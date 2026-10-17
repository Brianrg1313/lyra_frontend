import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/movements/stock_history_service.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/screens/modals/inventory/stock_history/_stock_history.dart';

/// A product's movements read back (`cocina-frontend.md` §10): a line says which way it went
/// by its operation and reason, the dish a supply was spent for (named from the catalog), how a
/// restock was bought and what it cost, and the panel pages the ledger.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  final spent = {
    "id": "m1", "operation": "recipe", "reason": "consumption", "qty": 0.4,
    "actor": {"kind": "user", "name": "Ana"}, "for": {"productId": "burger", "qty": 2, "recipeVersion": 3},
    "balance": {"onHand": 1.6, "reserved": 0, "available": 1.6, "returns": 0}, "date": "2026-10-16T18:00:00.000Z"
  };

  final bought = {
    "id": "m2", "operation": "add", "reason": "restock", "qty": 75, "actor": {"kind": "user", "name": null},
    "pack": {"id": "sack", "name": "Sack", "qty": 25, "count": 3}, "cost": 90, "note": "Tuesday's order"
  };

  test("a line reads what it moved for, how it was bought and which way it went", () {
    final line = StockLedgerEntry.fromJson(spent);

    expect(line.madeFor!.productId, "burger");
    expect(line.madeFor!.qty, 2);
    expect(line.available, 1.6);
    expect(line.sign, -1);

    final restock = StockLedgerEntry.fromJson(bought);
    expect(restock.pack!.count, 3);
    expect(restock.cost, 90);
    expect(restock.sign, 1);

    expect(StockLedgerEntry.fromJson({"operation": "recipe", "reason": "waste", "qty": 1}).sign, 0);
    expect(StockLedgerEntry.fromJson({"operation": "reserve", "reason": "hold", "qty": 1}).sign, 0);
    expect(StockLedgerEntry.fromJson({"operation": "transfer", "reason": "transfer_out", "qty": -2}).qty, 2);
  });

  test("the panel pages the ledger and names the dishes from the catalog tables", () async {
    final stock = _Stock([spent, bought, spent]);
    final service = StockHistoryService(productId: "bacon", stock: stock, inventory: _Inventory());
    addTearDown(service.dispose);

    await service.load();

    expect(service.status, StockHistoryStatus.ready);
    expect(service.entries, hasLength(2));
    expect(service.hasMore, isTrue);
    expect(service.dish("burger"), "Classic burger");
    expect(stock.summarized, ["menu"]);

    await service.more();
    expect(service.entries, hasLength(3));
    expect(service.hasMore, isFalse);
  });

  test("a product nothing moved is empty; a failed read is an error", () async {
    final empty = StockHistoryService(productId: "x", stock: _Stock(const []), inventory: _Inventory());
    addTearDown(empty.dispose);
    await empty.load();
    expect(empty.status, StockHistoryStatus.empty);

    final failed = StockHistoryService(productId: "x", stock: _Stock(const [], fail: true), inventory: _Inventory());
    addTearDown(failed.dispose);
    await failed.load();
    expect(failed.status, StockHistoryStatus.error);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 900);
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
      home: Builder(builder: (context) {
        AppSize.instance(context);
        return Scaffold(body: Center(child: SizedBox(width: 440, child: child)));
      })
    ));
    await tester.pumpAndSettle();
  }

  testWidgets("a supply spent on a dish says it, with who and what was left", (tester) async {
    await pump(tester, StockLedgerLine(entry: StockLedgerEntry.fromJson(spent), dish: "Classic burger", currency: _currency));

    expect(tester.takeException(), isNull);
    expect(find.text("Used in a sale · for 2 × Classic burger"), findsOneWidget);
    expect(find.text("−0.4"), findsOneWidget);
    expect(find.textContaining("Ana"), findsOneWidget);
    expect(find.textContaining("1.6 left"), findsOneWidget);
  });

  testWidgets("a restock says how it was bought and what it cost", (tester) async {
    await pump(tester, StockLedgerLine(entry: StockLedgerEntry.fromJson(bought), dish: "", currency: _currency));

    expect(tester.takeException(), isNull);
    expect(find.textContaining("Restock · 3 × Sack · "), findsOneWidget);
    expect(find.textContaining("90.00"), findsOneWidget);
    expect(find.text("+75"), findsOneWidget);
    expect(find.textContaining("An account that no longer exists"), findsOneWidget);
    expect(find.text("«Tuesday's order»"), findsOneWidget);
  });

  testWidgets("a reason is named with its operation", (tester) async {
    late BuildContext context;
    await pump(tester, Builder(builder: (inner) {
      context = inner;
      return const SizedBox();
    }));

    expect(stockLedgerReason(context, "remove", "waste"), "Waste");
    expect(stockLedgerReason(context, "recipe", "waste"), "Lost from the batch");
    expect(stockLedgerReason(context, "recipe", "spoiled"), "Dish lost");
    expect(stockLedgerReason(context, "later", "unknown"), "unknown");
  });
}

const _currency = CurrencyModel(code: "USD", name: "Dollar", symbol: "\$");

/// A ledger of [lines] in pages of two, and a catalog table naming the burger.
class _Stock implements StockSource {
  _Stock(this.lines, {this.fail = false});

  final List<Map<String, dynamic>> lines;
  final bool fail;
  final summarized = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<StockLedgerPage> movements({required String productId, required int page, required int size}) async {
    if (fail) throw {"message": "offline"};

    return StockLedgerPage.fromJson({
      "total": lines.length,
      "movements": lines.skip((page - 1) * 2).take(2).toList()
    });
  }

  @override
  Future<StockSummaryPage> summary({required int page, required int size, String match = "", String tableId = "", StockSummarySort? sort}) async {
    summarized.add(tableId);

    return StockSummaryPage(
      table: tableId,
      columns: const [StockSummaryColumn(key: "name", name: "Name")],
      rows: const [StockSummaryRow(id: "burger", values: {"name": "Classic burger"})]
    );
  }
}

class _Inventory implements InventorySource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<TableLiteModel>> tables() async => const [
    TableLiteModel(id: "menu", title: "Menu"),
    TableLiteModel(id: "pantry", title: "Pantry", kind: TableKind.supplies)
  ];
}
