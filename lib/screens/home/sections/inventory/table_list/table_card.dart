import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

import 'primary_mark.dart';
import 'table_options.dart';

/// Card of a table: it's how the list looks on desktop, where rows across the
/// width left half a meter of air to the right of each title.
///
/// It carries the same as the phone row ([TableListRow]) and in the same order
/// —the icon and title on top, below it what the table measures and at the end
/// its description—, in three rows instead of one: a card's width is that of a
/// grid column and not of the screen.
///
/// **It's a deliberately small card.** Tables are the top half of the section
/// and the stock summary starts below them: each extra row in the card is one
/// less row of inventory on the first screen. That's why the icon goes on the
/// same row as the title, the options button measures what the icon does and
/// the description fits in one line and not two: it's the one left over when you
/// already know what the table is called and how big it is.
///
/// The whole card opens the table (`/home/inventory/:id`); to the right of the
/// title goes its options button ([TableOptionsButton]), which is the only
/// thing touched without entering.
///
/// If it's the company's primary it says so ([PrimaryTableMark]): it's the one
/// the summary below is looking at.
///
/// The only thing it listens to is **whether its table is still being
/// imported**: an import keeps running after the table is already in the list
/// (the backend types the columns and only then do the rows upload, see
/// [TablesService.import]), and while it lasts the card says so instead of
/// measuring a table that isn't there yet. It's read with `select` and not
/// `watch` so an import repaints its card and not the whole grid.
///
/// And while it lasts **the card doesn't open the table** either: a sheet
/// with untyped columns and no rows looks like an import that failed, and
/// what people do about that is import the file again.
class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.table});

  final TableLiteModel table;

  /// Height of the card. Set by the grid (`mainAxisExtent`) and not by content:
  /// a table without a description and one with a line have to measure the same,
  /// or the grid row would be uneven.
  ///
  /// It comes from [AppSize] and isn't a loose number because the theme's
  /// measures scale with screen density: a fixed-height card would leave the
  /// last line out on screens where the text grows.
  ///
  /// It's the three rows plus the card's air, with a little to spare: the icon
  /// and title one, the measure one and the description one.
  static double get height => AppSize.action * 2.3;

  /// Max width of a grid column. It's a ceiling and not a measure: the grid
  /// distributes whatever width it has into as many columns as fit without
  /// going past this, so the window defines how many and they all end up equal.
  ///
  /// Narrower than a settings card so more fit per row: what a card has to let
  /// read is the table's name, and for that the width left over after the icon
  /// and the button is enough.
  ///
  /// It comes from [AppSize] for the same reason as the height: the icon, the
  /// button and the letters inside grow with screen density, and a fixed-number
  /// ceiling would leave the same card comfortable on one screen and cramped
  /// on the other.
  static double get maxWidth => AppSize.action * 5;

  /// How the list's grid is laid out: how many cards fit per row, how much each
  /// one measures and how much air goes between them.
  ///
  /// It lives in the card and not in the list because they're its own measures
  /// —the height is what its rows occupy and the width is as far as its content
  /// still fits—, and because that way what's tested is the same grid that's
  /// drawn.
  static SliverGridDelegate get grid =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxWidth,
      mainAxisExtent: height,
      crossAxisSpacing: AppSize.gap,
      mainAxisSpacing: AppSize.gap
    );

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final stage = context.select<TablesService, TableImportStage?>(
      (tables) => tables.importStage(table.id)
    );

    return FeedbackButton(
      action: () => _open(context, stage),
      // The wait cursor says the card does not open **before** it is clicked,
      // which is the only moment the notice cannot be given.
      mouseCursor: stage == null ? null : SystemMouseCursors.wait,
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The icon, the name and the options in a single row: all three are
          // "which table is this", and stacked they were two rows to say one
          // thing.
          Row(children: [
            Container(
              width: AppSize.button,
              height: AppSize.button,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(
                  AppSize.cornerInset(AppSize.spaceXS)
                )
              ),
              child: Center(child: Icon(
                CI.list,
                size: AppSize.text * 1.2,
                color: scheme.icon
              ))
            ),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(table.title, ellipsis: true, bold: true)),
            SizedBox(width: AppSize.gap),
            TableOptionsButton(table: table, size: AppSize.button)
          ]),
          SizedBox(height: AppSize.gap),
          // What this table is for the company and how big it is. The mark goes
          // first because it isn't a piece of the table's data but its role:
          // the one the summary below is looking at.
          Row(children: [
            if (table.primary) ...[
              const PrimaryTableMark(),
              SizedBox(width: AppSize.gap)
            ],
            if (stage != null) ...[
              SizedBox(
                width: AppSize.text * 0.8,
                height: AppSize.text * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.text.secondary
                )
              ),
              SizedBox(width: AppSize.gap)
            ],
            Flexible(child: TextSmall(
              stage == null ? _size(context) : _stage(context, stage),
              ellipsis: true,
              color: scheme.text.secondary
            ))
          ]),
          // The description takes the rest of the height: it's the only thing
          // that can be missing, and that way the card of a table without one
          // doesn't fit anything different, it just leaves the empty gap.
          if (table.description.isNotEmpty) ...[
            SizedBox(height: AppSize.gap * 0.5),
            Expanded(child: TextSmall(
              table.description,
              ellipsis: true,
              color: scheme.text.secondary
            ))
          ]
        ]
      )
    );
  }

  /// Opens the table, unless it is still being built.
  ///
  /// A table is in the list from the moment it exists, which is a good half a
  /// minute before it is finished: its columns are still `text`, its rows are
  /// not up yet, and a sheet in that state reads as an import that failed
  /// rather than as one that is halfway. So the tap says what is missing
  /// instead of opening it —doing nothing at all would read as a broken card,
  /// which is the same misunderstanding one step earlier.
  void _open(BuildContext context, TableImportStage? stage) {
    if (stage != null) {
      FloatFlag.of(context).message(S.of(context).import_table_busy);

      return;
    }

    Navis.push(context, "/home/inventory/${table.id}");
  }

  /// What the table measures: its columns and its records, in a single row.
  ///
  /// Records are counted apart from columns and that count can fail on its own
  /// (see [TableLiteModel.records]). When it didn't come, the card shows only
  /// the columns: it's better to say less than to say a loaded table is empty.
  String _size(BuildContext context) {
    final fields = S.of(context).table_field_count(table.fields);

    final records = table.records;
    if (records == null) return fields;

    return "$fields · ${S.of(context).table_record_count(records)}";
  }

  /// What the table is missing, while it's being imported.
  ///
  /// It takes the place of the measure and isn't added to it because that
  /// measure doesn't mean anything yet: the columns can change from here to the
  /// end (the backend adds the image one) and the rows haven't even started
  /// uploading. Saying "0 records" for a thousand-row spreadsheet would be worse
  /// than saying nothing.
  String _stage(BuildContext context, TableImportStage stage) => switch (stage) {
    TableImportStage.preparing => S.of(context).import_table_preparing,
    TableImportStage.loading => S.of(context).import_table_loading
  };
}
