import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:genui/genui.dart' as genui;

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import './assistant_line.dart';
import './assistant_turn.dart';
import './sources/assistant_cloud_source.dart';
import './sources/assistant_source.dart';

/// How the conversation's first read went.
enum AssistantStatus { idle, loading, ready, error }

/// The home's chat with the panel's assistant (the backend's operator: Lyra
/// working the app for this person, with their permissions).
///
/// The conversation is the server's: [load] reads it whole, [send] answers
/// with the new lines, and the socket (`assistant/working`,
/// `assistant/message`) keeps every screen of the person on the same thread.
/// Lines are deduplicated by id, since the `POST` and the socket carry the
/// same ones. What waits for the person's yes is [pending]; the model never
/// confirms, the screen's buttons do ([confirm]).
///
/// An answer's text may carry A2UI blocks: those go to GenUI's
/// [genui.SurfaceController] (through the [genui.Conversation] and its
/// [genui.A2uiTransportAdapter]) and the turn keeps the surface's place
/// between its sentences. A control pressed on a surface comes back through
/// the same loop as the person's next message.
///
/// Section-scoped: the home creates it and disposes it. Cloud only.
class AssistantService extends ChangeNotifier {
  AssistantService({
    required Iterable<genui.Catalog> catalogs,
    AssistantSource? source,
    this.onNavigate,
    bool live = true
  }) : _source = source ?? const AssistantCloudSource() {
    controller = genui.SurfaceController(catalogs: catalogs);
    _transport = genui.A2uiTransportAdapter(onSend: _onSend);
    _conversation = genui.Conversation(controller: controller, transport: _transport);
    _events = _conversation.events.listen(_onEvent);

    if (live) {
      final connection = ConnectionService();
      _unlisten.addAll([
        connection.on(workingEvent, (data) => receive(workingEvent, data)),
        connection.on(messageEvent, (data) => receive(messageEvent, data)),
        // Emitted while this screen was away is gone: read it again.
        connection.onRestored(load)
      ]);
    }
  }

  static const String workingEvent = "assistant/working";
  static const String messageEvent = "assistant/message";

  final AssistantSource _source;

  /// Opens an app path a surface asked for (a `navigate` event with a `path`).
  /// The screen's, since a service holds no navigation.
  final void Function(String path)? onNavigate;

  late final genui.SurfaceController controller;
  late final genui.A2uiTransportAdapter _transport;
  late final genui.Conversation _conversation;
  late final StreamSubscription<genui.ConversationEvent> _events;
  final List<void Function()> _unlisten = [];

  AssistantStatus _status = AssistantStatus.idle;
  AssistantStatus get status => _status;

  String? _thread;

  final List<AssistantTurn> _turns = [];
  final Set<String> _known = {};

  /// The person's message, shown at once, until the server's line for it
  /// arrives and takes its place.
  AssistantTurn? _optimistic;

  final List<AssistantPending> _pending = [];
  List<AssistantPending> get pending => List.unmodifiable(_pending);

  /// The pendings whose answer is on its way.
  final Set<String> _answering = {};
  bool answering(AssistantPending pending) => _answering.contains(pending.id);

  /// This screen's message is being answered.
  bool _sending = false;

  /// The server says it is answering (a message sent here or from another
  /// screen of the person).
  bool _working = false;

  /// Bumped by [clear] and [load]: an answer of a conversation gone is dropped.
  int _generation = 0;
  int _ids = 0;

  static final AssistantTurn _thinking = AssistantTurn.waiting("waiting");

  bool get busy => _sending || _working;

  /// The thread, and the thinking mark at its end while an answer is coming.
  List<AssistantTurn> get turns => List.unmodifiable([..._turns, if (busy) _thinking]);

  bool get isEmpty => _turns.isEmpty && !busy;

  /// The context a surface of an answer is drawn with.
  genui.SurfaceContext surface(String id) => controller.contextFor(id);

  /// Reads the conversation whole.
  Future<void> load() async {
    final generation = ++_generation;

    _status = AssistantStatus.loading;
    notifyListeners();

    try {
      final batch = await _source.read();
      if (generation != _generation) return;

      _reset();
      _apply(batch);
      _status = AssistantStatus.ready;
    } catch (error) {
      if (generation != _generation) return;

      debugPrint("Assistant conversation could not be read: $error");
      _status = AssistantStatus.error;
    }

    notifyListeners();
  }

  /// Sends what the person typed (or a surface's control: its [action] and
  /// label). Ignored while an answer is coming.
  Future<void> send(String text, {String? action}) async {
    final message = text.trim();
    if (message.isEmpty || busy) return;

    final generation = _generation;
    final optimistic = AssistantTurn.user(_nextId(), message, action: action);

    _optimistic = optimistic;
    _turns.add(optimistic);
    _sending = true;
    notifyListeners();

    try {
      final batch = await _source.send(message);
      if (generation != _generation) return;

      _apply(batch);
    } catch (error) {
      if (generation != _generation) return;

      debugPrint("Assistant answer failed: $error");
      _turns.add(AssistantTurn.failed(_nextId(), reason: _reason(error)));
    }

    _sending = false;
    if (_optimistic == optimistic) _optimistic = null;
    notifyListeners();
  }

  /// The person's yes or no on a [pending]. Throws what the server refused,
  /// for the screen to say; one already answered elsewhere just goes away.
  Future<void> confirm(AssistantPending pending, {required bool yes}) async {
    if (!_answering.add(pending.id)) return;
    notifyListeners();

    try {
      final batch = await _source.confirm(pending.id, yes: yes);
      _pending.removeWhere((held) => held.id == pending.id);
      _apply(batch);
    } catch (error) {
      if (_reason(error) != "harness_confirmation_not_found") rethrow;
      _pending.removeWhere((held) => held.id == pending.id);
    } finally {
      _answering.remove(pending.id);
      notifyListeners();
    }
  }

