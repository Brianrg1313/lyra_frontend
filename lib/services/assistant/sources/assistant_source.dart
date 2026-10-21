// SERVICES
import '../assistant_line.dart';

/// Where the panel's assistant lives (`docs/guides/asistente-frontend.md` in
/// the backend): one open conversation per person and company, kept on the
/// server.
///
/// An answer comes **whole**, when the assistant has finished (its run can
/// take a couple of minutes): no stream, and nothing to stop it with. Its text
/// may carry A2UI blocks; splitting them out is the service's.
abstract interface class AssistantSource {
  /// The open conversation, whole (`thread` null when there is none).
  Future<AssistantBatch> read();

  /// One message; answers the new lines (the person's and the assistant's) and
  /// what it now waits to be confirmed. Throws the normalised error
  /// (`assistant_busy` while the previous one is being answered). [app] is
  /// what this screen runs for the assistant (`AssistantAppTools.declared`).
  Future<AssistantBatch> send(String message, {Map<String, Object?>? app});

  /// The person's yes or no on a pending; answers its `event` line.
  Future<AssistantBatch> confirm(String id, {required bool yes});

  /// Closes the conversation: the next message starts a new one.
  Future<void> close();
}
