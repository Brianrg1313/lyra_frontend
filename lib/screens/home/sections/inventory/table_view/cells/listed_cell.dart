import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';

/// The cell of a field that picks from a list: one option (`OPTIONS`) or several
/// (`CATEGORIES`).
///
/// It's a single cell for both types because both are **tapped**: what changes
/// is how many tags end up written inside, not how it looks or how you get to
/// them. The ones in a several-tag cell come already written on one line
/// (`Shoes, Sports`, see `fieldLabelsText`), so here they're text like any other.
///
/// It's the sheet's only cell that looks like a **control** and not a datum, and
/// it has to be: it isn't typed, it's tapped and it unfolds
/// ([SheetController.pickOption]). A cell that opens something and looks the
/// same as a text one has no way to say so, so it carries the frame of an
/// expandable button —a filled [Surface] and its arrow— lifted off the cell's
/// borders so it reads as something **inside** it and not as the cell itself.
///
/// The fill comes from [SheetStyle.frameFill] and depends on which row it is:
/// with the zebra the sheet uses its two surfaces every other row, so the frame
/// takes the one its row isn't using. With a fixed color it would disappear in
/// half the sheet.
///
/// The frame is always there and not just in the chosen cell: it's what says
/// that column is picked, and that has to be known **before** tapping it. It's
/// one box per row, which is what it costs for a column to explain itself.
///
/// The value shows as it was stored, whether or not it's among the field's
/// options. What's stored is the label itself (not an index to it), so
/// removing an option from the list doesn't erase what had already been loaded
/// with it: it still reads what was captured, which is the datum someone put,
/// and the list only rules over what gets picked from now on.
class ListedCell extends StatelessWidget {
  const ListedCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.row
  });

  /// What the cell has loaded (or what was just picked in the row's draft):
  /// one label, or several already written on one line. Empty
  /// while none have been picked.
  final String value;

  /// Style of the value. The cell decides it, since it knows if the field is typed.
  final TextStyle style;

  final TextAlign alignment;

  /// Which row of the sheet it's in. It decides which zebra band its
  /// background belongs to, and with that the frame's fill (see [SheetStyle.frameFill]).
  final int row;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);

    return Surface(
      // The frame takes the whole cell minus the air that
      // [SheetStyle.framePadding] leaves. Without the sizes it would shrink to the text,
      // because the cell gives it its height but offers it loose.
      width: double.infinity,
      height: double.infinity,
      radius: sheet.frameRadius,
      color: sheet.frameFill(row: row),
      padding: EdgeInsets.only(left: AppSize.spaceXS),
      child: Row(children: [
        Expanded(child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment,
          style: style
        )),
        Icon(
          CI.arrow_down,
          size: AppSize.text * 1.4,
          color: sheet.scheme.text.secondary
        )
      ])
    );
  }
}
