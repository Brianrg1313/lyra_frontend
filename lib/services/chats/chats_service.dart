import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/chats/chat_event.dart';
import 'package:app/services/chats/chat_model.dart';
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/toolkit/api.dart';

enum ChatsStatus { idle, loading, ready, empty, error }

/// The inbox tabs. Each is `GET /aries/v1/chats` with its own filter, and its
/// counter comes from `GET /aries/v1/chats/summary`.
enum ChatsFilter {
  all,
  unanswered,
  attention,
  mine,
  paused;

  Map<String, dynamic> get query => switch (this) {
    all => const {},
    unanswered => const {"ANSWERED": 0},
    attention => const {"ATTENTION": 1},
    mine => const {"ASSIGNEE": "me"},
    paused => const {"PAUSED": 1}
  };

  /// The tab's counter in [summary]; null when the tab has none or it could
  /// not be measured.
  int? countIn(ChatSummary summary) => switch (this) {
    all => null,
    unanswered => summary.awaiting,
    attention => summary.attention,
    mine => summary.mine,
    paused => summary.paused
  };
}

/// **The inbox of the messages section**: the conversation list, its counters,
/// the stage catalog and the team, plus which conversation is open.
///
/// Owned by the messages section and dropped on leaving it (the state belongs
/// to the active company). Every endpoint answers for the `business_id` header.
///
/// It listens to the chat socket events and applies them to the rows it holds;
/// what an event cannot draw (a new conversation or session) is a debounced
/// reread of page one, and only while on page one — past it the list is
/// somebody's scroll, so it counts in [pending]. A restored connection rereads
/// everything: events missed while disconnected are not replayed.
class ChatsService extends ChangeNotifier {
  ChatsService() {
    final connection = ConnectionService();

    _unlisten = [
      connection.on(ChatEvent.message, _onMessage),
      connection.on(ChatEvent.handover, _onHandover),
      connection.on(ChatEvent.stage, _onStage),
      connection.on(ChatEvent.tags, _onTags),
      connection.on(ChatEvent.attention, _onAttention),
      connection.on(ChatEvent.attended, _onAttended),
      connection.on(ChatEvent.alert, _onAlert),
      connection.on(ChatEvent.assigned, _onAssigned),
      connection.on(BadgesService.openedEvent, _onOpened),
      connection.onRestored(_onRestored)
    ];
  }

  static const int _pageSize = 50;

  /// Collects a burst of events (a message, its stage, its summary) into one read.
  static const Duration _catchUpDelay = Duration(milliseconds: 800);

  ChatsStatus _status = ChatsStatus.idle;
  final List<ChatModel> _chats = [];

  ChatsFilter _filter = ChatsFilter.all;
  String _search = "";

  int _total = 0;
  int _page = 0;
  bool _reading = false;
  bool _moreFailed = false;
  int _generation = 0;
  int _pending = 0;

  ChatSummary _summary = const ChatSummary();
  List<ChatStageOption> _stages = const [];
  Map<String, ChatTag> _tags = const {};
  List<ChatPerson> _team = const [];

  /// Starts on the chat that was open when the desk was last left, in this
  /// business: the right panel reads it by id, so it opens even before (or
  /// without) its row being on the first page.
  String? _selected = PreferencesService().recall(RememberedSelection.chat);

  Timer? _catchUp;
  Timer? _summaryDebounce;
  List<void Function()> _unlisten = const [];
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;

    _catchUp?.cancel();
    _summaryDebounce?.cancel();

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

  ChatsStatus get status => _status;
  List<ChatModel> get chats => _chats;
  ChatsFilter get filter => _filter;
  String get search => _search;
  int get total => _total;
  ChatSummary get summary => _summary;
  List<ChatStageOption> get stages => _stages;
  List<ChatPerson> get team => _team;
  bool get moreFailed => _moreFailed;

  /// Events about conversations this list could not pick up on its own.
  int get pending => _pending;

  bool get hasMore => _page > 0 && _page * _pageSize < _total;

