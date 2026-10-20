import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:provider/provider.dart';

import 'package:app/generated/l10n.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/messages/inbox/_inbox.dart';
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/chats/chat_event.dart';
import 'package:app/services/chats/chat_model.dart';
import 'package:app/services/chats/chat_request.dart';
import 'package:app/services/chats/chats_service.dart';
import 'package:app/toolkit/settings/routes.dart';
import 'package:app/screens/home/sections/messages/tags/chat_tag_color.dart';

/// What the messages inbox runs on: rows decoded **by key name** from the
/// compressed `keys`/`values` list, the write bodies exactly as `/aries/v1`
/// takes them, and socket events applied to the rows already held (a message
/// moves its row to the top, a handover replaces `bot` and `assignee` whole, a
/// stage relabels) — without a reread the event already answers.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);

    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Map<String, dynamic> page(List<List<dynamic>> values, {List<String>? keys, int total = 1}) => {
    "page": 1,
    "size": 50,
    "total": total,
    "chats": {
      "keys": keys ?? ["id", "contact", "name", "stage", "label", "level", "attention", "waiting",
        "answered", "awaiting", "activity", "bot", "assignee"],
      "values": values
    }
  };

  ChatModel row(String id, {bool answered = true}) => ChatModel(
    id: id,
    contact: "58412$id",
    name: "Customer $id",
    answered: answered,
    activity: DateTime.utc(2026, 9, 16, 18)
  );

  group('routing', () {
    test('the messages section is its own url and needs a business', () {
      final match = Navis().match(HomeSection.messages.path);

      expect(match?.route.key, HomeSection.messages.key);
      expect(HomeSection.messages.needsBusiness, isTrue);
      expect(
        HomeSection.operations.indexOf(HomeSection.messages),
        HomeSection.operations.indexOf(HomeSection.sales) + 1
      );
    });
  });

  group('decoding', () {
    test('a row is read by key name, not by position', () {
      final result = ChatsPage.fromResponse(page(
        [[null, "Brian", "584126766990", "6aaadd9f", "paying", "Esperando el pago", "info"]],
        keys: ["awaiting", "name", "contact", "id", "stage", "label", "level"]
      ));

      final chat = result.chats.single;

      expect(chat.id, "6aaadd9f");
      expect(chat.contact, "584126766990");
      expect(chat.title, "Brian");
      expect(chat.stage.stage, "paying");
      expect(chat.stage.label, "Esperando el pago");
    });

    test('a nameless customer is titled by their number', () {
      final chat = ChatsPage.fromResponse(page(
        [["c1", "584126766990", null, "inquiry", "Consulta", "info", false, null, true, null,
          "2026-09-16T18:23:34.334Z", null, null]]
      )).chats.single;

      expect(chat.title, "584126766990");
      expect(chat.assignee, isNull);
      expect(chat.bot.active, isTrue);
    });

    test('a row carries its tag codes in drawing order', () {
      final chat = ChatsPage.fromResponse(page(
        [["c1", ["question", "reserved", "", "unpaid"]]],
        keys: ["id", "tags"]
      )).chats.single;

      expect(chat.tags, ["question", "reserved", "unpaid"]);
    });

    test('the tag catalog names codes, and an unknown code is kept bare', () {
      final service = ChatsService()
        ..seedTags(ChatTag.catalogFrom({
          "keys": ["tag", "name", "group", "level", "attention"],
          "values": [["failure", "Falló el bot", "chat", "critical", true]]
        }));

      addTearDown(service.dispose);

      final failure = service.tagOf("failure");

      expect(failure.label, "Falló el bot");
      expect(failure.level, ChatLevel.critical);
      expect(failure.attention, isTrue);
      expect(service.tagOf("brand_new").label, "brand_new");
    });

    test('a tag that repeats the stage is not drawn beside it', () {
      const tags = [ChatTag(tag: "question"), ChatTag(tag: "reserved"), ChatTag(tag: "unpaid")];

      expect(
        chatTagsBeside(const ChatStage(stage: "reserving"), tags).map((tag) => tag.tag),
        ["question", "unpaid"]
      );
      expect(
        chatTagsBeside(const ChatStage(stage: "paying"), tags).map((tag) => tag.tag),
        ["question", "reserved"]
      );
      expect(chatTagsBeside(const ChatStage(stage: "inquiry"), tags), hasLength(3));
    });

    test('a summary that could not measure awaiting keeps null, not zero', () {
      expect(ChatSummary.from({"awaiting": null, "attention": 1}).awaiting, isNull);
      expect(ChatsFilter.unanswered.countIn(const ChatSummary()), isNull);
    });

    test('a pause whose until passed reads as resumed', () {
      final bot = ChatBot.from({
        "enabled": true,
        "paused": true,
        "active": false,
        "until": "2026-09-16T19:00:00.000Z"
      });

      expect(bot.isPausedAt(DateTime.utc(2026, 9, 16, 18, 59)), isTrue);
      expect(bot.isPausedAt(DateTime.utc(2026, 9, 16, 19, 1)), isFalse);
    });
  });

  group('requests', () {
    test('assign always sends USERNAME, null unassigns', () {
      expect(assignChatRequest(id: "c1"), {"ID": "c1", "USERNAME": null});
    });

    test('a pause without minutes or reason sends only the id', () {
      expect(pauseChatRequest(id: "c1", minutes: 0, reason: "  "), {"ID": "c1"});
      expect(pauseChatRequest(id: "c1", minutes: 30, reason: "Price"),
        {"ID": "c1", "MINUTES": 30, "REASON": "Price"});
    });

    test('a reply omits MINUTES unless given', () {
      expect(sendChatMessageRequest(id: "c1", message: "Hi"),
        {"ID": "c1", "MESSAGE": "Hi", "PAUSE": 1});
    });

    test('undoing a manual stage sends STAGE null', () {
      expect(chatStageRequest(id: "c1"), {"ID": "c1", "STAGE": null});
    });

    test('resolving sends only what is given; an answer names its question', () {
      expect(resolveChatRequest(id: "c1"), {"ID": "c1"});
      expect(resolveChatRequest(id: "c1", stage: "question", questionId: "3f1c9a0b7e2d", answer: "No, one pair"),
        {"ID": "c1", "STAGE": "question", "QUESTION_ID": "3f1c9a0b7e2d", "ANSWER": "No, one pair"});
    });
  });

  group('socket events', () {
    late ChatsService service;

    setUp(() => service = ChatsService());

    // Disposing cancels the debounced rereads, so nothing reaches the network.
    tearDown(() => service.dispose());

    test('a message moves its row to the top and updates it', () {
      service.seed([row("a"), row("b"), row("c")]);

      service.receive(ChatEvent.message, {
        "id": "c",
        "name": "Renamed",
        "created": false,
        "activity": "2026-09-16T19:30:00.000Z",
        "answered": false,
        "awaiting": "2026-09-16T19:30:00.000Z",
        "message": {"id": "m1", "direction": "in", "text": "Hi"}
      });

      expect(service.chats.map((chat) => chat.id), ["c", "a", "b"]);
      expect(service.chats.first.name, "Renamed");
      expect(service.chats.first.answered, isFalse);
      expect(service.chats.first.awaiting, DateTime.utc(2026, 9, 16, 19, 30));
    });

    test('the customer writing marks a row unread, unless it is the open one, and opening clears it', () {
      service.seed([row("a"), row("b")]);
      service.select("b");

      for (final id in ["a", "b"]) {
        service.receive(ChatEvent.message, {
          "id": id,
          "created": false,
          "message": {"id": "m-$id", "direction": "in", "text": "Hi"}
        });
      }
      service.receive(ChatEvent.message, {
        "id": "a",
        "created": false,
        "message": {"id": "m-out", "direction": "out", "text": "Hello"}
      });

      ChatModel of(String id) => service.chats.firstWhere((chat) => chat.id == id);

      expect(of("a").unseen, isTrue, reason: "our own reply does not read it for this person");
      expect(of("b").unseen, isFalse, reason: "it is open: its panel reads it as it lands");

      service.receive(BadgesService.openedEvent, {"kind": "chat", "id": "a"});
      expect(of("a").unseen, isFalse);
      expect(ChatsPage.fromResponse(page([["x", true]], keys: ["id", "unseen"])).chats.single.unseen, isTrue);
    });

    test('an answer takes the row off the unanswered tab', () {
      service.seed([row("a", answered: false)], filter: ChatsFilter.unanswered);

      service.receive(ChatEvent.message, {"id": "a", "answered": true, "awaiting": null});

      expect(service.chats, isEmpty);
      expect(service.status, ChatsStatus.empty);
    });

    test('a handover replaces bot and assignee whole', () {
      service.seed([row("a").handedOver(
        bot: const ChatBot(),
        assignee: const ChatPerson(username: "u1", name: "Ana")
      )]);

      service.receive(ChatEvent.handover, {
        "id": "a",
        "bot": {"enabled": true, "paused": true, "active": false},
        "assignee": null
      });

      expect(service.chats.single.bot.paused, isTrue);
      expect(service.chats.single.assignee, isNull);
    });

    test('a stage event relabels with label, not name', () {
      service.seed([row("a")]);

      service.receive(ChatEvent.stage, {
        "id": "a",
        "stage": "verifying",
        "label": "Verificando el pago",
        "level": "warning",
        "attention": true
      });

      expect(service.chats.single.stage.label, "Verificando el pago");
      expect(service.chats.single.stage.level, ChatLevel.warning);
      expect(service.chats.single.name, "Customer a");
    });

    test('a tags event replaces the whole set', () {
      service.seed([const ChatModel(id: "a", tags: ["question", "reserved"])]);

      service.receive(ChatEvent.tags, {
        "id": "a",
        "chat": "a",
        "tags": ["reserved", "unpaid", "shipped"]
      });

      expect(service.chats.single.tags, ["reserved", "unpaid", "shipped"]);

      service.receive(ChatEvent.tags, {"id": "a", "tags": []});

      expect(service.chats.single.tags, isEmpty);
    });

    test('attended clears the waiting mark', () {
      service.seed([row("a").flagged(ChatWaiting.pending)]);

      service.receive(ChatEvent.attended, {"chat": "a"});

      expect(service.chats.single.waiting, isNull);
    });

    test('a new session past page one is counted, not redrawn', () {
      service.seed([row("a")], total: 120, page: 2);

      service.receive(ChatEvent.message, {"id": "z", "created": true});

      expect(service.pending, 1);
      expect(service.chats.map((chat) => chat.id), ["a"]);
    });
  });

  group('inbox panel', () {
    testWidgets('draws a third-width list without overflowing', (tester) async {
      final service = ChatsService()
        ..seed([
          row("a", answered: false).flagged(ChatWaiting.failure),
          const ChatModel(
            id: "b",
            contact: "584126766990",
            name: "A customer with a very long WhatsApp profile name 🌸🌸",
            stage: ChatStage(stage: "verifying", label: "Verificando el pago", attention: true),
            bot: ChatBot(paused: true, active: false),
            tags: ["question", "reserved", "unpaid", "preparing"]
          )
        ], total: 2)
        ..seedTags(const [
          ChatTag(tag: "question", name: "Pregunta", level: ChatLevel.warning, attention: true),
          ChatTag(tag: "reserved", name: "Reserva"),
          ChatTag(tag: "unpaid", name: "Sin pago"),
          ChatTag(tag: "preparing", name: "Preparando envío", level: ChatLevel.warning, attention: true)
        ]);

      addTearDown(service.dispose);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (context) {
          AppSize.instance(context);

          return ChangeNotifierProvider<ChatsService>.value(
            value: service,
            child: const Center(child: SizedBox(width: 320, height: 600, child: InboxPanel()))
          );
        })
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Customer a"), findsOneWidget);
      expect(find.text("Verificando el pago"), findsOneWidget);
      expect(find.text("Pregunta"), findsOneWidget);
      expect(find.text("Preparando envío"), findsOneWidget);
    });
  });
}
