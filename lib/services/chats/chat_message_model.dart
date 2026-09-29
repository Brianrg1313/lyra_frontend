// SERVICES
import 'package:app/services/chats/chat_model.dart';
import 'package:app/services/files/file_model.dart';

/// Who wrote a message.
enum ChatAuthorKind {
  customer,
  bot,

  /// A person from the desk (carries `username` and `name`).
  operator,

  /// An automatic message of the server (`reason: "confirmation"`).
  system;

  static ChatAuthorKind from(dynamic raw) => switch (raw?.toString().trim()) {
    "bot" => ChatAuthorKind.bot,
    "operator" => ChatAuthorKind.operator,
    "system" => ChatAuthorKind.system,
    _ => ChatAuthorKind.customer
  };
}

/// Delivery state of a message: incoming ones are always [received]; outgoing
/// ones go `sent → delivered → read`, or [failed].
enum ChatMessageStatus {
  received,
  sent,
  delivered,
  read,
  failed;

  static ChatMessageStatus from(dynamic raw) => switch (raw?.toString().trim()) {
    "sent" => ChatMessageStatus.sent,
    "delivered" => ChatMessageStatus.delivered,
    "read" => ChatMessageStatus.read,
    "failed" => ChatMessageStatus.failed,
    _ => ChatMessageStatus.received
  };
}

/// One message of the history, or of a `chat/message` event.
class ChatMessage {
  const ChatMessage({
    required this.id,
    this.chat = "",
    this.incoming = true,
    this.type = "text",
    this.text = "",
    this.media,
    this.status = ChatMessageStatus.received,
    this.author = ChatAuthorKind.customer,
    this.authorName = "",
    this.date,
    this.cursor = "",
    this.queued = false
  });

  /// WhatsApp id: the key ticks and dedupe run on. On `personal` numbers an
  /// outgoing message starts with a provisional id that `chat/message/rekeyed`
  /// replaces.
  final String id;
  final String chat;

  /// `direction: in` (the customer) vs `out` (the company).
  final bool incoming;

  /// `text` · `image` · `audio`.
  final String type;

  /// Text, or caption / transcription / generated description for media.
  final String text;

  /// The picture of an image message. A file id, not an address.
  final FileModel? media;
  final ChatMessageStatus status;
  final ChatAuthorKind author;

  /// Operator's name, when [author] is [ChatAuthorKind.operator].
  final String authorName;
  final DateTime? date;

  /// Position in the history; only on history pages.
  final String cursor;

  /// Sent while the `personal` phone was offline (`live: false`): it leaves when
  /// the phone reconnects. Local knowledge only, from the send answer.
  final bool queued;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final author = json["author"];

    return ChatMessage(
      id: chatText(json["id"]),
      chat: chatText(json["chat"]),
      incoming: chatText(json["direction"]) != "out",
      type: chatText(json["type"]).isEmpty ? "text" : chatText(json["type"]),
      text: json["text"]?.toString() ?? "",
      media: FileModel.from(json["media"]),
      status: ChatMessageStatus.from(json["status"]),
      author: ChatAuthorKind.from(author is Map ? author["kind"] : null),
      authorName: author is Map ? chatText(author["name"]) : "",
      date: chatDate(json["date"]),
      cursor: chatText(json["cursor"])
    );
  }

  ChatMessage withStatus(ChatMessageStatus value) => _copy(status: value);

  ChatMessage withId(String value) => _copy(id: value);

  ChatMessage asQueued() => _copy(queued: true);

  ChatMessage _copy({String? id, ChatMessageStatus? status, bool? queued}) =>
    ChatMessage(
      id: id ?? this.id,
      chat: chat,
      incoming: incoming,
      type: type,
      text: text,
      media: media,
      status: status ?? this.status,
      author: author,
      authorName: authorName,
      date: date,
      cursor: cursor,
      // A tick past `sent` means the phone came back and the message left.
      queued: queued ?? (_leftQueue(status) ? false : this.queued)
    );

  static bool _leftQueue(ChatMessageStatus? status) =>
    status == ChatMessageStatus.delivered || status == ChatMessageStatus.read;
}

/// One page of `GET /aries/v1/chats/messages/:ID`, oldest first.
class ChatMessagesPage {
  const ChatMessagesPage({
    required this.messages,
    this.before,
    this.isLoaded = true
  });

  final List<ChatMessage> messages;

  /// Opaque cursor of the next older page; null when there is nothing older.
  final String? before;
  final bool isLoaded;

  factory ChatMessagesPage.fromResponse(dynamic data) {
    if (data is! Map || data["messages"] is! List) {
      return const ChatMessagesPage(messages: [], isLoaded: false);
    }

    final before = chatText(data["before"]);

    return ChatMessagesPage(
      before: before.isEmpty ? null : before,
      messages: [
        for (final row in data["messages"] as List)
          if (chatEvent(row) case final json?)
            if (ChatMessage.fromJson(json) case final message when message.id.isNotEmpty)
              message
      ]
    );
  }
}
