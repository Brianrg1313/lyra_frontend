import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:genui/genui.dart' as genui;

// SERVICES
import './assistant_turn.dart';
import './sources/assistant_demo_source.dart';
import './sources/assistant_source.dart';

/// The home's chat with the assistant, over GenUI.
///
/// GenUI's [genui.Conversation] runs the loop: what the person says goes to
/// [genui.A2uiTransportAdapter.onSend], which streams the [AssistantSource]'s
/// raw answer back into the adapter; its parser splits the text from the A2UI
/// messages, and the [genui.SurfaceController] builds a surface per
/// `createSurface` with the widgets of [catalogs]. A control pressed on a
/// surface comes back through the same loop as the person's next turn.
///
/// This service only keeps the thread ([turns]) the screen draws: which text
/// and which surfaces belong to which answer. Section-scoped: the home
/// creates it and disposes it.
class AssistantService extends ChangeNotifier {
  AssistantService({
    required Iterable<genui.Catalog> catalogs,
    AssistantSource? source,
    this.onNavigate
  }) : _source = source ?? AssistantDemoSource() {
    controller = genui.SurfaceController(catalogs: catalogs);
    _transport = genui.A2uiTransportAdapter(onSend: _onSend);
    _conversation = genui.Conversation(controller: controller, transport: _transport);
    _events = _conversation.events.listen(_onEvent);
  }

  final AssistantSource _source;

  /// Opens an app path a surface asked for (a `navigate` event with a `path`).
  /// The screen's, since a service holds no navigation.
  final void Function(String path)? onNavigate;

  late final genui.SurfaceController controller;
  late final genui.A2uiTransportAdapter _transport;
  late final genui.Conversation _conversation;
  late final StreamSubscription<genui.ConversationEvent> _events;

  final List<AssistantTurn> _turns = [];
  List<AssistantTurn> get turns => List.unmodifiable(_turns);

  /// The answer being written; text and surfaces that arrive go to it.
  AssistantTurn? _answer;

  /// Bumped by [stop] and [clear]: a stream whose generation is gone stops
  /// writing.
  int _generation = 0;
  int _ids = 0;

  bool get busy => _answer != null;

  bool get isEmpty => _turns.isEmpty;

  /// The context a surface of an answer is drawn with.
  genui.SurfaceContext surface(String id) => controller.contextFor(id);

  /// Sends what the person typed. Ignored while an answer is being written.
  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || busy) return;

    _turns.add(AssistantTurn.user(_nextId(), prompt));
    notifyListeners();

    await _conversation.sendRequest(genui.ChatMessage.user(prompt));
  }

  /// Cuts the answer being written where it is.
  void stop() {
    final answer = _answer;
    if (answer == null) return;

    _generation++;
    _answer = null;
    answer.close(AssistantTurnState.stopped);
    notifyListeners();
  }

  /// Starts a new chat. The surfaces of the old one are left to the
  /// controller, which drops them on [dispose].
  void clear() {
    _generation++;
    _answer = null;
    _turns.clear();
    notifyListeners();
  }

  /// [genui.A2uiTransportAdapter.onSend]: one request to the source, typed or
  /// from a surface.
  Future<void> _onSend(genui.ChatMessage message) async {
    final AssistantRequest request;

    if (message.text.isNotEmpty) {
      request = AssistantRequest(prompt: message.text);
    } else {
      final action = _action(message);
      if (action == null) return;

      final name = action["name"] as String? ?? "";
      final context = (action["context"] as Map?)?.cast<String, Object?>() ?? const {};

      if (name == "navigate") {
        if (context["path"] case final String path) onNavigate?.call(path);
        return;
      }

      // Answering while another answer is written would mix them.
      if (busy) return;

      final label = context["label"] as String? ?? name;
      _turns.add(AssistantTurn.user(_nextId(), label, action: name));
      request = AssistantRequest(prompt: label, action: name, context: context);
    }

    await _stream(request);
  }

  Future<void> _stream(AssistantRequest request) async {
    final generation = ++_generation;
    final answer = AssistantTurn.assistant(_nextId());

    _answer = answer;
    _turns.add(answer);
    notifyListeners();

    try {
      await for (final chunk in _source.reply(request)) {
        if (generation != _generation) return;
        _transport.addChunk(chunk);
      }

      // The adapter parses asynchronously: let the last chunk land in the
      // turn before it is closed.
      await Future<void>.delayed(Duration.zero);
      if (generation != _generation) return;

      answer.close(AssistantTurnState.done);
    } catch (error) {
      if (generation != _generation) return;

      debugPrint("Assistant answer failed: $error");
      answer.close(AssistantTurnState.failed);
    }

    _answer = null;
    notifyListeners();
  }

  /// The A2UI `action` of a surface's interaction, or null for anything else
  /// the controller submits (its error reports are logged, never answered:
  /// answering them would loop on a broken surface).
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
    // Late arrivals of an answer already stopped or cleared are dropped.
    final answer = _answer;
    if (answer == null) return;

    switch (event) {
      case genui.ConversationContentReceived(:final text):
        answer.write(text);
      case genui.ConversationSurfaceAdded(:final surfaceId):
        answer.show(surfaceId);
      case genui.ConversationError(:final error):
        debugPrint("Assistant conversation error: $error");
        return;
      default:
        return;
    }

    notifyListeners();
  }

  String _nextId() => "turn_${_ids++}";

  @override
  void dispose() {
    _generation++;
    _events.cancel();
    _conversation.dispose();
    _transport.dispose();
    controller.dispose();
    super.dispose();
  }
}
