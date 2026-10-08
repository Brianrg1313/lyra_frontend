import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/badges/notification_model.dart';
import 'package:app/services/badges/notifications_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sales_service.dart';

import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/badges/badge_notes.dart';
import 'package:app/screens/home/badges/badge_route.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';
import 'package:app/screens/home/sections/sales/sales_tab.dart';

/// The badges (`GET /lyra/v1/badges`, `/init`'s `badges`): the app counts nothing, it keeps the
/// backend's last answer for the active company and draws it by place. A badge anchored to two
/// anchors one place reads is one fact, counted once; the dots of a company that was left go at
/// once; `badges/changed` carries keys, never numbers, so it is answered by reading again; only
/// what may be dismissed is ever sent as seen.

/// One company with no payment method, two chats waiting and a section that is new.
Map<String, dynamic> _state() => {
  "badges": {
    "keys": ["key", "kind", "count", "level", "scope", "anchors", "action", "dismissible", "title", "data"],
    "values": [
      ["chats.attention", "count", 2, "warning", "business", ["sidebar.chats", "chats.attention"], "/chats", false, "badge_chats_attention", null],
      ["setup.payments", "alert", 1, "warning", "business", ["sidebar.business", "business.payments", "field.payment_method"], "/business/payments", false, "badge_setup_payments", null],
      ["news.money", "news", 1, "info", "device", ["sidebar.money"], "/money", true, "badge_news_money", {"until": "2026-12-31"}]
    ]
  },
  "anchors": {
    "sidebar.chats": {"count": 2, "level": "warning", "badges": ["chats.attention"]},
    "sidebar.money": {"count": 1, "level": "info", "badges": ["news.money"]}
  },
  "total": 4,
  "level": "warning",
  "date": "2026-10-06T12:00:00.000Z"
};

const _companies = {
  "keys": ["id", "name"],
  "values": [["b-1", "One"], ["b-2", "Two"]]
};

class _Transport implements BadgesTransport {
  int reads = 0;
  final List<List<String>> acknowledged = [];
  Map<String, dynamic> answer = _state();

  @override
  Future<dynamic> read() async {
    reads++;
    return answer;
  }

  @override
  Future<dynamic> seen(List<String> keys) async {
    acknowledged.add(keys);
    return {...answer, "badges": {"keys": ["key"], "values": []}, "anchors": {}};
  }

  final List<String> rows = [];

  @override
  Future<dynamic> opened(BadgeRow kind, String id) async {
    rows.add("${kind.name}:$id");
    await Future<void>.delayed(Duration.zero);
    return true;
  }
}

