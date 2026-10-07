import 'package:flutter/material.dart';

// SERVICES
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/table_field_type.dart';

import './date_cell.dart';
import './image_cell.dart';
import './listed_cell.dart';
import './price_cell.dart';
import './sku_cell.dart';
import './unit_cell.dart';

export 'date_cell.dart';
export 'image_cell.dart';
export 'listed_cell.dart';
export 'price_cell.dart';
export 'sku_cell.dart';
export 'unit_cell.dart';

/// How the value of a cell that isn't being edited is shown.
///
/// The sheet has a single cell ([SheetCellView]) and it handles everything that
/// is the same across all of them: the width, the border, the cursor, when the
/// editor opens. The only thing that changes with the field type is **how the
/// data looks**, and that is what gets split up here: a price carries its
/// currency symbol, a measurement its unit, a date is written as a date.
///
/// The general case doesn't spend a widget: the vast majority of a sheet's
/// cells are text and return the bare [Text], with no intermediate layer to pay
/// for hundreds of thousands of times. Only the types that really do
/// something different —those in this folder— have their own widget, and there
/// the widget justifies itself: it's what lets them listen to their own thing
/// (the company's currency, in [PriceCell]) without the whole grid listening too.
///
/// In editing it doesn't pass through here: [CellEditor] rules, a single one for
/// the whole sheet that moves with the cursor. A list has no editor either —it is
/// picked in a dropdown, not typed— so it always passes through here, both
/// when it is the cursor's cell and when it isn't.
abstract final class SheetCells {
  static Widget value({
    required TableFieldType type,
    required String value,
    required TextStyle style,
    required TextAlign alignment,
    required int row,
    required int column,
    required String columnKey,
    dynamic raw,
    String unit = "",
    bool editable = true,
    VoidCallback? onGenerateSku
  }) => switch (type) {
    // The two money types read the same —an amount and the symbol of its
    // currency— so the same cell draws them. What separates them is who
    // can say them out loud, which is the agent's business and not the sheet's.
    TableFieldType.price || TableFieldType.currency => PriceCell(
      value: value,
      style: style,
      alignment: alignment,
      unit: unit
    ),
    // A measurement carries the symbol its column declared and a percentage has its
    // own baked in: there the unit **is** the type, so the field doesn't keep
    // one (see [TableFieldType.united]).
    TableFieldType.measure => UnitCell(
      value: value,
      style: style,
      alignment: alignment,
      symbol: unit
    ),
    TableFieldType.discount || TableFieldType.percentage => UnitCell(
      value: value,
      style: style,
      alignment: alignment,
      symbol: "%"
    ),
    // [row] is looked at by the two that render as a control —the list always,
    // the empty SKU while it offers to be generated—: both have to lift off
    // their row's background, and with the zebra that background depends on which
    // band the row falls into (see [SheetStyle.frameFill]).
    TableFieldType.options => ListedCell(
      value: value,
      style: style,
      alignment: alignment,
      row: row
    ),
    // The one with several tags renders like the single one, but its value is not
    // text but a list: that's why it reads [raw] and not [value], which for a list
    // would give Dart's `[a, b]`. They are written on one line (`Shoes, Sports`),
    // which is how they are read and how they travel.
    TableFieldType.categories => ListedCell(
      value: fieldLabelsText(raw ?? value),
      style: style,
      alignment: alignment,
      row: row
    ),
    // The only one that shows not the data but **what the data points to**: the cell
    // holds file ids and what's drawn is the photo. That's why it receives [raw]
    // and not the text: a gallery is a list, and the text of a list
    // (`[a, b]`) is not an image.
    TableFieldType.image => ImageCell(
      raw: raw ?? value,
      row: row,
      column: column
    ),
    // The two date forms read the same, so the format belongs to the
    // column and not the cell: that's why it looks at [columnKey] and not [column].
    TableFieldType.date || TableFieldType.datetime => DateCell(
      value: value,
      style: style,
      alignment: alignment,
      row: row,
      columnKey: columnKey
    ),
    TableFieldType.sku => SkuCell(
      value: value,
      style: style,
      alignment: alignment,
      row: row,
      editable: editable,
      onGenerate: onGenerateSku
    ),
    _ => Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      style: style
    )
  };
}
