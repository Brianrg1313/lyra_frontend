/// A figure follows its unit only between units of one magnitude, and a conversion asked
/// travels as `CONVERT` and comes back in the ledger as one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/inventory/measure_units.dart';
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/kitchen/kitchen_units.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/screens/modals/inventory/unit_change/_unit_change.dart';

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  /// Opens the question for 30 kg going to grams and answers it with [answer] (null: cancel).
  Future<UnitChange?> ask(WidgetTester tester, UnitChange? answer) async {
    late BuildContext context;

    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(builder: (built) {
        AppSize.instance(built);
        context = built;
        return const SizedBox.shrink();
      })
    ));

    final asked = askUnitChange(context, from: "kg", to: "g", factor: 1000, figure: 30, note: "note");
    await tester.pumpAndSettle();

    expect(find.text(S.current.unit_change_convert_detail("30 kg", "30000 g")), findsOneWidget);
    expect(find.text(S.current.unit_change_keep_detail("30 kg", "30 g")), findsOneWidget);

    if (answer != null) {
      await tester.tap(find.text(answer == UnitChange.convert ? S.current.unit_change_convert : S.current.unit_change_keep));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text(answer == null ? S.current.cancel : S.current.unit_change_confirm));
    await tester.pumpAndSettle();

    return asked;
  }

  group("question", () {
    testWidgets("converting comes chosen, and keeping is one tap away", (tester) async {
      expect(await ask(tester, UnitChange.convert), UnitChange.convert);
      expect(await ask(tester, UnitChange.keep), UnitChange.keep);
    });

    testWidgets("cancelled, nothing changes", (tester) async {
      expect(await ask(tester, null), isNull);
    });
  });

  group("factor", () {
    test("units of one magnitude convert, however they are written", () {
      expect(measureFactor("kg", "g"), 1000);
      expect(measureFactor("gramos", "Kilos"), 0.001);
      expect(measureFactor("l", "ml"), 1000);
      expect(measureFactor("lb", "kg"), closeTo(0.45359237, 1e-12));
    });

    test("units are no number of litres, and an unknown word converts to nothing", () {
      expect(measureFactor("", "l"), isNull);
      expect(measureFactor("u", "kg"), isNull);
      expect(measureFactor("caja", "kg"), isNull);
      expect(measureFactor("kg", "m"), isNull);
    });

    test("the same unit written two ways is no conversion", () {
      expect(measureFactor("u", ""), 1);
      expect(measureFactor("lt", "l"), 1);
      expect(measureFactor("Caja", "caja"), 1);
    });

    test("a converted figure carries no float noise", () {
      expect(measureConvert(0.3, 1000), 300);
      expect(measureConvert(450, 0.001), 0.45);
      expect(measureConvert(30, 1000), 30000);
    });
  });

  group("request", () {
    test("a conversion travels only beside the unit it converts to", () {
      expect(editFieldRequest(id: "f", name: "Weight", unit: "g", convert: true)["CONVERT"], isTrue);
      expect(editFieldRequest(id: "f", name: "Weight", unit: "g").containsKey("CONVERT"), isFalse);
      expect(editFieldRequest(id: "f", name: "Weight", convert: true).containsKey("CONVERT"), isFalse);
    });
  });

  group("ledger", () {
    test("a conversion says from which unit to which, and which way the figure went", () {
      final up = StockLedgerEntry.fromJson({
        "operation": "unit", "reason": "conversion", "qty": 29970,
        "unit": {"from": "kg", "to": "g", "factor": 1000}
      });

      expect(up.unit, (from: "kg", to: "g", factor: 1000));
      expect(up.sign, 1);

      final down = StockLedgerEntry.fromJson({
        "operation": "unit", "reason": "conversion", "qty": 29.97,
        "unit": {"from": "g", "to": "kg", "factor": 0.001}
      });

      expect(down.sign, -1);
      expect(StockLedgerEntry.fromJson({"operation": "add", "reason": "restock", "qty": 1}).unit, isNull);
    });
  });

  group("recipe", () {
    test("an ingredient is written in any unit of its magnitude", () {
      final pepsi = kitchenUnitsFor("l");

      expect([for (final unit in pepsi) unit.symbol], ["ml", "l", "gal"]);
      expect(450 * pepsi.first.factor, closeTo(0.45, 1e-12));
      expect([for (final unit in kitchenUnitsFor("cm")) unit.symbol], ["mm", "cm", "m", "km", "in", "ft"]);
    });
  });
}
