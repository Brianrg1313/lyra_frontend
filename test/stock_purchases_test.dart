import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/screens/modals/inventory/stock_movement/_stock_movement.dart';
import 'package:app/screens/modals/inventory/stock_movement/movement_shape.dart';

/// A restock of the kitchen (`cocina-frontend.md` §1, §7–8): a supply's stock carries up to
/// six decimals of its unit, a purchase may count presentations («3 Saco») and say what the
/// whole of it cost, and only a restock carries that cost (`invalid_cost` otherwise).
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  group("figures", () {
    test("a counter keeps a supply's decimals and whole numbers as integers", () {
      expect(stockNum(2.0), isA<int>());
      expect(stockNum("1.75"), 1.75);
      expect(stockNum(null), isNull);
      expect(stockFigure(1.75), "1.75");
      expect(stockFigure(0.033300), "0.0333");
      expect(stockFigure(12), "12");

      final balance = StockBalance.fromResponse({"onHand": 1.75, "reserved": 0, "available": 1.75, "returns": 0});
      expect(balance.available, 1.75);

      const row = StockSummaryRow(id: "wax", values: {"stock": 0.5, "reserved": 0});
      expect(row.stock, 0.5);
      expect(row.withBalance(stock: 2.25, reserved: 0).stock, 2.25);
    });
  });

  group("bodies", () {
    test("a purchase sends its presentation and its cost; a decimal amount as it is", () {
      expect(const StockMovement(
        operation: StockOperation.add,
        quantity: 3,
        reason: StockReason.restock,
        presentation: "sack",
        cost: 90
      ).request(tableId: "s", productId: "flour"), {
        "TABLE_ID": "s", "PRODUCT_ID": "flour", "QUANTITY": 3, "REASON": "restock",
        "PRESENTATION": "sack", "COST": 90
      });

      expect(const StockMovement(operation: StockOperation.remove, quantity: 0.25, reason: StockReason.waste)
        .request(tableId: "s", productId: "wax"),
        {"TABLE_ID": "s", "PRODUCT_ID": "wax", "QUANTITY": 0.25, "REASON": "waste"});
    });

    test("a cost travels only with a restock", () {
      final body = const StockMovement(operation: StockOperation.add, quantity: 1, reason: StockReason.addCorrection, cost: 5)
        .request(tableId: "s", productId: "wax");

      expect(body.containsKey("COST"), isFalse);
    });
  });

  group("the restock form", () {
    Future<void> open(WidgetTester tester, StockSummaryService service, StockDirection direction) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1400);
      addTearDown(tester.view.reset);

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

          return Scaffold(body: StockMovementModal(
            service: service,
            productId: "flour",
            shape: StockMovementShape.of(counter: StockCounter.stock, direction: direction),
            stock: 1.5,
            reserved: 0
          ));
        })
      ));
      await tester.pumpAndSettle();
    }

    testWidgets("a supply's form says its amount with decimals and offers how it is bought", (tester) async {
      final service = StockSummaryService(source: _Source(), supplies: true);
      addTearDown(service.dispose);

      await open(tester, service, StockDirection.put);

      expect(tester.takeException(), isNull);
      expect(find.text("1.5 available"), findsOneWidget);
      expect(find.text("Bought as"), findsOneWidget);
      // The cost waits for the reason: only a purchase carries one.
      expect(find.text("Total cost"), findsNothing);
    });

    testWidgets("a catalog's form counts units and asks for no presentation", (tester) async {
      final service = StockSummaryService(source: _Source(bought: const []));
      addTearDown(service.dispose);

      await open(tester, service, StockDirection.put);

      expect(tester.takeException(), isNull);
      expect(find.text("1 unit available"), findsOneWidget);
      expect(find.text("Bought as"), findsNothing);
    });
  });
}

/// A source with the presentations of a product and nothing else to read.
class _Source implements StockSource {
  _Source({this.bought = const [Presentation(id: "sack", name: "Sack", qty: 25)]});

  final List<Presentation> bought;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Presentation>> presentations(String productId) async => bought;

  @override
  Future<StockSummaryPage> summary({required int page, required int size, String match = "", String tableId = "", StockSummarySort? sort}) =>
    Completer<StockSummaryPage>().future;
}
