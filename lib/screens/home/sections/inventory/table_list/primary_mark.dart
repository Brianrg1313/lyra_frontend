import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The mark of the company's primary table, in the list.
///
/// **Answers where the summary below comes from.** Nobody chooses the stock
/// summary: the backend always answers for the primary table
/// (`tables`.`primary`, see `StockSummaryService`). Without this mark, a
/// company with six tables has no way of knowing which of the six is the one
/// being looked at down there, nor on which one to turn on a column's toggle so
/// it shows up.
///
/// It's a label and not a loose icon: "primary" is a word that has to be said.
/// An adornment in the corner of a card reads as decoration, and the only one
/// who'd know what it means is whoever already knew which their primary table
/// is.
///
/// It goes with the table's size and not stuck to the title: the title was
/// written by the company and can be long, and in a grid card —which is
/// deliberately narrow— the two together would leave the name cut mid-word to
/// make room for this.
class PrimaryTableMark extends StatelessWidget {
  const PrimaryTableMark({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Tooltip(
      message: S.of(context).table_primary_hint,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.gap,
          vertical: AppSize.gap * 0.3
        ),
        decoration: BoxDecoration(
          // Barely tinted with the brand color, just like the settings card's
          // labels: it accompanies the data, it doesn't compete with the title.
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CI.shop, size: AppSize.text * 0.9, color: scheme.primary),
            SizedBox(width: AppSize.gap * 0.5),
            TextSmall(S.of(context).table_primary, color: scheme.primary)
          ]
        )
      )
    );
  }
}
