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
import 'package:app/services/connection/connection_service.dart';

import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/badges/badge_route.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';

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
}
