import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import '../sheet_style.dart';

/// The cell of an SKU-type field, out of editing.
///
/// It's set apart from a text cell in two things.
///
/// The first is the color: the code goes in gray ([SheetStyle.code]) and not in
/// the datum's. An SKU isn't something to read or compare at a glance with the
/// one in the row next to it —it's the label you find the product with— and in a
/// full sheet, in black, it's the noisiest column: they're the longest strings
/// and the least legible of all.
///
/// The second is that, while it's empty and can be written, it carries on the
/// right a button that builds a random code ([SheetController.generateSku])
/// without going through the editor. Once the cell has something loaded the
/// button goes away: it's only so the first load doesn't stay blank, not a way
/// to replace what had already been written.
///
/// It's a button and not a loose icon —filled frame, rounded, responding to the
/// mouse hover— and that's what makes it look tappable. But with no label: a
/// sheet cell is narrow and text inside eats the column. What it does is said by
/// the sparkle icon, which is the "generate" one and not the reload one that was
/// there before, and by the help balloon on hover, like the field row.
///
/// It sits against the right border for the same reason as a list's arrow: it's
/// a control, not the datum, and from that side it doesn't step on the code's
/// spot when it appears.
///
/// The fill comes from [SheetStyle.frameFill] and depends on which row it is,
/// for the same reason as in [SelectCell]: with the zebra the sheet uses its two
/// surfaces every other row, so the button takes the one its row isn't using and
/// shows on both bands.
class SkuCell extends StatelessWidget {
  const SkuCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.row,
    required this.editable,
    required this.onGenerate
  });

  /// The SKU as stored (or as just typed in the
  /// row's draft).
  final String value;

  final TextStyle style;

  final TextAlign alignment;

  /// Which row of the sheet it's in. It decides which zebra band its
  /// background belongs to, and with that the button's fill (see [SheetStyle.frameFill]).
  final int row;

  /// Whether the cell can be written. Without this the button would also show on
  /// a field the backend carries or on a row whose record hasn't arrived yet.
  final bool editable;

  /// Builds a new SKU and stores it in this cell. `null` when it doesn't apply
  /// (see [editable]), which is the same as not showing the button.
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);

    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      // The code goes in gray and not in the datum's color: it isn't something to
      // read, it's the label you find the product with (see
      // [SheetStyle.code]). It's always like this, whether the cell can be
      // written or not: the gray doesn't say it's off, it says that's a code.
      style: sheet.code
    );

    if (value.isNotEmpty || !editable || onGenerate == null) return text;

    // A bit taller than a letter: it has to read as a button without weighing
    // like a toolbar one, which in a sheet row doesn't fit.
    final size = AppSize.text * 1.8;

    return Row(children: [
      Expanded(child: text),
      Tooltip(
        // The icon says there's something to generate; this, that the code comes out of
        // nowhere and that another can be asked for. It isn't the button's title: it's
        // what an icon alone can't tell.
        message: S.of(context).product_table_view_sku_generate_hint,
        child: FeedbackButton(
          message: S.of(context).product_table_view_sku_generate,
          width: size,
          height: size,
          radius: sheet.frameRadius,
          color: sheet.frameFill(row: row),
          action: onGenerate,
          child: Center(child: Icon(
            CI.ia,
            size: AppSize.text,
            color: sheet.scheme.text.primary
          ))
        )
      )
    ]);
  }
}
