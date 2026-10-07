import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/screens/home/sections/_section/section_tabs.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';
import 'package:app/screens/home/sections/sales/sales_tab.dart';

/// **Tabs gated by permission**: each tab is the area `<section>.<key>`, the bare section
/// opens on the first granted tab, and a locked tab is marked in the bar (it still opens,
/// onto the "no access" message).
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });
  // The app's instance: permissions default to its active company.
  setUp(() => businessService.seed({
    "keys": ["id", "name"],
    "values": [["b-1", "One"]]
  }));
  tearDown(() => PermissionsService().clear());

  test('each tab is its section area', () {
    expect(BusinessTab.employees.area, "business.employees");
    expect(FinanceTab.methods.area, "finance.methods");
    expect(SalesTab.done.area, "sales.done");
  });

  test('the bare section opens on the initial tab while it is granted', () {
    PermissionsService().seed({
      "b-1": {
        "business": {"view": true, "statistics": {"view": true}, "settings": {"view": true}},
        "sales": {"view": true, "process": {"view": true}, "done": {"view": true}}
      }
    });

    expect(BusinessTab.opening, BusinessTab.statistics);
    expect(SalesTab.opening, SalesTab.process);
  });

  test('a locked initial tab gives way to the first granted one', () {
    PermissionsService().seed({
      "b-1": {
        "business": {"view": true, "branches": {"view": true}},
        "finance": {"view": true, "payments": {"view": true}, "methods": {"view": true}}
      }
    });

    // The employees tab is always granted (the viewer's own profile) and comes first.
    expect(BusinessTab.opening, BusinessTab.employees);
    expect(FinanceTab.opening, FinanceTab.payments);
  });

  test('the employees tab opens without its view: everyone sees their own profile', () {
    PermissionsService().seed({"b-1": {"business": {"view": true}}});

    expect(BusinessTab.employees.granted, isTrue);
    expect(BusinessTab.settings.granted, isFalse);
  });

  test('with no tab granted it is the initial one, which shows the lock', () {
    PermissionsService().seed({"b-1": {"sales": {"view": true}}});

    expect(SalesTab.opening, SalesTab.initial);
  });

  testWidgets('a locked tab is drawn with a lock and still opens', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    FinanceTab? opened;

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: SectionTabs<FinanceTab>(
        tabs: FinanceTab.values,
        active: FinanceTab.overview,
        icon: (tab) => tab.icon,
        title: (_, tab) => tab.key,
        onTab: (tab) => opened = tab,
        isLocked: (tab) => tab == FinanceTab.receivables
      ));
    })));

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(FinanceTab.receivables.icon), findsNothing);
    expect(find.byIcon(FinanceTab.payments.icon), findsOneWidget);

    await tester.tap(find.text("receivables"));
    await tester.pump(const Duration(milliseconds: 500));

    expect(opened, FinanceTab.receivables);
  });
}
