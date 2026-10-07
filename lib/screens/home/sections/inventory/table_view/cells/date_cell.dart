import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_date.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_dates.dart';

/// The cell of a date-type field, out of editing.
///
/// A stored date is `2026-02-12`, which is how it travels and how it's compared,
/// but not how it's read: a column of dashes and zeros has to be deciphered
/// number by number. Here it's shown written —`Feb 12, 2026`, in the app's
/// language— which is the form in which the month is recognized without reading it.
///
/// On the right it carries the button that switches it to the **full date**: the
/// day in digits and, if one was loaded, its time (`2026-02-12 12:30 PM`). Both
/// readings are needed and neither replaces the other: the written one is for
/// grasping it at a glance, the full one for comparing two rows, copying the date
/// elsewhere or checking when something happened.
///
/// The button changes **the whole column** and not its cell (see [SheetDates]): a
/// column of dates is read as a strip, and with each row in a different
/// format two dates would stop being comparable at a glance.
///
/// What isn't a date is shown just as it was entered, without a button: while the
/// data isn't a date, writing it as one would affirm something that isn't known.
/// It's also what keeps a freshly imported table —with the column full of who
/// knows what— from losing a single datum for not having been understood.
class DateCell extends StatelessWidget {
  const DateCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.row,
    required this.columnKey
  });

  /// The date as stored (or as just typed in the
  /// row's draft).
  final String value;

  final TextStyle style;

  final TextAlign alignment;

  /// Which row of the sheet it's in. It decides which zebra band its
  /// background belongs to, and with that the button's fill (see [SheetStyle.frameFill]).
  final int row;

  /// Its column's key: the same one used to remember its width. It's how
  /// the cell asks —and changes— how that column is being read.
  final String columnKey;

  @override
  Widget build(BuildContext context) {
    final date = ProductDate.parse(value);

    if (date == null) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      );
    }

    final sheet = SheetTheme.of(context);

    // Only its own column: changing one's format can't repaint the dates of
    // the others.
    final full = context.select<SheetDates, bool>(
      (dates) => dates.isFull(columnKey)
    );

    final locale = Localizations.localeOf(context).toString();

    // A bit taller than a letter, like the one that generates a SKU: it has to read
    // as a button without weighing like a toolbar one, which in a sheet row
    // doesn't fit.
    final size = AppSize.text * 1.8;

    return Row(children: [
      Expanded(child: Text(
        full ? date.full(locale) : date.short(locale),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      )),
      Tooltip(
        // The icon says what it switches to; this, that what changes is the column and
        // not this single row.
        message: full
          ? S.of(context).product_table_view_date_short_hint
          : S.of(context).product_table_view_date_full_hint,
        child: FeedbackButton(
          message: full
            ? S.of(context).product_table_view_date_short
            : S.of(context).product_table_view_date_full,
          width: size,
          height: size,
          radius: sheet.frameRadius,
          color: sheet.frameFill(row: row),
          action: () => context.read<SheetDates>().toggle(columnKey),
          child: Center(child: Icon(
            // The icon is the format it switches to, not the one being looked at:
            // a button says what it does.
            full ? CI.calendar : Icons.schedule,
            size: AppSize.text,
            color: sheet.scheme.text.primary
          ))
        )
      )
    ]);
  }
}
