import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/chats/chat_detail_model.dart';
import 'package:app/services/chats/chat_event.dart';
import 'package:app/services/chats/chat_message_model.dart';
import 'package:app/services/chats/chat_model.dart';
import 'package:app/services/chats/chat_request.dart';
import 'package:app/services/chats/chats_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/toolkit/api.dart';

enum ChatThreadStatus { idle, loading, ready, error }

/// **One open conversation**: its detail, its history and every write a person
/// makes on it.
///
/// Created per opened chat (the panel is keyed by chat id), never cached. It
/// patches the [inbox] row after its own writes so the list agrees before the
/// socket echo arrives; the echo is idempotent.
///
/// Messages are kept oldest first, as the backend pages them. Every message
/// arriving by socket or by a send answer is **deduplicated by id**, since both
/// paths deliver the same one.
class ChatThreadService extends ChangeNotifier {
  ChatThreadService({required this.id, this.inbox, ChatModel? row})
    : _detail = row == null ? null : ChatDetailModel.fromRow(row, tagOf: inbox?.tagOf) {
    final connection = ConnectionService();

    _unlisten = [
      connection.on(ChatEvent.message, _onMessage),
      connection.on(ChatEvent.status, _onStatus),
      connection.on(ChatEvent.rekeyed, _onRekeyed),
      connection.on(ChatEvent.handover, _onHandover),
      connection.on(ChatEvent.stage, _onStage),
      connection.on(ChatEvent.tags, _onTags),
      connection.on(ChatEvent.attention, _onAttentionChanged),
      connection.on(ChatEvent.attended, _onAttentionChanged),
      connection.onRestored(_onRestored)
    ];
  }

  final String id;
  final ChatsService? inbox;

  static const int _pageSize = 50;

  ChatThreadStatus _status = ChatThreadStatus.idle;
  ChatDetailModel? _detail;
  final List<ChatMessage> _messages = [];

  String? _before;
  bool _loadingOlder = false;
  bool _allSessions = false;
  bool _sending = false;
  bool _busy = false;

  List<void Function()> _unlisten = const [];
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;

    for (final remove in _unlisten) {
      remove();
    }
    _unlisten = const [];

    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  // ─── What is on screen ──────────────────────────────────────────────────────

  ChatThreadStatus get status => _status;

  /// Null only before the first read of a chat that was not in the list.
  ChatDetailModel? get detail => _detail;

  /// Oldest first.
  List<ChatMessage> get messages => _messages;

  bool get hasOlder => _before != null;
  bool get loadingOlder => _loadingOlder;

  /// Showing every session of the customer on this number (`ALL=1`).
  bool get allSessions => _allSessions;
  bool get sending => _sending;

  /// A handover/stage/resolve write is in flight.
  bool get busy => _busy;

  // ─── Reading ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _status = ChatThreadStatus.loading;
    _notify();

    await Future.wait([_readDetail(), _readMessages()]);

    if (_status == ChatThreadStatus.loading) _status = ChatThreadStatus.ready;
    _notify();

