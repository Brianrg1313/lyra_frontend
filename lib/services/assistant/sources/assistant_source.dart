/// What the assistant is asked in one turn.
///
/// [action] is set when the person pressed a control of a surface instead of
/// typing: its event name, with the label it showed in [prompt] and what the
/// control carried in [context].
class AssistantRequest {
  const AssistantRequest({
    required this.prompt,
    this.action,
    this.context = const {}
  });

  final String prompt;
  final String? action;
  final Map<String, Object?> context;
}

/// Where the assistant's answers come from.
///
/// An answer is the model's raw output: text chunks with A2UI messages
/// (`createSurface`, `updateComponents`…) inlined as JSON blocks, which
/// GenUI's `A2uiTransportAdapter` splits into the chat's text and its
/// surfaces. A source only streams; parsing and state are the service's.
abstract class AssistantSource {
  Stream<String> reply(AssistantRequest request);
}