  /// Starts a new conversation: the server closes the open one, and what
  /// waited for a yes is dropped.
  Future<void> clear() async {
    _generation++;
    _reset();
    _sending = false;
    _working = false;
    _status = AssistantStatus.ready;
    notifyListeners();

    try {
      await _source.close();
    } catch (error) {
      debugPrint("Assistant conversation could not be closed: $error");
    }
  }

  /// A socket event (and the tests' seam).
  @visibleForTesting
  void receive(String event, Object? data) {
    if (data is! Map) return;

    final thread = data["thread"]?.toString();

    switch (event) {
      case workingEvent:
        if (_thread != null && thread != null && thread != _thread) return;

        _working = data["working"] == true;
        notifyListeners();
      case messageEvent:
        // Another screen closed this one and started anew: read that one.
        if (_thread != null && thread != null && thread != _thread) {
          load();
          return;
        }

        _apply(AssistantBatch.fromJson(data));
        notifyListeners();
    }
  }

  void _reset() {
    _thread = null;
    _turns.clear();
    _known.clear();
    _pending.clear();
    _answering.clear();
    _optimistic = null;
  }

  /// Adds what is new of [batch]: lines not seen yet, pendings not held yet.
  void _apply(AssistantBatch batch) {
    if (batch.thread != null) _thread = batch.thread;

    for (final line in batch.lines) {
      if (!_known.add(line.id)) continue;

      final optimistic = _optimistic;

      if (line.role == AssistantLineRole.person && optimistic != null) {
        final at = _turns.indexOf(optimistic);
        final turn = AssistantTurn.line(line, action: optimistic.action);

        at < 0 ? _turns.add(turn) : _turns[at] = turn;
        _optimistic = null;
        continue;
      }

      if (line.role == AssistantLineRole.event) {
        // Answered here or on another screen: it waits no more.
        _pending.removeWhere((held) => held.summary == line.text && held.operation == line.operation);
      }

      _turns.add(_turn(line));
    }

    for (final held in batch.pending) {
      if (_pending.every((known) => known.id != held.id)) _pending.add(held);
    }
  }

  /// A line as the thread draws it; an answer's A2UI blocks become surfaces.
  AssistantTurn _turn(AssistantLine line) {
    final turn = AssistantTurn.line(line);
    if (line.role != AssistantLineRole.assistant) return turn;

    var from = 0;

    for (final block in _fence.allMatches(line.text)) {
      final surfaces = _surfaces(block.group(1)!);
      if (surfaces == null) continue;

      turn.write(line.text.substring(from, block.start));
      // Only whole, valid A2UI goes to the parser: anything else it would
      // hold, waiting for the rest, and every later answer behind it.
      _transport.addChunk(block.group(0)!);
      surfaces.forEach(turn.show);
      from = block.end;
    }

    turn.write(line.text.substring(from));
    turn.close(AssistantTurnState.done);

    return turn;
  }

  static final RegExp _fence = RegExp(r"```(?:json)?[ \t]*\r?\n([\s\S]*?)\r?\n?```");

  static const Set<String> _a2ui = {"createSurface", "updateComponents", "updateDataModel", "deleteSurface"};

  /// The surfaces a fenced block creates, or null when it is not A2UI (a JSON
  /// example the model wrote stays text).
  List<String>? _surfaces(String block) {
    final Object? decoded;

    try {
      decoded = jsonDecode(block);
    } on FormatException {
      return null;
    }

    final messages = decoded is List ? decoded : [decoded];
    if (messages.isEmpty || messages.any((message) => message is! Map || !message.keys.any(_a2ui.contains))) return null;

    return [
      for (final message in messages.cast<Map>())
        if (message["createSurface"] case {"surfaceId": final String id}) id
    ];
  }

  /// [genui.A2uiTransportAdapter.onSend]: a control pressed on a surface (its
  /// error reports are logged, never answered: answering them would loop on a
  /// broken surface).
  Future<void> _onSend(genui.ChatMessage message) async {
    final action = _action(message);
    if (action == null) return;

    final name = action["name"] as String? ?? "";
    final context = (action["context"] as Map?)?.cast<String, Object?>() ?? const {};

    if (name == "navigate") {
      if (context["path"] case final String path) onNavigate?.call(path);
      return;
    }

    // A suggestion asks its prompt, as if typed.
    if (name == "ask" && context["prompt"] is String) {
      return send(context["prompt"] as String);
    }

    await send(context["label"] as String? ?? name, action: name);
  }

  Map<String, Object?>? _action(genui.ChatMessage message) {
    for (final part in message.parts) {
      if (part is! genui.DataPart || part.mimeType != genui.UiPartConstants.interactionMimeType) continue;

      final interaction = genui.UiInteractionPart.fromDataPart(part).interaction;
      final decoded = jsonDecode(interaction);

      if (decoded is Map && decoded["action"] is Map) {
        return (decoded["action"] as Map).cast<String, Object?>();
      }

      debugPrint("Assistant surface reported: $interaction");
    }

    return null;
  }

  void _onEvent(genui.ConversationEvent event) {
    if (event case genui.ConversationError(:final error)) debugPrint("Assistant conversation error: $error");
  }

  /// The server's key of a refusal (`assistant_busy`), when it gave one.
  static String? _reason(Object error) => error is Map ? error["message"]?.toString() : null;

  String _nextId() => "local_${_ids++}";

  @override
  void dispose() {
    _generation++;
    for (final unlisten in _unlisten) {
      unlisten();
    }
    _events.cancel();
    _conversation.dispose();
    _transport.dispose();
    controller.dispose();
    super.dispose();
  }
}