  /// The open conversation, or null.
  String? get selected => _selected;

  ChatModel? rowOf(String id) {
    for (final chat in _chats) {
      if (chat.id == id) return chat;
    }
    return null;
  }

  /// The tag catalog, in drawing order.
  Iterable<ChatTag> get tagCatalog => _tags.values;

  /// A row's tag code with its name, colour hint and attention. Before the
  /// catalog arrives (or for a code it lacks) the bare code, so a chip is
  /// never dropped.
  ChatTag tagOf(String code) => _tags[code] ?? ChatTag(tag: code);

  /// Stages a person can set by hand.
  List<ChatStageOption> get manualStages =>
    _stages.where((stage) => stage.manual).toList();

  // ─── Reading ────────────────────────────────────────────────────────────────

  /// What the section calls when it mounts: the page, the counters and the
  /// three vocabularies (stages, tags, team), in parallel.
  Future<void> load() => Future.wait([
    _read(1, reset: true),
    loadSummary(),
    _loadStages(),
    _loadTags(),
    _loadTeam()
  ]);

  Future<void> retry() => _read(1, reset: true);

  Future<void> refresh() => Future.wait([
    _read(1, reset: true, silent: _status == ChatsStatus.ready),
    loadSummary()
  ]);

  Future<void> applyFilter(ChatsFilter value) {
    if (value == _filter) return Future.value();

    _filter = value;
    return _read(1, reset: true);
  }

  /// Narrows the list by profile name or number. [value] is already trimmed.
  Future<void> applySearch(String value) {
    if (value == _search) return Future.value();

    _search = value;
    return _read(1, reset: true);
  }

  Future<void> more() {
    if (_reading || _moreFailed || !hasMore) return Future.value();
    return _read(_page + 1);
  }

  Future<void> retryMore() {
    if (_reading || !hasMore) return Future.value();

    _moreFailed = false;
    return _read(_page + 1);
  }

  Future<void> loadSummary() async {
    try {
      final data = await aries.get(path: "/chats/summary", version: "v1");
      _summary = ChatSummary.from(data);
      _notify();
    } catch (error) {
      if (kDebugMode) print("loadChatsSummary failed: $error");
    }
  }

  Future<void> _loadStages() async {
    try {
      final data = await aries.get(path: "/chats/stages", version: "v1");
      _stages = ChatStageOption.listFrom(data);
      _notify();
    } catch (error) {
      if (kDebugMode) print("loadChatStages failed: $error");
    }
  }

  Future<void> _loadTags() async {
    try {
      final data = await aries.get(path: "/chats/tags", version: "v1");
      _tags = {for (final tag in ChatTag.catalogFrom(data)) tag.tag: tag};
      _notify();
    } catch (error) {
      if (kDebugMode) print("loadChatTags failed: $error");
    }
  }

  Future<void> _loadTeam() async {
    try {
      final data = await aries.get(path: "/team", version: "v1");
      _team = [
        for (final row in catalogRows(data))
          ?ChatPerson.from(row)
      ];
      _notify();
    } catch (error) {
      if (kDebugMode) print("loadChatTeam failed: $error");
    }
  }

  // ─── Selection and local patches ────────────────────────────────────────────

  void select(String? id) {
    if (id == _selected) return;

    _selected = id;
    PreferencesService().remember(RememberedSelection.chat, id);

    // Its panel tells the backend (`ChatThreadService.load`); the row is not left saying "new"
    // while that travels.
    if (id != null) _patch(id, (row) => row.unseen ? row.read() : row);
    _notify();
  }

  /// A write of the open chat answered with a new `bot`/`assignee`.
  void patchHandover(String id, {required ChatBot bot, required ChatPerson? assignee}) =>
    _patch(id, (row) => row.handedOver(bot: bot, assignee: assignee));

  void patchStage(String id, ChatStage stage) =>
    _patch(id, (row) => row.staged(stage));

