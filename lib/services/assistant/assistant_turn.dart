/// Who said a turn of the assistant's chat.
enum AssistantRole { user, assistant }

/// How an assistant turn ended. `streaming` until its source closes.
enum AssistantTurnState { streaming, done, stopped, failed }

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
/// An assistant turn is written while it arrives: its [parts] keep text and
/// surfaces in the order the model sent them, so a card shows between the
/// sentence that introduces it and the one that follows. A user turn is
/// either typed ([text]) or a control of a surface pressed ([action], with the
/// control's label as its text), which the model reads as the person's answer.
class AssistantTurn {
  AssistantTurn.user(this.id, String text, {this.action})
    : role = AssistantRole.user,
      state = AssistantTurnState.done {
    parts.add(AssistantPart.text(text));
  }

  AssistantTurn.assistant(this.id)
    : role = AssistantRole.assistant,
      action = null,
      state = AssistantTurnState.streaming;

  final String id;
  final AssistantRole role;
  final String? action;
  AssistantTurnState state;
  final List<AssistantPart> parts = [];

  bool get isUser => role == AssistantRole.user;

  bool get isStreaming => state == AssistantTurnState.streaming;

  /// Nothing has arrived yet: the thread shows the thinking mark instead.
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
