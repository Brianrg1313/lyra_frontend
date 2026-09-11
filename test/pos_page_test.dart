import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/pos/_pos.dart';
import 'package:app/screens/pos/desktop/_body.dart';
import 'package:app/screens/pos/desktop/left_panel.dart';
import 'package:app/screens/pos/desktop/admin_card.dart';
import 'package:app/screens/pos/desktop/center_panel.dart';
import 'package:app/screens/pos/desktop/right_panel.dart';
import 'package:app/screens/pos/desktop/category_bar.dart';
import 'package:app/screens/pos/desktop/catalog.dart';
import 'package:app/screens/pos/desktop/ticket_footer.dart';
import 'package:app/screens/pos/desktop/ticket_header.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/client/client_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_methods_service.dart';
import 'package:app/services/pos/pos_service.dart';
import 'package:app/toolkit/settings/routes.dart';

/// [Surface] is abstract and what stays in the tree is the private
/// implementation of its factory, so `find.byType` —which compares the exact
/// type— does not find it. It is looked up by subtype.
final _surfaces = find.byWidgetPredicate((widget) => widget is Surface);

/// How many surfaces frame [scope], not counting the ones its content draws:
/// the badges of the cashier's card and the catalog's tiles are surfaces too,
/// and adding them up would measure what each panel draws inside instead of how
/// the screen is divided.
int _frames([Finder? scope]) {
  final all = scope == null
    ? _surfaces
    : find.descendant(of: scope, matching: _surfaces);

  final content = <Finder>[
    find.descendant(of: find.byType(PosAdminCard), matching: _surfaces),
    find.descendant(of: find.byType(PosCatalog), matching: _surfaces),
    find.descendant(of: find.byType(PosTicketHeader), matching: _surfaces),
    find.descendant(of: find.byType(PosTicketFooter), matching: _surfaces)
  ].expand((finder) => finder.evaluate()).toSet();

  return all.evaluate().where((element) => !content.contains(element)).length;
}

/// A desktop window, which is the only place this screen exists.
///
/// The default test surface (800x600) is not a size the counter can be drawn
/// at: the two sides are fixed at 300 and 340, so the middle panel —the one
/// that holds the catalog— would be left with barely a hundred pixels, less
/// than a single product tile. It is set here and not once in `setUpAll`
/// because the view belongs to the tester.
void _desktop(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.reset);
}

/// The counter shows who is attending it, so the page does not mount without a
/// session: the admin card reads [ClientService] and it lives above the whole
/// app, not inside the POS.
ClientService _client() => ClientService()..update(const ClientModel(
  name: "Ada",
  lastName: "Lovelace",
  username: "ada",
  email: "ada@lyra.test"
));

/// The counter also writes amounts —the ticket's totals and the catalog's
/// prices— and those are written in the currency the **company** charges with,
/// which is two app-wide services and not one (see `posCurrency`). They are
/// mounted empty on purpose: with no active business the code is empty and the
/// catalog answers with the fallback currency, which is exactly the state a
/// counter opened before `/init` resolved would paint in.
Widget _app() => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<ClientService>.value(value: _client()),
      ChangeNotifierProvider<BusinessService>(create: (_) => BusinessService()),
      ChangeNotifierProvider<CurrencyCatalogService>.value(
        value: CurrencyCatalogService()
      )
    ],
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return const Scaffold(body: PosBody());
    })
  )
);

/// The ticket on its own, at the width the counter gives it
/// ([PosBody.rightWidth]).
///
/// The panel is mounted apart from the page because [PosBody] builds its own
/// [PosInvoiceService] and nothing on this screen can fill one in a test: the
/// ticket is an invoice the backend holds, and the products come from the
/// network. Seeding it here is what lets the rows be looked at at all.
Widget _ticket(PosInvoiceService cart) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<PosInvoiceService>.value(value: cart),
      ChangeNotifierProvider<PosMethodsService>(create: (_) => PosMethodsService()),
      ChangeNotifierProvider<PosService>(create: (_) => PosService()),
      ChangeNotifierProvider<BusinessService>(create: (_) => BusinessService()),
      ChangeNotifierProvider<CurrencyCatalogService>.value(
        value: CurrencyCatalogService()
      )
    ],
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return const Scaffold(body: SizedBox(
        width: PosBody.rightWidth,
        height: 900,
        child: PosRightPanel()
      ));
    })
  )
);

