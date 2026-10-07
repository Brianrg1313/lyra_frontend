import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_structure_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';

import './sheet_theme.dart';

/// Arrow on the right edge of a field's cell: unfolds the types and changes
/// that column's.
///
/// It goes where it is expected, attached to the column's title, like in a
/// sheet.
///
/// The [Builder] is not for show: the dropdown anchors to the arrow, so a
/// context is needed that is in its place in the tree and not in the whole
/// cell's.
///
/// It carries no tooltip of its own: the cell's already says what type the
/// column is, and two nested tooltips show both at once.
class TypeArrow extends StatelessWidget {
  const TypeArrow({super.key, required this.field});

  final TableFieldModel field;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();
    final style = SheetTheme.of(context);

    return Builder(
      builder: (context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          // The arrow's tap beats the cell's: it is the child, and in the
          // gesture arena the deepest one keeps the touch.
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.pickType(context, field),
          child: Padding(
            padding: EdgeInsets.only(left: AppSize.gap),
            child: Icon(
              CI.arrow_down,
              size: AppSize.text * 1.4,
              color: style.scheme.text.secondary
            )
          )
        )
      )
    );
  }
}
