part of '../sheet_controller.dart';

const String _kStockPut = "put";
const String _kStockTake = "take";

/// A record's stock cell: the figure is the inventory engine's, so instead of an editor it
/// unfolds the two movements of the stock summary (put, take) and opens the same form.
extension SheetStockMoves on SheetController {
  /// Whether [cell] moves its product's stock: a `STOCK` column, a record already read with
  /// its id, and a mover the section gave.
  bool movesStock(SheetCell cell) {
    if (stock == null || cell.row == kFieldsRow || cell.row >= service.records) return false;
    if (typeAt(cell.column) != TableFieldType.stock) return false;

    return service.rowAt(cell.row)?.id.isNotEmpty ?? false;
  }

  /// Unfolds put / take anchored to the cell ([anchor] is its context) and opens the
  /// movement form; the row shows the balance it leaves ([TableViewService.writeStock]).
  Future<void> moveStock(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    final mover = stock;
    final record = service.rowAt(cell.row);
    if (mover == null || record == null || anchor == null || !anchor.mounted) return;

    final picked = await showSelectMenu(
      context: anchor,
      options: [
        SelectOption(
          value: _kStockPut,
          placeholder: S.of(anchor).stock_move_add_stock,
          subtitle: S.of(anchor).stock_move_add_hint
        ),
        SelectOption(
          value: _kStockTake,
          placeholder: S.of(anchor).stock_move_take_stock,
          subtitle: S.of(anchor).stock_move_take_hint
        )
      ],
      // Hangs from a cell, which measures one row.
      dense: true
    );

    if (_disposed || picked == null || !anchor.mounted) return;

    final value = record.at(columns.slotAt(cell.column));

    await showStockMovement(
      anchor,
      service: mover,
      productId: record.id,
      counter: StockCounter.stock,
      direction: picked.value == _kStockTake ? StockDirection.take : StockDirection.put,
      stock: value is num ? value : num.tryParse("${value ?? ""}") ?? 0,
      // The sheet does not read what is set aside; it only caps setting units aside, which
      // the backend checks anyway.
      reserved: 0
    );
  }
}
