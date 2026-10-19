part of '../sheet_controller.dart';

/// A record's stock cell: the figure is the inventory engine's, so what is typed in it goes
/// out as a correction that leaves the product at that figure, never as the cell; its − and
/// + open the movement form, where a movement carries its reason.
extension SheetStockMoves on SheetController {
  /// Whether [cell] moves its product's stock: a `STOCK` column, a record already read with
  /// its id, and a mover the section gave.
  bool movesStock(SheetCell cell) {
    if (stock == null || cell.row == kFieldsRow || cell.row >= service.records) return false;
    if (typeAt(cell.column) != TableFieldType.stock) return false;

    return service.rowAt(cell.row)?.id.isNotEmpty ?? false;
  }

  /// Leaves [cell]'s product at the figure typed in it ([text]): the difference goes in as a
  /// correction ([TableStockMover.correct]). What is no figure the table counts — a word, a
  /// negative, decimals where whole units are counted — is said and sends nothing; the cell
  /// keeps the figure it had, since nothing was written in the row.
  Future<void> correctStock(SheetCell cell, String text) async {
    final mover = stock;
    final record = service.rowAt(cell.row);
    final context = _context();
    if (mover == null || record == null || !context.mounted) return;

    final typed = text.trim();
    if (typed.isEmpty) return;

    final target = num.tryParse(typed.replaceAll(",", "."));

    if (target == null || target < 0 || !target.isFinite) {
      FloatFlag.of(context).alert(message: S.of(context).stock_typed_invalid);
      return;
    }

    if (!mover.supplies && target != target.roundToDouble()) {
      FloatFlag.of(context).alert(message: S.of(context).stock_typed_whole);
      return;
    }

    final value = record.at(columns.slotAt(cell.column));

    await mover.correct(
      context,
      productId: record.id,
      target: stockNum(target) ?? target,
      shown: value is num ? value : num.tryParse("${value ?? ""}") ?? 0
    );
  }

  /// Opens the movement form of [cell]'s product straight in [direction]: the − and + at the
  /// sides of a record's stock, like the stock summary's (`SummaryStepper`).
  Future<void> stepStock(SheetCell cell, StockDirection direction, BuildContext anchor) async {
    select(cell);

    final mover = stock;
    final record = service.rowAt(cell.row);
    if (mover == null || record == null || !anchor.mounted) return;

    final value = record.at(columns.slotAt(cell.column));

    await showStockMovement(
      anchor,
      service: mover,
      productId: record.id,
      counter: StockCounter.stock,
      direction: direction,
      stock: value is num ? value : num.tryParse("${value ?? ""}") ?? 0,
      // The sheet does not read what is set aside; it only caps setting units aside, which
      // the backend checks anyway.
      reserved: 0
    );
  }
}