void main() {
  late _Transport transport;

  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  setUp(() {
    transport = _Transport();
    BadgesService().transport = transport;
    businessService.seed(_companies);
  });

  tearDown(() {
    BadgesService().clear();
    PermissionsService().clear();
    businessService.clear();
    useBusiness(null);
  });

  test("the answer reads by name, and a place counts each badge once", () {
    final state = BadgeState.fromJson(_state());

    expect(state.badges.map((badge) => badge.key), ["chats.attention", "setup.payments", "news.money"]);
    expect(state.byKey("chats.attention")!.kind, BadgeKind.count);
    expect(state.anchor("sidebar.chats").count, 2);
    expect(state.level, BadgeLevel.warning);

    // `setup.payments` is anchored to both: one fact, not two.
    final finance = state.union(BadgePlace.finance.anchors);
    expect(finance.count, 2);
    expect(finance.badges, ["setup.payments", "news.money"]);
    expect(finance.level, BadgeLevel.warning);
  });

  test("a field finer than any anchor reads its badges by key", () {
    final state = BadgeState.fromJson({
      ..._state(),
      "badges": {
        "keys": ["key", "kind", "count", "level", "scope", "anchors", "dismissible", "title"],
        "values": [
          ["setup.country", "alert", 1, "warning", "business", ["sidebar.business", "business.profile"], false, "badge_setup_country"],
          ["setup.logo", "alert", 1, "info", "business", ["sidebar.business", "business.profile"], true, "badge_setup_logo"]
        ]
      }
    });

    expect(state.union(BadgePlace.countryField.anchors, keys: BadgePlace.countryField.keys).badges, ["setup.country"]);
    expect(state.union(BadgePlace.logoField.anchors, keys: BadgePlace.logoField.keys).badges, ["setup.logo"]);
    expect(state.union(BadgePlace.businessSettings.anchors).badges, hasLength(2));
  });

  test("/init's badges are kept only when they were measured for the active company", () async {
    BadgesService().seed(_state(), business: "b-1");

    expect(transport.reads, 0);
    expect(BadgesService().at(BadgePlace.messages).count, 2);

    BadgesService().clear();
    BadgesService().seed(_state(), business: "b-2");
    await Future<void>.delayed(Duration.zero);

    expect(transport.reads, 1, reason: "measured for another company: read for the active one");
  });

  test("badges/changed is answered by reading again, a burst as one read", () async {
    BadgesService().seed(_state(), business: "b-1");

    ConnectionService().receive(BadgesService.changedEvent, {"badges": [], "stale": ["chats.attention"]});
    ConnectionService().receive(BadgesService.changedEvent, {"badges": [], "stale": ["pos.invoices"]});
    ConnectionService().receive(BadgesService.resetEvent, {});
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(transport.reads, 1);
  });

  test("a company switch drops the dots of the one left before the new ones arrive", () async {
    BadgesService().seed(_state(), business: "b-1");
    businessService.selectBusiness("b-2");

    expect(BadgesService().state.isEmpty, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(transport.reads, 1);
    expect(BadgesService().at(BadgePlace.messages).count, 2);
  });

  test("only what may be dismissed is sent as seen, and it leaves at once", () async {
    BadgesService().seed(_state(), business: "b-1");

    final done = BadgesService().seen(["news.money", "setup.payments"]);
    expect(BadgesService().state.byKey("news.money"), isNull);
    expect(BadgesService().state.byKey("setup.payments"), isNotNull);

    await done;
    expect(transport.acknowledged, [["news.money"]]);

    await BadgesService().seen(["setup.payments"]);
    expect(transport.acknowledged, hasLength(1), reason: "nothing dismissible: nothing sent");
  });

  test("opening a section finds the news it shows", () async {
    BadgesService().seed(_state(), business: "b-1");

    BadgesService().discover(BadgePlace.finance);
    await Future<void>.delayed(Duration.zero);

    expect(transport.acknowledged, [["news.money"]]);
  });

  test("a badge opens the tab that fixes it, not the section the backend names", () {
    final payments = BadgeState.fromJson(_state()).byKey("setup.payments")!;

    expect(badgeRoute(payments, business: "b-1"), FinanceTab.methods.path);
    expect(badgeRoute(const BadgeModel(key: "x", kind: BadgeKind.count, count: 1, level: BadgeLevel.info)), isNull);
  });

  test("a customer waiting, a sale going and a question left light their own side bar entries", () {
    final state = BadgeState.fromJson({
      "badges": {
        "keys": ["key", "kind", "count", "level", "scope", "anchors", "dismissible", "title"],
        "values": [
          ["chats.attention", "count", 1, "warning", "business", ["sidebar.chats", "chats.attention"], false, "badge_chats_attention"],
          ["chats.unread", "count", 3, "info", "user", ["sidebar.chats", "chats.unread"], false, "badge_chats_unread"],
          ["sales.new", "count", 2, "info", "user", ["sidebar.sales", "sales.process"], false, "badge_sales_new"],
          ["knowledge.pending", "count", 4, "warning", "business", ["sidebar.knowledge", "knowledge.pending"], false, "badge_knowledge_pending"]
        ]
      }
    });

    final messages = state.union(BadgePlace.section("messages")!.anchors);
    expect(messages.count, 4, reason: "both chat counters are the conversations entry's");
    expect(messages.level, BadgeLevel.warning);

    expect(state.union(BadgePlace.section("sales")!.anchors).count, 2);
    expect(state.union(SalesTab.process.badge!.anchors).count, 2);
    expect(SalesTab.done.badge, isNull, reason: "a finished sale is not work");
    expect(state.union(BadgePlace.section("knowledge")!.anchors).count, 4);

    expect(badgeRoute(state.byKey("sales.new")!), HomeSection.sales.path);
    expect(badgeRoute(state.byKey("knowledge.pending")!), HomeSection.knowledge.path);
    expect(badgeRoute(state.byKey("chats.unread")!), HomeSection.messages.path);
  });

  test("a sale opened is sent by its chat, and its marker leaves every list holding it", () async {
    BadgesService().seed(_state(), business: "b-1");

    final service = SalesService();
    addTearDown(service.dispose);

    final sales = [
      SaleModel.fromJson({"id": "t-1", "source": "ticket", "chat": "c-1", "unseen": true}),
      SaleModel.fromJson({"id": "t-2", "source": "ticket"}),
      SaleModel.fromJson({"id": "c-3", "source": "chat", "chat": "c-3", "unseen": true})
    ];
    service.seed(sales);

    service.review(service.sales.first);
    expect(service.sales.first.unseen, isFalse, reason: "the row does not wait for the answer");

    service.review(service.sales[1]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(transport.rows, ["sale:c-1"], reason: "a counter sale has no chat and is never new");

    // Opened on another screen of the same person: only a sale's notice clears a sale.
    ConnectionService().receive(BadgesService.openedEvent, {"kind": "chat", "id": "c-3"});
    expect(service.sales.last.unseen, isTrue);
    ConnectionService().receive(BadgesService.openedEvent, {"kind": "sale", "id": "c-3"});
    expect(service.sales.last.unseen, isFalse);
  });

  test("a row opened again while its last opening travels is sent once more after it", () async {
    BadgesService().seed(_state(), business: "b-1");

    final first = BadgesService().opened(BadgeRow.chat, "c-1");
    await BadgesService().opened(BadgeRow.chat, "c-1");
    await first;

    expect(transport.rows, ["chat:c-1", "chat:c-1"],
      reason: "a customer writing into the open chat while it was being sent is read too");
  });

  test("a notification reads as the backend sends it and opens the section it is about", () {
    final ticket = NotificationModel.fromJson({
      "id": "n-1",
      "type": "sale.ticket",
      "title": "Nuevo ticket de venta",
      "body": "Ana · #K3F9",
      "level": "success",
      "link": "/sales",
      "data": {"chat": "c-1", "ticket": "K3F9"},
      "seen": false,
      "date": "2026-10-07T12:00:00.000Z"
    })!;

    expect(ticket.area, "sales");
    expect(ticket.level, BadgeLevel.info);
    expect(notificationRoute(ticket), HomeSection.sales.path);
    expect(ticket.asSeen.seen, isTrue);

    expect(NotificationModel.fromJson({"id": "n-2", "type": "chat.new"}), isNull, reason: "nothing to read");
    expect(notificationRoute(NotificationModel.fromJson({"id": "n-3", "type": "import.finished", "title": "x"})!), isNull);
  });

  test("notification/new lands on top of the feed, once, and only for whoever can open its section", () async {
    BadgesService().seed(_state(), business: "b-1");
    PermissionsService().seed({"b-1": {"sales": {"view": true}}});

    Map<String, dynamic> pushed(String id, String type) => {
      "id": id, "type": type, "title": "t-$id", "level": "info", "seen": false, "date": "2026-10-07T12:00:00.000Z"
    };

    ConnectionService().receive(NotificationsService.newEvent, pushed("n-1", "sale.ticket"));
    ConnectionService().receive(NotificationsService.newEvent, pushed("n-1", "sale.ticket"));
    ConnectionService().receive(NotificationsService.newEvent, pushed("n-2", "chat.new"));
    ConnectionService().receive(NotificationsService.newEvent, pushed("n-3", "import.finished"));

    expect(NotificationsService().recent.map((notification) => notification.id), ["n-3", "n-1"],
      reason: "the chats are not this person's: a customer's first words stay off their screen");

    NotificationsService().markSeen();
    expect(NotificationsService().recent.every((notification) => notification.seen), isTrue);

    BadgesService().clear();
    expect(NotificationsService().recent, isEmpty, reason: "signing out forgets the feed");
  });

  testWidgets("a place that counts shows its number, one with only alerts a dot, a clear one nothing", (tester) async {
    BadgesService().seed(_state(), business: "b-1");

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      AppSize.instance(context);
      return const Column(children: [
        BadgeMark(key: ValueKey("chats"), place: BadgePlace.messages),
        BadgeMark(key: ValueKey("methods"), place: BadgePlace.financeMethods),
        BadgeMark(key: ValueKey("pos"), place: BadgePlace.pos)
      ]);
    })));

    expect(find.descendant(of: find.byKey(const ValueKey("chats")), matching: find.text("2")), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey("methods")), matching: find.byType(Container)), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey("methods")), matching: find.text("1")), findsNothing);
    expect(find.descendant(of: find.byKey(const ValueKey("pos")), matching: find.byType(Container)), findsNothing);
  });

  testWidgets("a page says in words what its place has pending, and nothing when clear", (tester) async {
    BadgesService().seed(_state(), business: "b-1");

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: Builder(builder: (context) {
        AppSize.instance(context);
        return const Column(children: [
          BadgeNotes(key: ValueKey("methods"), place: BadgePlace.financeMethods),
          BadgeNotes(key: ValueKey("pos"), place: BadgePlace.pos)
        ]);
      })
    ));
    await tester.pump();

    expect(find.descendant(of: find.byKey(const ValueKey("methods")), matching: find.text(S.current.badge_setup_payments)), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey("pos")), matching: find.byType(Container)), findsNothing);
  });
}
