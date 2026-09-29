/// Write bodies of the conversation desk (`/aries/v1/chats/...`). Keys travel
/// in UPPERCASE; the chat id travels in the body as `ID`.
library;

/// Stages a person can set by hand (`PUT /aries/v1/chats/stage`); `null` undoes.
const String kChatStageSold = "sold";
const String kChatStageEnded = "ended";

/// `POST /aries/v1/chats/messages`.
///
/// [pause] defaults to the backend's own default (pausing, so the bot does not
/// talk over the person). [minutes] is only sent when given: omitted = 24 h,
/// `0` = until resumed by hand. An already paused chat keeps its pause.
Map<String, dynamic> sendChatMessageRequest({
  required String id,
  required String message,
  bool pause = true,
  int? minutes
}) => {
  "ID": id,
  "MESSAGE": message,
  "PAUSE": pause ? 1 : 0,
  "MINUTES": ?minutes
};

/// `POST /aries/v1/chats/bot/pause`. [minutes] null or `0` = until resumed.
/// Pausing a paused chat rewrites duration and reason.
Map<String, dynamic> pauseChatRequest({
  required String id,
  int? minutes,
  String? reason
}) => {
  "ID": id,
  if (minutes != null && minutes > 0) "MINUTES": minutes,
  if (reason != null && reason.trim().isNotEmpty) "REASON": reason.trim()
};

/// `POST /aries/v1/chats/bot/resume`, `POST /aries/v1/chats/read`.
Map<String, dynamic> chatIdRequest({required String id}) => {"ID": id};

/// `PUT /aries/v1/chats/assign`. `USERNAME` is mandatory: `null` unassigns.
Map<String, dynamic> assignChatRequest({required String id, String? username}) => {
  "ID": id,
  "USERNAME": username
};

/// `PUT /aries/v1/chats/stage`: [kChatStageSold], [kChatStageEnded] or `null`
/// to undo. `sold` also settles the payment and **messages the customer**.
Map<String, dynamic> chatStageRequest({required String id, String? stage}) => {
  "ID": id,
  "STAGE": stage
};

/// `POST /aries/v1/chats/alerts/resolve`. Without [stage] every pending work
/// of the chat is resolved.
Map<String, dynamic> resolveChatRequest({required String id, String? stage}) => {
  "ID": id,
  "STAGE": ?stage
};
