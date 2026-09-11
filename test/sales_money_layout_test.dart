import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_money.dart';

/// **The money block is read two figures to a line.**
///
/// Every entry in it is a handful of characters under a two-word label, so in
/// one column three quarters of the panel was blank and the arithmetic of a
/// credit sale ran past the bottom of the screen. What is pinned here is the
/// pairing itself and the one thing that can go wrong with it: the panel is as
/// wide as the window lets it be, so a narrow one has to come back to a single
/// column rather than cut both figures in half — an ellipsis over an amount is
/// a figure nobody can act on.
///
/// The method keeps a line to itself in both, because it is the only entry that
/// is not a figure: the reference hangs under it and is as long as the bank
/// felt like making it.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('at the panel width the figures are paired', (tester) async {
    await _pump(tester, width: 460);

    // The chain a person follows —units, subtotal, tax, total— is four cells
    // read left to right and then down, so each pair shares a line.
    expect(_line(tester, S.current.sales_detail_units),
      _line(tester, S.current.sales_detail_subtotal));
    expect(_line(tester, S.current.sales_detail_tax),
      _line(tester, S.current.sales_detail_total));
    // And so do the two figures that only exist together, which is the pair
    // somebody is comparing rather than reading.
    expect(_line(tester, S.current.sales_detail_collected),
      _line(tester, S.current.sales_detail_outstanding));

    // The subtotal is on a line below the units and not beside them again: a
    // pair is two cells, not a row that keeps filling.
    expect(_line(tester, S.current.sales_detail_tax),
      greaterThan(_line(tester, S.current.sales_detail_units)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the method keeps its own line', (tester) async {
    await _pump(tester, width: 460);

    final method = tester.getRect(find.text(S.current.sales_detail_method));
    final block = tester.getRect(find.byType(SaleDetailMoney));

    // It starts at the left edge like every other entry and nothing shares the
    // line: the entry under it is the collected/owed pair, one line down.
    expect(method.left, lessThan(block.left + block.width / 2));
    expect(_line(tester, S.current.sales_detail_collected),
      greaterThan(_line(tester, S.current.sales_detail_method)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow panel goes back to one column', (tester) async {
    await _pump(tester, width: 200);

    expect(_line(tester, S.current.sales_detail_subtotal),
      greaterThan(_line(tester, S.current.sales_detail_units)));
    expect(_line(tester, S.current.sales_detail_outstanding),
      greaterThan(_line(tester, S.current.sales_detail_collected)));
    expect(tester.takeException(), isNull);
  });
}

/// Where a label sits down the block, which is what says whether two of them
/// share a line.
double _line(WidgetTester tester, String label) =>
  tester.getCenter(find.text(label)).dy;

Future<void> _pump(WidgetTester tester, {required double width}) async {
  final sale = SaleDetailModel.fromJson(_credit);

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
        width: width,
        child: SingleChildScrollView(child: SaleDetailMoney(sale: sale))
      ));
    })
  ));

  await tester.pump();
}

/// A ticket sold on the company's tab: the one sale that draws every entry of
/// the block, the collected/owed pair included.
const Map<String, dynamic> _credit = {
  "id": "s1",
  "source": "ticket",
  "ticket": "K7M4-2QX9",
  "status": "completed",
  "stage": "owed",
  "label": "Credito por cobrar",
  "section": "process",
  "level": "warning",
  "attention": true,
  "channel": "pos",
  "customer": {"name": "Luis", "contact": "584120000000"},
  "seller": {"kind": "user", "name": "Ana"},
  "currency": "USD",
  "units": 3,
  "subtotal": 100,
  "tax": 16,
  "taxes": [
    {"rate": 16, "base": 100, "amount": 16}
  ],
  "total": 116,
  "payment": {
    "method": "account",
    "name": "Credito",
    "reference": "NOTA-77",
    "credit": true,
    "collected": 40,
    "outstanding": 76
  },
  "items": [],
  "closed": "2026-09-08T14:00:00.000Z"
};