  /// The open chat read its detail: its tags are at least as new as the row's.
  void patchTags(String id, List<ChatTag> tags) {
    final row = rowOf(id);
    final codes = [for (final tag in tags) tag.tag];

    if (row == null || listEquals(row.tags, codes)) return;

    _patch(id, (row) => row.tagged(codes));
  }

  /// A send opened a new session with another id: the open chat moves to it
  /// and page one is reread, since the new row cannot be drawn from here.
  void moved(String from, String to) {
    if (_selected == from) {
      _selected = to;
      PreferencesService().remember(RememberedSelection.chat, to);
    }
    _scheduleCatchUp();
    _notify();
  }

  // ─── Seams ──────────────────────────────────────────────────────────────────

  @visibleForTesting
  void seedTags(List<ChatTag> catalog) =>
    _tags = {for (final tag in catalog) tag.tag: tag};

  @visibleForTesting
  void seed(List<ChatModel> chats, {int? total, int page = 1, ChatsFilter filter = ChatsFilter.all}) {
    _filter = filter;
    _chats
      ..clear()
      ..addAll(chats);
    _total = total ?? chats.length;
    _page = page;
    _pending = 0;
    _status = chats.isEmpty ? ChatsStatus.empty : ChatsStatus.ready;
  }

  /// Feeds a socket frame exactly as it arrives.
  @visibleForTesting
  void receive(String event, dynamic data) => switch (event) {
    ChatEvent.message => _onMessage(data),
    ChatEvent.handover => _onHandover(data),
    ChatEvent.stage => _onStage(data),
    ChatEvent.tags => _onTags(data),
    ChatEvent.attention => _onAttention(data),
    ChatEvent.attended => _onAttended(data),
    BadgesService.openedEvent => _onOpened(data),
    _ => null
  };

  // ─── Events ─────────────────────────────────────────────────────────────────

  void _onMessage(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    final id = chatText(event["id"]);
    if (id.isEmpty) return;

    final index = _chats.indexWhere((row) => row.id == id);

    if (event["created"] == true || index == -1) {
      _scheduleCatchUp();
    } else {
      var row = _chats.removeAt(index).touched(event);

      // The customer wrote: unread for this person, unless it is the conversation they have open
      // (its panel reports it read again).
      final message = chatEvent(event["message"]);
      if (message != null && chatText(message["direction"]) == "in") {
        row = row.read(unseen: id != _selected);
      }

      // An answered row can leave the "unanswered" tab; any other filter is
      // untouched by a message.
      if (_filter == ChatsFilter.unanswered && row.answered) {
        if (_total > 0) _total--;
      } else {
        _chats.insert(0, row);
      }

      _status = _chats.isEmpty ? ChatsStatus.empty : ChatsStatus.ready;
      _notify();
    }

    _scheduleSummary();
  }

  /// This person opened a conversation, here or on another screen.
  void _onOpened(dynamic data) {
    final event = chatEvent(data);
    if (event == null || BadgeRow.from(event["kind"]) != BadgeRow.chat) return;

    _patch(chatText(event["id"]), (row) => row.unseen ? row.read() : row);
  }

  void _onHandover(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    final id = chatText(event["id"] ?? event["chat"]);

    _patch(id, (row) => row.handedOver(
      bot: ChatBot.from(event["bot"]),
      assignee: ChatPerson.from(event["assignee"])
    ));

    // Who holds a chat is what the "mine" and "paused" tabs and counters read.
    if (_filter == ChatsFilter.mine || _filter == ChatsFilter.paused) {
      _scheduleCatchUp();
    }

    _scheduleSummary();
  }

  void _onStage(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    _patch(chatText(event["id"] ?? event["chat"]), (row) => row.staged(ChatStage.from(event)));
  }

  void _onTags(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    _patch(chatText(event["id"] ?? event["chat"]), (row) => row.tagged(chatCodes(event["tags"])));
  }

