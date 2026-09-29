import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/chats/chat_detail_model.dart';
import 'package:app/services/chats/chat_event.dart';
import 'package:app/services/chats/chat_message_model.dart';
import 'package:app/services/chats/chat_model.dart';
import 'package:app/services/chats/chat_thread_service.dart';

/// What the open conversation runs on: the same message arrives by the send
/// answer and by the socket, so it is **deduplicated by id**; ticks never go
/// backwards; a provisional id is renamed by `chat/message/rekeyed`; and events
/// for another conversation are ignored.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatThreadService thread;

  setUp(() {
    thread = ChatThreadService(id: "c1")
      ..seed(detail: const ChatDetailModel(id: "c1", answered: false));
  });

  tearDown(() => thread.dispose());

  Map<String, dynamic> message(String id, {String status = "sent", String direction = "out"}) => {
    "id": id,
    "chat": "c1",
    "direction": direction,
    "type": "text",
    "text": "Hello",
    "status": status,
    "author": {"kind": "operator", "username": "u1", "name": "Ana"},
    "date": "2026-09-16T19:30:00.000Z"
  };

  test('a history page is oldest first and keeps its cursor', () {
    final page = ChatMessagesPage.fromResponse({
      "messages": [message("m1", direction: "in"), message("m2")],
      "before": "6aaadd9f.10"
    });

    expect(page.messages.map((m) => m.id), ["m1", "m2"]);
    expect(page.messages.first.incoming, isTrue);
    expect(page.messages.last.authorName, "Ana");
    expect(page.before, "6aaadd9f.10");
    expect(ChatMessagesPage.fromResponse({"messages": [], "before": null}).before, isNull);
  });

  test('a message delivered twice is kept once', () {
    thread.receive(ChatEvent.message, {"id": "c1", "message": message("m1")});
    thread.receive(ChatEvent.message, {"id": "c1", "message": message("m1")});

    expect(thread.messages.length, 1);
  });

  test('a message for another conversation is ignored', () {
    thread.receive(ChatEvent.message, {"id": "other", "message": message("m1")});

    expect(thread.messages, isEmpty);
  });

  test('the chat/message event updates answered and awaiting', () {
    thread.receive(ChatEvent.message, {
      "id": "c1",
      "answered": true,
      "awaiting": null,
      "message": message("m1")
    });

    expect(thread.detail!.answered, isTrue);
    expect(thread.detail!.awaiting, isNull);
  });

  test('ticks move forward and an older echo does not undo them', () {
    thread.receive(ChatEvent.message, {"id": "c1", "message": message("m1")});

    thread.receive(ChatEvent.status, {"chat": "c1", "message_id": "m1", "status": "read"});
    expect(thread.messages.single.status, ChatMessageStatus.read);

    thread.receive(ChatEvent.message, {"id": "c1", "message": message("m1", status: "delivered")});
    expect(thread.messages.single.status, ChatMessageStatus.read);
  });

  test('a provisional id is renamed to the real one', () {
    thread.receive(ChatEvent.message, {"id": "c1", "message": message("ticket-1")});

    thread.receive(ChatEvent.rekeyed, {"chat": "c1", "ticket": "ticket-1", "message_id": "3EB0"});

    expect(thread.messages.single.id, "3EB0");
  });

  test('a rekey whose real id already arrived leaves one message', () {
    thread.receive(ChatEvent.message, {"id": "c1", "message": message("ticket-1")});
    thread.receive(ChatEvent.message, {"id": "c1", "message": message("3EB0")});

    thread.receive(ChatEvent.rekeyed, {"chat": "c1", "ticket": "ticket-1", "message_id": "3EB0"});

    expect(thread.messages.map((m) => m.id), ["3EB0"]);
  });

  test('a queued message stops being queued once delivered', () {
    final queued = ChatMessage.fromJson(message("m1")).asQueued();

    expect(queued.withStatus(ChatMessageStatus.sent).queued, isTrue);
    expect(queued.withStatus(ChatMessageStatus.delivered).queued, isFalse);
  });

  test('a handover replaces bot and assignee on the open chat', () {
    thread.receive(ChatEvent.handover, {
      "id": "c1",
      "bot": {"enabled": true, "paused": true, "active": false, "by": {"username": "u1", "name": "Ana"}},
      "assignee": {"username": "u1", "name": "Ana"}
    });

    expect(thread.detail!.bot.paused, isTrue);
    expect(thread.detail!.bot.by?.label, "Ana");
    expect(thread.detail!.assignee?.username, "u1");
  });

  test('the detail keeps the most urgent mark first and the rest in also', () {
    final detail = ChatDetailModel.fromJson({
      "id": "c1",
      "attention": {
        "kind": "failure",
        "stage": "reply",
        "partial": true,
        "also": [{"kind": "pending", "stage": "question", "detail": "¿Envíos?"}]
      },
      "cart": [{"id": "p1", "label": "Perfume", "state": "reserved", "qty": 1}],
      "sessions": 2,
      "tags": [
        {"tag": "question", "label": "Pregunta", "group": "chat", "level": "warning", "attention": true,
          "since": "2026-09-16T18:23:34.341Z", "tickets": []},
        {"tag": "unpaid", "label": "Sin pago", "group": "payment", "level": "info", "attention": false,
          "since": "2026-09-16T18:20:37.150Z", "tickets": ["4GEL-ZAQM"]}
      ]
    });

    expect(detail.attention!.kind.name, "failure");
    expect(detail.attention!.partial, isTrue);
    expect(detail.attention!.all.map((a) => a.kind.name), ["failure", "pending"]);
    expect(detail.cart.single.isReserved, isTrue);
    expect(detail.sessions, 2);
    expect(detail.tags.map((tag) => tag.label), ["Pregunta", "Sin pago"]);
    expect(detail.tags.first.attention, isTrue);
    expect(detail.tags.last.tickets, ["4GEL-ZAQM"]);
    expect(detail.tags.last.since, DateTime.utc(2026, 9, 16, 18, 20, 37, 150));
  });

  test('a tags event replaces the open chat tags, named by its detail', () {
    thread.seed(detail: const ChatDetailModel(id: "c1", tags: [ChatTag(tag: "question")]));

    thread.receive(ChatEvent.tags, {
      "id": "c1",
      "tags": ["unpaid", "shipped"],
      "detail": [
        {"tag": "unpaid", "name": "Sin pago", "group": "payment", "level": "info", "tickets": ["4GEL-ZAQM"]},
        {"tag": "shipped", "name": "Enviado", "group": "delivery", "level": "info", "tickets": ["4GEL-ZAQM"]}
      ]
    });

    expect(thread.detail!.tags.map((tag) => tag.label), ["Sin pago", "Enviado"]);
    expect(thread.detail!.tags.first.tickets, ["4GEL-ZAQM"]);

    thread.receive(ChatEvent.tags, {"id": "other", "tags": []});

    expect(thread.detail!.tags, hasLength(2));
  });

  test('the detail reads the session AI spend and keeps a failed read apart from zero', () {
    final detail = ChatDetailModel.fromJson({
      "id": "c1",
      "usage": {
        "cost": 0.205514, "input": 251947, "output": 6465, "cached": 170251, "requests": 27,
        "areas": {
          "replies": {"requests": 14, "input": 237800, "output": 6372, "cost": 0.201929},
          "media": {"requests": 0, "input": 0, "output": 0, "cost": 0}
        }
      }
    });

    final usage = detail.usage!;
    expect(usage.cost, 0.205514);
    expect(usage.input, 251947);
    expect(usage.cached, 170251);
    expect(usage.requests, 27);
    expect(usage.isEmpty, isFalse);
    expect(usage.areas.keys, ["replies", "media"]);
    expect(usage.areas["replies"]!.ran, isTrue);
    expect(usage.areas["media"]!.ran, isFalse);

    expect(ChatDetailModel.fromJson({"id": "c1", "usage": null}).usage, isNull);
    expect(ChatDetailModel.fromJson({"id": "c1", "usage": {"cost": 0, "requests": 0}}).usage!.isEmpty, isTrue);
    expect(detail.copyWith(name: "Ana").usage, same(usage));
  });
}
