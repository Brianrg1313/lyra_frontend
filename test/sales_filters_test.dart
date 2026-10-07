import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';
import 'package:app/screens/home/sections/sales/sales_filters/_sales_filters.dart';

/// **The bar above the board is one row**, and that is the thing about it that
/// can break without anybody noticing: the count is the backend's sentence and
/// the controls wear the backend's words —a state's name, a channel's— so a
/// long one in a narrow window pushes the whole bar off the right edge.
///
/// The states are a dropdown rather than a strip of chips, which puts one more
/// rule in reach of a test: **a tab must not be able to filter itself down to a
/// state that belongs to the other one**. The list is
/// `SalesCatalogService.of(section)` and never every stage there is.
///
/// The bar also carries the caption for the **header's** search, which is the
/// one thing on this screen that narrows the rows already read instead of the
/// query: `GET /sales` takes no search. A board that filtered silently would
/// answer "no such sale" for a sale that is simply on the next page.
///
/// The service is seeded and the catalog is a stand-in: asking either would be
/// hitting the backend, and **no test may hit the network**.
class _Catalog extends SalesCatalogService {
  _Catalog(this._stages);

  final List<SaleStage> _stages;

  @override
  SalesCatalogStatus get status => SalesCatalogStatus.ready;

  @override
  List<SaleStage> get stages => _stages;

  @override
  Future<void> load({bool force = false}) async {}
}

const _stages = [
  SaleStage(
    stage: "uncharged",
    name: "Sin cobrar",
    section: SaleSection.process,
    level: SaleLevel.warning,
    attention: true
  ),
  SaleStage(
    stage: "shipping",
    name: "En camino",
    section: SaleSection.process
  ),
  SaleStage(
    stage: "delivered",
    name: "Entregada y cobrada",
    section: SaleSection.done,
    level: SaleLevel.success
  )
];

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('the count and the controls share one row', (tester) async {
    final service = SalesService()..seed(const [], total: 42);

    await _pump(tester, service);

    // The count on the left, and every control to the right of it: what the
    // list is showing and what narrows it, read left to right.
    expect(find.text(S.current.sales_count(42)), findsOneWidget);
    expect(find.text(S.current.sales_all_stages), findsOneWidget);
    expect(find.text(S.current.sales_channel), findsOneWidget);
    expect(find.text(S.current.sales_mine), findsOneWidget);
    expect(tester.takeException(), isNull);

    service.dispose();
  });

  testWidgets('a narrow window does not push the bar off its right edge',
    (tester) async {
      // The labels are the backend's, so the bar has to survive a long one in
      // a window that is not a desktop's.
      final service = SalesService()
        ..seed(const [], total: 9999, stage: "uncharged");

      await _pump(tester, service, width: 360);

      expect(tester.takeException(), isNull);

      service.dispose();
    }
  );

  testWidgets('the state control says which state is on', (tester) async {
    final service = SalesService()..seed(const [], stage: "shipping");

    await _pump(tester, service);

    // Closed, the dropdown is the answer and not the question: it carries the
    // chosen state's own name, which is what a strip of chips said with a fill.
    expect(find.text("En camino"), findsOneWidget);
    expect(find.text(S.current.sales_all_stages), findsNothing);
    // Something narrows the list, so it can be cleared.
    expect(find.text(S.current.sales_clear), findsOneWidget);

    service.dispose();
  });

  testWidgets('a tab only offers the states of its own section',
    (tester) async {
      final service = SalesService()..seed(const [], section: SaleSection.process);

      await _pump(tester, service);
      await tester.tap(find.text(S.current.sales_all_stages));
      await tester.pumpAndSettle();

      expect(find.text("Sin cobrar"), findsOneWidget);
      expect(find.text("En camino"), findsOneWidget);
      // It belongs to `done`. Offering it here would let the open tab ask the
      // backend for a contradiction, which it resolves in favour of the stage —
      // quietly reopening the tab that was just left.
      expect(find.text("Entregada y cobrada"), findsNothing);

      service.dispose();
    }
  );

  testWidgets('the bar says what the header search reaches', (tester) async {
    final service = SalesService()..seed(const [], total: 42);
    final home = HomeService();

    await _pump(tester, service, home: home);

    // Nothing typed: the caption is about a search in progress and not a
    // standing note about the screen.
    expect(find.text(S.current.sales_search_scope), findsNothing);

    home.search("A-1024");
    await tester.pump();

    expect(find.text(S.current.sales_search_scope), findsOneWidget);

    home.clearSearch();
    await tester.pump();

    expect(find.text(S.current.sales_search_scope), findsNothing);

    home.dispose();
    service.dispose();
  });
}

Future<void> _pump(
  WidgetTester tester,
  SalesService service, {
  double width = 900,
  HomeService? home
}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<SalesService>.value(value: service),
        ChangeNotifierProvider<SalesCatalogService>.value(
          value: _Catalog(_stages)
        ),
        // The search lives in the home's header, above every section. Reading
        // it is what the caption is for; the box itself is not mounted here.
        ChangeNotifierProvider<HomeService>.value(value: home ?? HomeService())
      ],
      child: Builder(builder: (context) {
        AppSize.instance(context);

        return Scaffold(body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: const SalesFilters())
        ));
      })
    )
  ));

  await tester.pump();
}