  void _onAttention(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    final id = chatText(event["chat"]);
    final kind = ChatWaiting.from(event["kind"]);

    _patch(id, (row) => row.flagged(kind));

    if (_filter == ChatsFilter.attention && rowOf(id) == null) _scheduleCatchUp();
    _scheduleSummary();

    final row = rowOf(id);
    final who = row?.title ?? chatText(event["contact"]);

    FloatFlag.of().alert(
      title: kind == ChatWaiting.failure
        ? S.current.messages_notice_failure_title
        : S.current.messages_notice_pending_title,
      message: who
    );
  }

  void _onAttended(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    _patch(chatText(event["chat"]), (row) => row.flagged(null));
    _scheduleSummary();
  }

  void _onAlert(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    final name = chatText(event["name"]);

    FloatFlag.of().notification(
      title: S.current.messages_notice_waiting_title(
        name.isNotEmpty ? name : chatText(event["contact"])
      ),
      message: chatText(event["detail"])
    );
  }

  void _onAssigned(dynamic data) {
    final event = chatEvent(data);
    if (event == null) return;

    final id = chatText(event["id"] ?? event["chat"]);
    final row = rowOf(id);

    FloatFlag.of().notification(
      title: S.current.messages_notice_assigned(row?.title ?? chatText(event["contact"]))
    );
  }

  void _onRestored() {
    if (_disposed || _status == ChatsStatus.idle) return;

    unawaited(loadSummary());

    if (_page > 1) {
      _pending++;
      _notify();
      return;
    }

    _catchUp?.cancel();
    unawaited(_read(1, reset: true, silent: true));
  }

  // ─── Internals ──────────────────────────────────────────────────────────────

  void _patch(String id, ChatModel Function(ChatModel row) change) {
    if (id.isEmpty) return;

    final index = _chats.indexWhere((row) => row.id == id);
    if (index == -1) return;

    _chats[index] = change(_chats[index]);
    _notify();
  }

  void _scheduleCatchUp() {
    if (_status == ChatsStatus.idle) return;

    if (_page > 1) {
      _pending++;
      _notify();
      return;
    }

    _catchUp?.cancel();
    _catchUp = Timer(_catchUpDelay, () {
      _catchUp = null;
      unawaited(_read(1, reset: true, silent: true));
    });
  }

  void _scheduleSummary() {
    _summaryDebounce?.cancel();
    _summaryDebounce = Timer(_catchUpDelay, () {
      _summaryDebounce = null;
      unawaited(loadSummary());
    });
  }

  Future<void> _read(int page, {bool reset = false, bool silent = false}) async {
    if (_reading && !reset) return;

    _reading = true;
    _moreFailed = false;

    if (reset) {
      _generation++;

      if (!silent) {
        _chats.clear();
        _page = 0;
        _status = ChatsStatus.loading;
        _notify();
      }
    }

    final generation = _generation;
    dynamic data;

    try {
      data = await aries.get(
        path: "/chats",
        version: "v1",
        query: {
          ..._filter.query,
          if (_search.isNotEmpty) "SEARCH": _search,
          "PAGE": page,
          "SIZE": _pageSize
        }
      );
    } catch (error) {
      if (kDebugMode) print("loadChats failed: $error");
      if (generation != _generation) return;

      _reading = false;

      if (silent) {
        _pending++;
      } else {
        _nothing();
      }

      _notify();
      return;
    }

    if (generation != _generation) return;

    _reading = false;

    final result = ChatsPage.fromResponse(data);

    if (!result.isLoaded) {
      if (silent) {
        _pending++;
      } else {
        _nothing();
      }

      _notify();
      return;
    }

    if (reset) {
      _chats.clear();
      _pending = 0;
    }

    // A page read after events moved rows may repeat one already listed.
    final known = {for (final chat in _chats) chat.id};

    _total = result.total;
    _page = page;
    _chats.addAll(result.chats.where((chat) => !known.contains(chat.id)));
    _status = _chats.isEmpty ? ChatsStatus.empty : ChatsStatus.ready;

    _notify();
  }

  void _nothing() {
    if (_chats.isEmpty) {
      _status = ChatsStatus.error;
      return;
    }

    _moreFailed = true;
  }
}
