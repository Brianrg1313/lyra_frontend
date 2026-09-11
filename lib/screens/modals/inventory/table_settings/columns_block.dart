import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';
import 'columns_table.dart';

/// The columns of the table: how many of each kind and then one by one.
///
/// Above goes the summary by type —what the table is made of— and below the
/// complete list, in the same order in which they are seen in the
/// spreadsheet. It is what allows answering the two questions asked here:
/// "does this table have prices?" is answered with the summary and "what does
/// the third column have?" with the list.
///
/// The list is a table and not a row of cards, and it is also edited: the
/// type, the visibility, the options and whether it enters the inventory
/// summary are changed in the very row of each column (see
/// [TableColumnsTable]). The counts above are not: they are counts, and they
/// correct themselves when the column that moves them is corrected.
///
/// **Bare text columns are reported.** Every column imported from a
/// spreadsheet is born as text, and a table that ended up entirely like that
/// stores data without anyone —not even the AI— being able to compare it,
/// filter it or quote it. It is not an error and that is why the notice is not
/// red: it is what is left to do, and it is done on the same screen.
class TableColumnsBlock extends StatelessWidget {
  const TableColumnsBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final types = detail.columns.sorted;

    return SettingsBlock(
      title: S.of(context).table_settings_columns_title,
      subtitle: S.of(context).table_settings_columns_subtitle,
      child: detail.fields.isEmpty && types.isEmpty
        // A newly created table does not have columns yet: they are written in
        // the spreadsheet, not here, so this block only says it.
        ? TextMedium(
            S.of(context).table_settings_columns_empty,
            lines: 2,
            color: scheme.text.secondary
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (types.isNotEmpty) ...[
                TextSmall(
                  S.of(context).table_settings_types,
                  color: scheme.text.secondary
                ),
                SizedBox(height: AppSize.gap),
                Wrap(
                  spacing: AppSize.gap,
                  runSpacing: AppSize.gap,
                  children: [
                    for (final entry in types) SettingsTag(
                      icon: entry.key.icon,
                      label: S.of(context).table_settings_type_count(
                        entry.key.label(context),
                        entry.value
                      ),
                      color: scheme.text.secondary
                    )
                  ]
                ),
                SizedBox(height: AppSize.spaceS)
              ],
              if (detail.columns.total > 0) ...[
                TextSmall(
                  S.of(context).table_settings_columns_summary_count(
                    detail.columns.summary,
                    detail.columns.total
                  ),
                  lines: 2,
                  color: scheme.text.secondary
                ),
                SizedBox(height: AppSize.spaceS)
              ],
              if (detail.columns.untyped > 0) ...[
                _UntypedNotice(count: detail.columns.untyped),
                SizedBox(height: AppSize.spaceS)
              ],
              TableColumnsTable(fields: detail.fields)
            ]
          )
    );
  }
}

/// How many columns are still bare text, and why it matters.
///
/// It goes in the brand color and not in red: nothing broke, the table is
/// still to be typed. It is the same criterion with which a channel without
/// credentials says "needs configuring" instead of giving an error.
class _UntypedNotice extends StatelessWidget {
  const _UntypedNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      padding: EdgeInsets.all(AppSize.spaceXS),
      color: scheme.accent.withValues(alpha: 0.1),
      radius: AppSize.cornerInset(AppSize.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.5),
            child: Icon(CI.info, size: AppSize.text, color: scheme.accent)
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                S.of(context).table_settings_untyped(count),
                lines: 2,
                color: scheme.accent
              ),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).table_settings_untyped_hint,
                lines: 4,
                color: scheme.text.secondary
              )
            ]
          ))
        ]
      )
    );
  }
}