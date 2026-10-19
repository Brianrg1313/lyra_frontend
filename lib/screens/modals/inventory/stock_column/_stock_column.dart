import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Asks before a column becomes the table's stock, from the sheet's type menu or the table's
/// settings: a stock is the inventory's count (`Inventory.#settle` mirrors it into the column),
/// so the figures typed in it until now are no stock at all — the first movement of each
/// product replaces its figure with what the ledger has. A supplies table filled with typed
/// quantities read 0 everywhere a recipe measured it, and nothing said why.
///
/// Only asked while the table has rows ([records] > 0, or unknown): an empty one has no
/// figure to lose.
Future<bool> confirmStockColumn(BuildContext context, {int? records}) async {
  if (records == 0) return true;

  return showAlertModal(
    context: context,
    title: S.of(context).product_table_view_stock_convert_title,
    message: S.of(context).product_table_view_stock_convert_message,
    confirmText: S.of(context).product_table_view_stock_convert_confirm,
    cancelText: S.of(context).cancel
  );
}