    _opened();
  }

  /// Reads the detail again. Its AI spend (`usage`) moves with every turn and
  /// no event carries it, so what shows it asks for it fresh.
  Future<void> refreshDetail() => _readDetail();

  /// Every session, or back to this one.
  Future<void> showAllSessions(bool value) {
    if (value == _allSessions) return Future.value();

    _allSessions = value;
    return _readMessages();
  }

  /// Next older page, prepended.
  Future<void> older() async {
    final before = _before;
    if (before == null || _loadingOlder) return;

    _loadingOlder = true;
    _notify();

    try {
      final data = await aries.get(
        path: "/chats/messages/$id",
        version: "v1",
        query: {"LIMIT": _pageSize, "BEFORE": before, if (_allSessions) "ALL": 1}
      );

      final page = ChatMessagesPage.fromResponse(data);

      if (page.isLoaded) {
        final known = {for (final message in _messages) message.id};
        _messages.insertAll(0, page.messages.where((m) => !known.contains(m.id)));
        _before = page.before;
      }
    } catch (error) {
      if (kDebugMode) print("loadOlderChatMessages failed: $error");
      FloatFlag.showFromError(error);
    }

    _loadingOlder = false;
    _notify();
  }

  Future<void> _readDetail() async {
    try {
      final data = await aries.get(path: "/chats/detail/$id", version: "v1");
      final json = chatEvent(data);

      if (json == null) throw S.current.messages_error_title;

      final detail = ChatDetailModel.fromJson(json);

      _detail = detail;
      inbox?.patchTags(id, detail.tags);
    } catch (error) {
      if (kDebugMode) print("loadChatDetail failed: $error");

      // Only the opening read blanks the panel: a later reread that fails
      // leaves the last thing that was true. The api layer keeps only
      // `{message, action}`, so a 404 is not told apart from a failure.
      if (_status == ChatThreadStatus.loading) _status = ChatThreadStatus.error;
    }

    _notify();
  }

  Future<void> _readMessages() async {
    try {
      final data = await aries.get(
        path: "/chats/messages/$id",
        version: "v1",
        query: {"LIMIT": _pageSize, if (_allSessions) "ALL": 1}
      );

      final page = ChatMessagesPage.fromResponse(data);

      if (!page.isLoaded) throw S.current.messages_error_title;

      // Keep what arrived by socket while the page was in flight.
      final known = {for (final message in page.messages) message.id};
      final live = _messages.where((m) => !known.contains(m.id)).toList();

      _messages
        ..clear()
        ..addAll(page.messages)
        ..addAll(live);
      _before = page.before;
    } catch (error) {
      if (kDebugMode) print("loadChatMessages failed: $error");

      if (_status == ChatThreadStatus.loading) _status = ChatThreadStatus.error;
    }

    _notify();
  }

  // ─── Writes ─────────────────────────────────────────────────────────────────

  /// Answers the customer as the company. Pauses the bot by default (24 h) so
  /// it does not talk over the person.
  ///
  /// Returns the chat id the message landed on: **it differs from [id]** when
  /// the conversation had expired and the message opened a new session, and
  /// the caller moves to it. Null when it failed (already reported).
  Future<String?> send(String text, {bool pause = true}) async {
    final message = text.trim();
    if (message.isEmpty || _sending) return null;

    _sending = true;
    _notify();

    dynamic data;

    try {
      data = await aries.post(
        path: "/chats/messages",
        version: "v1",
        data: sendChatMessageRequest(id: id, message: message, pause: pause)
      );
    } catch (error) {
      if (kDebugMode) print("sendChatMessage failed: $error");

      _sending = false;
      _notify();
      FloatFlag.showFromError(error);

      return null;
    }

    _sending = false;

    final answer = chatEvent(data) ?? const {};
    final chat = chatText(answer["chat"]);
    final landed = chat.isEmpty ? id : chat;

    if (landed == id) {
      if (chatEvent(answer["message"]) case final json?) {
        var sent = ChatMessage.fromJson(json);
        if (answer["live"] == false) sent = sent.asQueued();
        _add(sent);
      }

      // Answering marks the customer's messages read and clears a failure.
      if (_detail != null) {
        _detail = _detail!.copyWith(
          answered: true,
          awaiting: () => null,
          attention: _detail!.attention?.kind == ChatWaiting.failure
            ? () => null
            : null
        );
      }
    } else {
      inbox?.moved(id, landed);
    }

    if (answer["live"] == false) {
      FloatFlag.of().alert(
        title: S.current.messages_queued_title,
        message: S.current.messages_queued_subtitle
      );
    }

    _notify();

    return landed;
  }

  /// Takes the conversation: the bot stops answering this customer. [minutes]
  /// null = until resumed.
  Future<bool> pause({int? minutes, String? reason}) => _handover(
    "/chats/bot/pause",
    pauseChatRequest(id: id, minutes: minutes, reason: reason)
  );

  /// Hands the conversation back to the bot.
  Future<bool> resume() => _handover("/chats/bot/resume", chatIdRequest(id: id));

  /// Assigns a member, or unassigns with null.
  /// Who may take this conversation (`GET /aries/v1/team?ID=`): a person kept to other
  /// branches can't take one of this conversation's branch (`409 desk_member_branch`). Read on
  /// every "Assign to…", so a refusal is followed by the list as it is now. A failed read falls
  /// back to the whole team ([inbox]'s), which the backend still checks.
  Future<List<ChatPerson>> assignable() async {
    try {
      final data = await aries.get(path: "/team", version: "v1", query: {"ID": id});

      return [for (final row in catalogRows(data)) ?ChatPerson.from(row)];
    } catch (error) {
      if (kDebugMode) print("loadChatAssignable failed: $error");

      return inbox?.team ?? const [];
    }
  }

  Future<bool> assign(String? username) => _write(
    () => aries.put(
      path: "/chats/assign",
      version: "v1",
      data: assignChatRequest(id: id, username: username)
    ),
    _applyHandover
  );

  /// Closes by hand ([kChatStageSold] / [kChatStageEnded]) or undoes with null.
  /// `sold` also messages the customer their confirmation.
  Future<bool> setStage(String? stage) => _write(
    () => aries.put(
      path: "/chats/stage",
      version: "v1",
      data: chatStageRequest(id: id, stage: stage)
    ),
    (_) => _readDetail().then((_) {
      final current = _detail;
      if (current != null) inbox?.patchStage(id, current.stage);
    })
  );

  /// Marks pending work as done ([stage] null = all of it).
  Future<bool> resolve({String? stage}) => _write(
    () => aries.post(
      path: "/chats/alerts/resolve",
      version: "v1",
      data: resolveChatRequest(id: id, stage: stage)
    ),
    (_) => _readDetail()
  );

  /// Blue ticks to the customer without answering. By user action only: it
  /// tells the customer somebody is looking.
  Future<bool> markRead() => _write(
    () => aries.post(path: "/chats/read", version: "v1", data: chatIdRequest(id: id)),
    (_) async {}
  );

  Future<bool> _handover(String path, Map<String, dynamic> body) => _write(
    () => aries.post(path: path, version: "v1", data: body),
    _applyHandover
  );

  Future<void> _applyHandover(dynamic data) async {
    final answer = chatEvent(data);
    if (answer == null) return;

    final bot = ChatBot.from(answer["bot"]);
    final assignee = ChatPerson.from(answer["assignee"]);

    if (_detail != null) {
      _detail = _detail!.copyWith(bot: bot, assignee: () => assignee);
    }

    inbox?.patchHandover(id, bot: bot, assignee: assignee);
  }

  Future<bool> _write(
    Future<dynamic> Function() call,
    Future<void> Function(dynamic data) apply
  ) async {
    if (_busy) return false;

    _busy = true;
    _notify();

    try {
      final data = await call();
      await apply(data);

      return true;
    } catch (error) {
      if (kDebugMode) print("chat write failed: $error");
      FloatFlag.showFromError(error);

      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  // ─── Seams ──────────────────────────────────────────────────────────────────

  @visibleForTesting
  void seed({ChatDetailModel? detail, List<ChatMessage> messages = const [], String? before}) {
    _detail = detail ?? _detail;
    _messages
      ..clear()
      ..addAll(messages);
    _before = before;
    _status = ChatThreadStatus.ready;
  }

  @visibleForTesting
  void receive(String event, dynamic data) => switch (event) {
    ChatEvent.message => _onMessage(data),
    ChatEvent.status => _onStatus(data),
    ChatEvent.rekeyed => _onRekeyed(data),
    ChatEvent.handover => _onHandover(data),
    ChatEvent.stage => _onStage(data),
    ChatEvent.tags => _onTags(data),
    _ => null
  };

  // ─── Events ─────────────────────────────────────────────────────────────────

  void _onMessage(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["id"]) != id) return;

    final json = chatEvent(event["message"]);
    if (json != null) {
      final message = ChatMessage.fromJson(json);
      _add(message);

      // What the customer writes into the open conversation is read as it lands.
      if (message.incoming) _opened();
    }

    final current = _detail;
    if (current != null) {
      _detail = current.copyWith(
        name: event.containsKey("name") ? chatText(event["name"]) : null,
        status: event.containsKey("status") ? chatText(event["status"]) : null,
        activity: chatDate(event["activity"]),
        answered: event.containsKey("answered") ? event["answered"] != false : null,
        awaiting: event.containsKey("awaiting") ? () => chatDate(event["awaiting"]) : null
      );
    }

    _notify();
  }

  /// The person has this conversation in front of them: it is not new for them
  /// (`chats.unread`).
  void _opened() {
    if (_disposed) return;

    unawaited(BadgesService().opened(BadgeRow.chat, id));
  }

  void _onStatus(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["chat"]) != id) return;

    final messageId = chatText(event["message_id"]);
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    _messages[index] = _messages[index].withStatus(ChatMessageStatus.from(event["status"]));
    _notify();
  }

  void _onRekeyed(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["chat"]) != id) return;

    final ticket = chatText(event["ticket"]);
    final real = chatText(event["message_id"]);
    if (ticket.isEmpty || real.isEmpty) return;

    final index = _messages.indexWhere((m) => m.id == ticket);
    if (index == -1) return;

    // The real id may already be here if its echo beat the rekey: keep one.
    if (_messages.any((m) => m.id == real)) {
      _messages.removeAt(index);
    } else {
      _messages[index] = _messages[index].withId(real);
    }

    _notify();
  }

  void _onHandover(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["id"] ?? event["chat"]) != id) return;

    final current = _detail;
    if (current == null) return;

    final assignee = ChatPerson.from(event["assignee"]);

    _detail = current.copyWith(bot: ChatBot.from(event["bot"]), assignee: () => assignee);
    _notify();
  }

  void _onStage(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["id"] ?? event["chat"]) != id) return;

    final current = _detail;
    if (current == null) return;

    _detail = current.copyWith(stage: ChatStage.from(event));
    _notify();
  }

  /// The whole set is replaced. `detail` names each tag and its tickets; an
  /// event without it is named from the inbox catalog.
  void _onTags(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["id"] ?? event["chat"]) != id) return;

    final current = _detail;
    if (current == null) return;

    final tags = event["detail"] is List
      ? ChatTag.listOf(event["detail"])
      : [
          for (final code in chatCodes(event["tags"]))
            inbox?.tagOf(code) ?? ChatTag(tag: code)
        ];

    _detail = current.copyWith(tags: tags);
    _notify();
  }

  /// The mark itself travels thin; the detail carries the text for the team.
  void _onAttentionChanged(dynamic data) {
    final event = chatEvent(data);
    if (event == null || chatText(event["chat"]) != id) return;

    unawaited(_readDetail());
  }

  void _onRestored() {
    if (_disposed || _status == ChatThreadStatus.idle) return;

    unawaited(_readDetail());
    unawaited(_readMessages());
  }

  // ─── Internals ──────────────────────────────────────────────────────────────

  void _add(ChatMessage message) {
    if (message.id.isEmpty) return;

    final index = _messages.indexWhere((m) => m.id == message.id);

    if (index == -1) {
      _messages.add(message);
      return;
    }

    // Keep the furthest tick: an echo may carry an older status than one
    // already applied. A queued mark survives until a tick says it left.
    final known = _messages[index];
    if (message.status.index < known.status.index) return;

    _messages[index] = known.queued && message.status == ChatMessageStatus.sent
      ? message.asQueued()
      : message;
  }
}
