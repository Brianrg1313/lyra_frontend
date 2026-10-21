// SERVICES
import './assistant_line.dart';

/// Who said a turn of the assistant's chat. An `event` is what a confirmation's
/// button did: shown in the thread, never read by the model as a turn.
enum AssistantRole { user, assistant, event }

/// How an assistant turn stands: `waiting` until its answer arrives.
enum AssistantTurnState { waiting, done, failed }

/// A piece of an answer: a run of text, or one GenUI surface (the id of an
/// A2UI `createSurface`).
class AssistantPart {
  AssistantPart.text(this.text) : surface = null;
  AssistantPart.surface(String this.surface) : text = "";

  String text;
  final String? surface;

  bool get isSurface => surface != null;
}

/// One turn of the home's chat with the assistant.
///
/// An assistant turn's [parts] keep text and surfaces in the order the model
/// wrote them, so a card shows between the sentence that introduces it and
/// the one that follows. A user turn is either typed ([text]) or a control of
/// a surface pressed ([action], with the control's label as its text).
class AssistantTurn {
  AssistantTurn.user(this.id, String text, {this.action})
    : role = AssistantRole.user,
      state = AssistantTurnState.done,
      calls = const [],
      outcome = null,
      reason = null {
    parts.add(AssistantPart.text(text));
  }

  /// An answer still on its way: the thread shows the thinking mark.
  AssistantTurn.waiting(this.id)
    : role = AssistantRole.assistant,
      action = null,
      state = AssistantTurnState.waiting,
      calls = const [],
      outcome = null,
      reason = null;

  /// An answer that never came ([AssistantTurnState.failed], no text);
  /// [reason] is the server's key, when it refused.
  AssistantTurn.failed(this.id, {this.reason})
    : role = AssistantRole.assistant,
      action = null,
      state = AssistantTurnState.failed,
      calls = const [],
      outcome = null;

  /// A line the server keeps. An assistant line's text is filled by the
  /// service, which splits its surfaces out.
  AssistantTurn.line(AssistantLine line, {this.action})
    : id = line.id,
      role = switch (line.role) {
        AssistantLineRole.person => AssistantRole.user,
        AssistantLineRole.assistant => AssistantRole.assistant,
        AssistantLineRole.event => AssistantRole.event
      },
      state = AssistantTurnState.done,
      calls = line.calls,
      outcome = line.outcome,
      reason = null {
    if (role != AssistantRole.assistant) parts.add(AssistantPart.text(line.text));
  }

  final String id;
  final AssistantRole role;
  final String? action;
  AssistantTurnState state;
  final List<AssistantPart> parts = [];

  /// What the assistant ran to answer.
  final List<AssistantCall> calls;

  /// An event's end: `done`, `failed`, `declined`, `expired`.
  final String? outcome;

  /// Why a failed answer never came (`assistant_busy`, `harness_unavailable`).
  final String? reason;

  bool get isUser => role == AssistantRole.user;

  bool get isEvent => role == AssistantRole.event;

  bool get isWaiting => state == AssistantTurnState.waiting;

  /// Nothing has arrived yet.
  bool get isEmpty => parts.isEmpty;

  /// The turn's words, without its surfaces (what "copy" takes).
  String get text => parts.where((part) => !part.isSurface).map((part) => part.text).join("\n\n");

  void write(String chunk) {
    final last = parts.isEmpty ? null : parts.last;

    if (last != null && !last.isSurface) {
      last.text += chunk;
    } else if (chunk.trim().isNotEmpty) {
      // A new run never opens with the blank lines that separated it from a surface.
      parts.add(AssistantPart.text(chunk.trimLeft()));
    }
  }

  void show(String surface) {
    if (parts.any((part) => part.surface == surface)) return;
    parts.add(AssistantPart.surface(surface));
  }

  /// Closes the turn: trailing blanks out, empty runs gone.
  void close(AssistantTurnState end) {
    state = end;

    for (final part in parts) {
      part.text = part.text.trimRight();
    }
    parts.removeWhere((part) => !part.isSurface && part.text.isEmpty);
  }
}
