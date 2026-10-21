import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

StockSummaryPage _page({required List<Map> columns, required List<String> keys, required List<List> values}) =>
  StockSummaryPage.fromResponse({
    "table": "t1",
    "columns": columns,
    "data": {"keys": keys, "values": values}
  });

void main() {
  test("a product is named by the row's title, not the SKU the summary shows first", () {
    final page = _page(
      columns: [
        {"key": "image", "fixed": true},
        {"key": "sku-col", "name": "SKU", "type": "SKU"},
        {"key": "stock", "fixed": true}
      ],
      keys: ["id", "image", "sku-col", "stock", "unit", "name"],
      values: [["p1", null, "HW-1200", 3, null, "RAM 16 GB"]]
    );

    expect(KitchenProduct.fromSummary(page).single.label, "RAM 16 GB");
  });

  test("without a row title, a title column shown wins over the first text one", () {
    final page = _page(
      columns: [
        {"key": "code", "name": "Code", "type": "TEXT"},
        {"key": "title", "name": "Name", "type": "TITLE"}
      ],
      keys: ["id", "code", "title", "unit"],
      values: [["p1", "A-1", "Gift box", null]]
    );

    expect(KitchenProduct.fromSummary(page).single.label, "Gift box");
  });
}
