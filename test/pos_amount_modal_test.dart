import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:core/button.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/pos/pos_amount/_pos_amount.dart';
import 'package:app/screens/modals/pos/pos_tax/_pos_tax.dart';
import 'package:app/services/catalog/currency_model.dart';

/// The two little forms the ticket is edited with, and the one way they broke.
///
/// **Mounting them is half the test.** Their inputs carry error messages read
/// from `S.of(context)`, so building a controller is an inherited lookup: done
/// from `initState` it throws, and the half-built modal then takes the navigator
/// down on the next frame with `_dependents.isEmpty`. Both modals build their
/// controllers from `didChangeDependencies` or later for that reason, and a
/// plain mount is what pins it.
///
/// The other half is what they hand back, which is the only thing the panel
/// reads: a typed price in either notation, and a rate the empty field reports
/// as zero.
final _currency = CurrencyModel.unknown("USD");

Widget _host(Widget modal, void Function(dynamic result) onClosed) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: Builder(builder: (context) => TextButton(
      // The modal is opened through a route and not mounted inline because what
      // it answers travels through `Navigator.pop`, which is what the panel
      // awaits.
      onPressed: () async => onClosed(await showDialog(
        context: context,
        builder: (context) => Dialog(child: SingleChildScrollView(child: modal))
      )),
      child: const Text("open")
    )));
  })
);

/// Opens the modal and leaves the tester on it.
Future<void> _open(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('the amount modal mounts without an inherited lookup too early', (
    tester
  ) async {
    dynamic result;

    await _open(tester, _host(PosAmountModal(currency: _currency), (value) {
      result = value;
    }));

    expect(tester.takeException(), isNull);
    expect(find.byType(PosAmountModal), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('it hands back the concept and the price in either notation', (
    tester
  ) async {
    dynamic result;

    await _open(tester, _host(PosAmountModal(currency: _currency), (value) {
      result = value;
    }));

    await tester.enterText(find.byType(TextField).at(0), "Delivery");
    // The comma is what a counter writing in a currency that groups the other
    // way types. It is the same amount.
    await tester.enterText(find.byType(TextField).at(1), "12,50");

    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();

    expect(result, isA<PosAmountEntry>());
    expect((result as PosAmountEntry).label, "Delivery");
    expect(result.price, 12.5);
  });

  testWidgets('a price that is not a number keeps the modal open', (
    tester
  ) async {
    dynamic result;
    var closed = false;

    await _open(tester, _host(PosAmountModal(currency: _currency), (value) {
      closed = true;
      result = value;
    }));

    await tester.enterText(find.byType(TextField).at(0), "Delivery");
    await tester.enterText(find.byType(TextField).at(1), ",,");

    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();

    // It stays open with what was written, to be corrected or dismissed by
    // hand: closing it would throw the concept away with the typo.
    expect(closed, isFalse);
    expect(result, isNull);
    expect(find.byType(PosAmountModal), findsOneWidget);
  });

  testWidgets('the tax modal mounts and reports an emptied field as zero', (
    tester
  ) async {
    dynamic result;

    await _open(tester, _host(const PosTaxModal(rate: 16), (value) {
      result = value;
    }));

    expect(tester.takeException(), isNull);

    // The rate opens on what is being charged, without the trailing zero
    // nobody says out loud.
    expect(find.text("16"), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, "");

    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();

    // Emptying the box is how a counter stops charging tax, so it is an answer
    // and not the one thing the field cannot say.
    expect(result, 0.0);
  });
}