/// The strip on its own, which is how the case with categories is reached: the
/// panel takes them from [PosService] and the page loads that from the network.
Widget _bar({
  required List<String> categories,
  String? selected,
  void Function(String? category)? onCategory
}) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: PosCategoryBar(
      categories: categories,
      selected: selected,
      onCategory: onCategory ?? (_) {}
    ));
  })
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    Navis.defineRoutes(routes);
  });

  test('the POS is a standalone screen, not a home section', () {
    final match = Navis().match(Pos.path);

    expect(match, isNotNull, reason: "${Pos.path} does not resolve");
    expect(match!.route.key, Pos.routeKey);

    // No shell and no parents: it does not reuse the home page nor hang off any
    // of its sections. That is what makes it a page and not one more section.
    expect(match.route.shell, isNull);
    expect(match.route.parents, isEmpty);
  });

  test('no home section is marked while in the POS', () {
    // The side bar is not on screen inside the POS, but if it were no option
    // should stay lit: the POS does not live inside any section.
    final marked = HomeSection.values
      .where((section) => section.isCurrent(Pos.routeKey))
      .toList();

    expect(marked, isEmpty);
    expect(HomeSection.byKey(Pos.routeKey), isNull);
  });

  test('entering the POS stacks a page over the home', () {
    Navis.navigate(HomeSection.dashboard.path);
    final length = Navis().history.length;

    Navis.navigate(Pos.path);

    // The sections share a single page; the POS does not, so the home stays
    // underneath just as it was and going back finds it where it was left.
    expect(Navis().history.length, length + 1);
    expect(Navis.currentKey.value, Pos.routeKey);
  });

  testWidgets('the counter is three panels and the left one is split', (
    tester
  ) async {
    _desktop(tester);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byType(PosLeftPanel), findsOneWidget);
    expect(find.byType(PosCenterPanel), findsOneWidget);
    expect(find.byType(PosRightPanel), findsOneWidget);

    // Two surfaces on the left, one in each of the other two. The centre is
    // split too, but its top half only exists if there are categories and
    // without a network there are none.
    expect(_frames(find.byType(PosLeftPanel)), 2);
    expect(_frames(), 4);
  });

  testWidgets('with no categories the catalog keeps the whole centre', (
    tester
  ) async {
    _desktop(tester);

    await tester.pumpWidget(_app());
    await tester.pump();

    // A single surface in the centre —the catalog's— and no strip: a bar with
    // nothing to pick would eat the height the products are worth.
    expect(_frames(find.byType(PosCenterPanel)), 1);
    expect(find.byType(PosCategoryBar), findsNothing);
    expect(find.byType(PosCatalog), findsOneWidget);

    final center = tester.getSize(find.byType(PosCenterPanel));
    final catalog = tester.getSize(find.byType(PosCatalog));

    expect(catalog.height, center.height);
  });

  testWidgets('the strip draws "all" plus one chip per category', (
    tester
  ) async {
    _desktop(tester);

    await tester.pumpWidget(_bar(categories: const ["Shoes", "Trainers"]));
    await tester.pump();

    expect(find.text("Shoes"), findsOneWidget);
    expect(find.text("Trainers"), findsOneWidget);

    // The first one is not a category: it is how the filter is undone. Without
    // it, once one is picked there would be no way back to the whole catalog.
    expect(find.byType(FeedbackButton), findsNWidgets(3));
  });

  testWidgets('the strip is two rows that grow sideways', (tester) async {
    _desktop(tester);

    await tester.pumpWidget(_bar(
      categories: const ["Shoes", "Trainers", "Boots", "Sandals"]
    ));
    await tester.pump();

    final chips = find.byType(FeedbackButton);
    final first = tester.getTopLeft(chips.at(0));
    final second = tester.getTopLeft(chips.at(1));
    final third = tester.getTopLeft(chips.at(2));

    // The chips fill the column top to bottom and only then open the next one:
    // that is what separates a horizontal grid from a row.
    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
    expect(third.dx, greaterThan(first.dx));
    expect(third.dy, first.dy);

    // The height is set by the strip and not by the chips: it sits above the
    // products, so the overflow goes into the scroll and not into more rows.
    expect(
      tester.getSize(find.byType(PosCategoryBar)).height,
      PosCategoryBar.height
    );
  });

  testWidgets('picking a chip reports it, and "all" reports null', (
    tester
  ) async {
    _desktop(tester);

    final picked = <String?>[];

    await tester.pumpWidget(_bar(
      categories: const ["Shoes"],
      selected: "Shoes",
      onCategory: picked.add
    ));
    await tester.pump();

    await tester.tap(find.text("Shoes"));
    await tester.pump();

    expect(picked, ["Shoes"]);

    await tester.tap(find.byType(FeedbackButton).first);
    await tester.pump();

    expect(picked, ["Shoes", null]);
  });

  testWidgets('the sides measure their own and the centre keeps the rest', (
    tester
  ) async {
    _desktop(tester);

    await tester.pumpWidget(_app());
    await tester.pump();

    final left = tester.getSize(find.byType(PosLeftPanel));
    final right = tester.getSize(find.byType(PosRightPanel));
    final center = tester.getSize(find.byType(PosCenterPanel));

    expect(left.width, PosBody.leftWidth);
    expect(right.width, PosBody.rightWidth);
    expect(center.width, greaterThan(0));

    // The three reach the same height: the counter has no bar on top.
    expect(center.height, left.height);
    expect(center.height, right.height);
  });

  testWidgets('the two halves of the left panel share the height', (
    tester
  ) async {
    _desktop(tester);

    await tester.pumpWidget(_app());
    await tester.pump();

    // The two framing ones, in order: first the top one and then the card. The
    // card's badges come behind and are not looked at here.
    final halves = find.descendant(
      of: find.byType(PosLeftPanel),
      matching: _surfaces
    );

    final panel = tester.getSize(find.byType(PosLeftPanel));
    final top = tester.getSize(halves.at(0));
    final bottom = tester.getSize(halves.at(1));

    // The bottom one measures what its content needs and the top one keeps the
    // rest: stretching the card would leave empty air below that data.
    expect(bottom.height, lessThan(panel.height));
    expect(top.height + AppSize.gap + bottom.height, panel.height);
    expect(top.width, PosBody.leftWidth);
  });

  testWidgets('a full ticket fits its panel and keeps the total in place', (
    tester
  ) async {
    _desktop(tester);

    final cart = PosInvoiceService();

    // The invoice as the backend would have answered it: every line already
    // priced, taxed and given its own id. Tapping the tiles instead would open
    // a document and hold units, which is a round trip a test may not make.
    cart.seed(PosInvoice(
      id: "invoice-1",
      ticket: "K7M4-2QX9",
      isOpen: true,
      items: [
        for (var index = 0; index < 12; index++)
          PosInvoiceLine(
            lineId: "line-$index",
            productId: "product-$index",
            // Long enough to be cut: a name is what a line is looked up by, so
            // it has to ellipsise instead of pushing the amount off the panel.
            name: "Espresso machine, professional, $index",
            quantity: 1,
            held: 1,
            price: 12345.67,
            taxRate: 16
          ),
        const PosInvoiceLine(
          lineId: "line-delivery",
          name: "Delivery",
          quantity: 1,
          price: 40,
          taxRate: 16
        )
      ]
    ));

    await tester.pumpWidget(_ticket(cart));
    await tester.pump();

    // A line that did not fit is a `RenderFlex overflowed` error, which the
    // tester keeps instead of drawing the yellow bars. This is the assertion
    // the panel is narrow for.
    expect(tester.takeException(), isNull);

    expect(find.byType(PosTicketHeader), findsOneWidget);
    expect(find.byType(PosTicketFooter), findsOneWidget);

    final panel = tester.getRect(find.byType(PosRightPanel));
    final footer = tester.getRect(find.byType(PosTicketFooter));

    // The lines take whatever is left and the foot stays at the bottom: the
    // total must not walk down the panel as products are added, because it is
    // the number being watched while they are.
    expect(footer.bottom, closeTo(panel.bottom - AppSize.padding, 0.01));
    expect(footer.width, closeTo(panel.width - AppSize.padding * 2, 0.01));
  });
}
