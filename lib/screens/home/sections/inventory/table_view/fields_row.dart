import 'dart:math' as math;

import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_shape.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_window.dart';

import './field_cell.dart';
import './sheet_theme.dart';

/// Row 1 of the sheet: the table's fields.
///
/// The already created ones show their type's icon and name; the free columns
/// at the end are blank and await a title to be written, which is what turns
/// them into fields. All are resized from their right edge, and the ones that
/// are already a field are dragged into place from the cell itself.
///
/// It does not know which the columns are: it receives the sheet's shape, so it is only
/// rebuilt when a column is gained, lost, or moved, and when other columns come into view
/// ([SheetWindow]: it builds the same ones the body's rows do). The title, the type, the
/// cursor, and the width are each listened to by each cell on its own.
class FieldsRow extends StatelessWidget {
  const FieldsRow({super.key, required this.shape});

  /// The shape of the sheet: one column per key, in order.
  final SheetShape shape;

  @override
  Widget build(BuildContext context) {
    final span = context.select<SheetWindow, SheetSpan>((window) => window.span);
    final last = math.min(span.last, shape.length - 1);

    return SizedBox(
      height: SheetTheme.of(context).rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (span.first > 0) SizedBox(width: span.lead),
          for (var index = span.first; index <= last; index++)
            FieldCell(key: ValueKey(shape.keys[index]), index: index, widthKey: shape.keys[index])
        ]
      )
    );
  }
}
