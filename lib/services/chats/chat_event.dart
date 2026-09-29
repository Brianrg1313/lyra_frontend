/// Socket events of the conversation desk. They reach every user of the company
/// with no subscription (`chat/alert` and `chat/assigned` only reach their
/// person). Fire and forget: missed ones are gone, so a restored connection
/// rereads.
abstract final class ChatEvent {
  /// A message was stored (customer, bot, person or system).
  static const String message = "chat/message";

  /// Ticks of one message.
  static const String status = "chat/message/status";

  /// A provisional outgoing id (`ticket`) became the real one (`message_id`).
  static const String rekeyed = "chat/message/rekeyed";

  /// An attention mark was raised: notify.
  static const String attention = "chat/attention";

  /// The attention marks were fully cleared.
  static const String attended = "chat/attended";

  /// The customer wrote to a paused conversation: notify.
  static const String alert = "chat/alert";

  /// Who answers changed (pause, resume, assign).
  static const String handover = "chat/handover";

  /// The conversation was assigned to the receiving user: notify.
  static const String assigned = "chat/assigned";

  /// The measured stage changed.
  static const String stage = "chat/stage";

  /// The measured tags changed. Carries the whole set: `tags` (codes) and
  /// `detail` (full). `silent` depends on the clock and has no event.
  static const String tags = "chat/tags";
}
