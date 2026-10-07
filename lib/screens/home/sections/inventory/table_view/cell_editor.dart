import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/inventory/table_field_type.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';

import './sheet_theme.dart';

/// The editor of the active cell.
///
/// It is the **only** [TextField] in the sheet: it moves with the cursor, and its
/// [FocusNode] is the one that handles the navigation keys (it sees them before
/// the text field itself, so Tab does not change widgets and Enter does not
/// trigger the submit).
///
/// The controller and the focus are not its own: [SheetController] creates and
/// releases them, since it is the one that knows when a cell opens and closes.
/// That is why this widget is read with `context.read` and listens to nothing:
/// when it must move, the cell containing it is already rebuilding.
class CellEditor extends StatelessWidget {
  const CellEditor({super.key, required this.type, required this.alignment});

  /// Type of the field, which decides which keyboard is used to type.
  final TableFieldType type;

  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();
    final style = SheetTheme.of(context);

    return TextField(
      controller: controller.editor,
      focusNode: controller.focus,
      autofocus: true,
      textAlign: alignment,
      keyboardType: type.keyboard,
      onChanged: controller.onChanged,
      // A date is typed with the numeric keyboard, where the slash is not: the
      // space types it in its place (see [DateSeparatorFormatter]).
      inputFormatters: type.isDate ? const [DateSeparatorFormatter()] : null,
      // It is written with the letter it is read with. It is almost always that
      // of the data, except for a code, which goes in gray (see [SkuCell]), and
      // for the text the AI indexes by meaning, which goes with the brand color:
      // with the usual one, entering the cell would change the color of the text
      // that was already there.
      style: switch (type) {
        TableFieldType.sku => style.code,
        _ => type.semantic ? style.semanticValue : style.value
      },
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero
      )
    );
  }
}
