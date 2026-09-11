import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/screens/modals/sales/sale_items/_sale_items.dart';
import 'package:app/screens/modals/sales/sale_items/item_line.dart';

/// **The lines of a sale, in the panel they moved to.**
///
/// They came out of the sale's own panel because a ticket has one line or it
/// has three hundred, and three hundred of them pushed the handover, the holds
/// and where the sale came from past the bottom of a screen that is read top to
/// bottom. So the two things worth pinning are the two that make the move worth
/// anything:
///
/// - **The list is lazy.** A `Column` in a scroll builds all three hundred rows
///   to draw the twelve on screen, and it would do it every time somebody opens
///   a sale. What is asserted is that far fewer rows exist than lines.
/// - **The search finds a line by either of the two things somebody holding the
///   box has**, its name or the code printed on it — and it only appears once
///   there is enough to look through, since on a three-line ticket the box is
///   one more thing to read past to reach the three lines.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('three hundred lines build the ones on screen', (tester) async {
    await _pump(tester, _sale(300));

    final built = tester.widgetList(find.byType(SaleItemLine)).length;

    expect(built, lessThan(40));
    expect(built, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search narrows by name and by code', (tester) async {
    await _pump(tester, _sale(30));

    // The name of one line and the code of another: both are what somebody
    // with the box in their hand actually has.
    await tester.enterText(find.byType(SearchInput), "Producto 7");
    await tester.pump();

    expect(_line("Producto 7"), findsOneWidget);
    expect(_line("Producto 8"), findsNothing);

    await tester.enterText(find.byType(SearchInput), "sku-12");
    await tester.pump();

    expect(_line("Producto 12"), findsOneWidget);
    expect(_line("Producto 7"), findsNothing);

    // A search that matches nothing says so; the sale is not empty and must
    // not read as if it were.
    await tester.enterText(find.byType(SearchInput), "tornillo");
    await tester.pump();

    expect(find.text(S.current.sales_detail_items_no_match), findsOneWidget);
    expect(find.text(S.current.sales_detail_items_empty), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short ticket is not given a search box', (tester) async {
    await _pump(tester, _sale(3));

    expect(find.byType(SearchInput), findsNothing);
    expect(find.byType(SaleItemLine), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

/// A product name **on a line**, and not the same word sitting in the search
/// box: what is being asked is which lines are left, and the query is drawn on
/// screen too.
Finder _line(String name) => find.descendant(
  of: find.byType(SaleItemLine),
  matching: find.text(name)
);

/// The panel at the width and height it opens at: a side modal is as tall as
/// the window, which is what gives the list its bounded height.
Future<void> _pump(WidgetTester tester, SaleDetailModel sale) async {
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

      return Scaffold(body: SizedBox(
        width: 460,
        height: 700,
        child: SaleItemsModal(sale: sale)
      ));
    })
  ));

  await tester.pump();
}

/// A charged ticket with [lines] products on it.
SaleDetailModel _sale(int lines) => SaleDetailModel.fromJson({
  "id": "s1",
  "source": "ticket",
  "ticket": "K7M4-2QX9",
  "status": "completed",
  "currency": "USD",
  "units": lines,
  "payment": const {"method": "cash", "name": "Efectivo", "credit": false},
  "items": [
    for (int i = 0; i < lines; i++)
      {
        "productId": "p$i",
        "sku": "SKU-$i",
        "name": "Producto $i",
        "qty": 1,
        "price": 10,
        "subtotal": 10,
        "total": 10,
        "held": 0
      }
  ]
});
