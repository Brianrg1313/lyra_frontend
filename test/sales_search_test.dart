import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';
import 'package:app/screens/home/sections/sales/sales_board.dart';

/// **The board answers the home's search box**, which is the only search this
/// screen has: there is one in the header, it searches the section being looked
/// at, and until now the sales were the section that ignored it.
///
/// It matches the three things somebody has in hand when they are looking for
/// one sale — the ticket code off a printed slip, the customer's name, and who
/// sold it — and nothing else: matching a stage or a channel would answer a
/// question the two controls above the board already answer, and better.
///
/// It narrows the rows that were read and does not travel: `GET /sales` takes
/// no search. That is why a query that matches nothing says so in its own words
/// instead of drawing the section's empty state, which would claim the company
/// has no such sale when it may only be on the next page.
class _Catalog extends SalesCatalogService {
  @override
  SalesCatalogStatus get status => SalesCatalogStatus.ready;

  @override
  Future<void> load({bool force = false}) async {}
}

const _sales = [
  SaleModel(
    id: "1",
    source: SaleSource.ticket,
    ticket: "K7M4-2QX9",
    number: "A-000123",
    customer: "Ana Perez",
    seller: "Luis Gomez"
  ),
  SaleModel(
    id: "2",
    source: SaleSource.ticket,
    ticket: "B2C3-9ZZ1",
    customer: "Carlos Ruiz",
    seller: "Marta Diaz"
  ),
  // A conversation: no code and no seller, so the customer is the only thing
  // it can be found by.
  SaleModel(id: "3", customer: "Ana Maria Soto")
];

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('a ticket code finds the one sale it names', (tester) async {
    final home = HomeService();
    final service = SalesService()..seed(_sales);

    await _pump(tester, service, home);

    // Lowercased on the way in, like everything the header hands over: the code
    // on the slip is upper case and nobody types it that way.
    home.search("k7m4");
    await tester.pump();

    expect(find.text("Ana Perez"), findsOneWidget);
    expect(find.text("Carlos Ruiz"), findsNothing);
    expect(find.text("Ana Maria Soto"), findsNothing);

    await _dispose(tester, service, home);
  });

  testWidgets("the branch's internal number finds its sale too", (tester) async {
    final home = HomeService();
    final service = SalesService()..seed(_sales);

    await _pump(tester, service, home);

    home.search("a-000123");
    await tester.pump();

    expect(find.text("Ana Perez"), findsOneWidget);
    expect(find.text("Carlos Ruiz"), findsNothing);

    await _dispose(tester, service, home);
  });

  testWidgets('a name finds the customer and the seller', (tester) async {
    final home = HomeService();
    final service = SalesService()..seed(_sales);

    await _pump(tester, service, home);

    // The seller, which is the question somebody asks about their own morning.
    home.search("marta");
    await tester.pump();

    expect(find.text("Carlos Ruiz"), findsOneWidget);
    expect(find.text("Ana Perez"), findsNothing);

    // And a customer that two sales share, one of them a conversation with no
    // code and no seller to be found by.
    home.search("ana");
    await tester.pump();

    expect(find.text("Ana Perez"), findsOneWidget);
    expect(find.text("Ana Maria Soto"), findsOneWidget);
    expect(find.text("Carlos Ruiz"), findsNothing);

    await _dispose(tester, service, home);
  });

  testWidgets('a search that matches nothing is not an empty section',
    (tester) async {
      final home = HomeService();
      final service = SalesService()..seed(_sales);

      await _pump(tester, service, home);

      home.search("no-such-sale");
      await tester.pump();

      // Its own news: the rows are there and the search is hiding them, and the
      // sale may be further down a list that is read a page at a time.
      expect(find.text(S.current.sales_search_empty_title), findsOneWidget);
      expect(find.text(S.current.sales_empty_process_title), findsNothing);

      // And it goes away with the text: the board is not left filtered.
      home.clearSearch();
      await tester.pump();

      expect(find.text("Carlos Ruiz"), findsOneWidget);

      await _dispose(tester, service, home);
    }
  );
}

Future<void> _pump(
  WidgetTester tester,
  SalesService service,
  HomeService home
) async {
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
        ChangeNotifierProvider<SalesCatalogService>.value(value: _Catalog()),
        ChangeNotifierProvider<HomeService>.value(value: home)
      ],
      child: Builder(builder: (context) {
        AppSize.instance(context);

        return const Scaffold(body: Center(child: SizedBox(
          width: 900,
          height: 600,
          child: SalesBoard(section: SaleSection.process)
        )));
      })
    )
  ));

  // The board asks for its list and its vocabulary on the first frame. The
  // service is already seeded on the section it opens, so neither read leaves
  // for the network.
  await tester.pump();
}

/// Takes the board down before the test ends: it keeps a one-minute clock, and
/// a timer that outlives the tree is what the framework reports as a leak.
Future<void> _dispose(
  WidgetTester tester,
  SalesService service,
  HomeService home
) async {
  await tester.pumpWidget(const SizedBox.shrink());

  service.dispose();
  home.dispose();
}
