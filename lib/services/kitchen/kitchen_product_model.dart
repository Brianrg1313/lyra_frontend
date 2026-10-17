import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/kitchen/kitchen_read.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

/// A product as the supply chain lists and picks it: a row of a table's stock summary
/// (`POST /inventory/stock/summary/`), named by its first text column.
///
/// The backend gives no unit for a product (`cocina-frontend.md` §8: a supplies table does not
/// always have a unit column), so [unit] is the table's when it says one: a measure column's
/// magnitude, or a column called "unit" holding it per row. Empty otherwise.
@immutable
class KitchenProduct {
  const KitchenProduct({
    required this.id,
    required this.tableId,
    this.name = "",
    this.unit = "",
    this.stock,
    this.supplies = false,
    this.made = false
  });

  final String id;
  final String tableId;
  final String name;
  final String unit;

  /// What the branch has of it, decimals and all on a supply. `null` when the summary did not
  /// count it.
  final double? stock;

  /// A row of a supplies table: never sold, counted with decimals.
  final bool supplies;

  /// A row of a made table: its recipe is part of the record (written with it, never removed),
  /// counted in whole units.
  final bool made;

  /// What a list writes for it: its name, or its id when it has none.
  String get label => name.isEmpty ? id : name;

  /// The rows of a summary [page], named by its first text column.
  static List<KitchenProduct> fromSummary(StockSummaryPage page, {bool supplies = false, bool made = false}) {
    final columns = page.columns;
    final name = columns.where((column) => !column.isImage && !column.isNumber && !column.type.united).firstOrNull;
    final measure = columns.where((column) => column.type == TableFieldType.measure && column.unit.isNotEmpty).firstOrNull;
    final unitColumn = columns.where((column) => _unitNames.contains(column.name.trim().toLowerCase())).firstOrNull;

    return [
      for (final row in page.rows) KitchenProduct(
        id: row.id,
        tableId: page.table,
        name: name == null ? "" : kitchenText(row.values[name.key]),
        unit: unitColumn != null && kitchenText(row.values[unitColumn.key]).isNotEmpty
          ? kitchenText(row.values[unitColumn.key])
          : measure?.unit ?? "",
        stock: kitchenNum(row.values[StockSummaryColumn.stockKey]),
        supplies: supplies,
        made: made
      )
    ];
  }

  static const Set<String> _unitNames = {"unit", "units", "unidad", "unidades", "uom", "medida"};

  @override
  bool operator ==(Object other) => other is KitchenProduct && other.id == id && other.tableId == tableId;

  @override
  int get hashCode => Object.hash(id, tableId);
}
