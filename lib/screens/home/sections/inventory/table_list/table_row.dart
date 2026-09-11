import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

import 'primary_mark.dart';
import 'table_options.dart';

/// Row of the tables list: the icon, the title with what the table measures
/// (how many columns and how many records) and, if it has one, the description.
/// Tapping it opens the table's view and its data (`/home/inventory/:id`) —
/// unless the table is still being imported, in which case it says what is
/// missing instead of opening a sheet that isn't finished.
///
/// On the right it carries its options button, from where it's renamed, its
/// settings are opened and it's deleted without having to open it
/// ([TableOptionsButton]).
///
/// If it's the company's primary it says so ([PrimaryTableMark]): it's the one
/// the stock summary is looking at.
///
/// It's the shape the list takes on the phone; on desktop the same table is
/// drawn as a grid card ([TableCard]).
///
/// The only thing it listens to is **whether its table is still being
/// imported**: an import keeps running after the table is already in the list
/// (the backend types the columns and only then do the rows upload, see
/// [TablesService.import]), and while it lasts the row says so instead of
/// measuring a table that isn't there yet. It's read with `select` and not
/// `watch` so an import repaints its row and not the whole list.
class TableListRow extends StatelessWidget {
  const TableListRow({super.key, required this.table});

  final TableLiteModel table;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final stage = context.select<TablesService, TableImportStage?>(
      (tables) => tables.importStage(table.id)
    );

    return FeedbackButton(
      action: () => _open(context, stage),
      // The wait cursor says the row does not open **before** it is clicked,
      // which is the only moment the notice cannot be given.
      mouseCursor: stage == null ? null : SystemMouseCursors.wait,
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: scheme.surfaceOver,
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Center(child: Icon(
            CI.list,
            size: AppSize.text * 1.2,
            color: scheme.icon
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextMedium(table.title, ellipsis: true, bold: true)),
              SizedBox(width: AppSize.spaceS),
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
            if (table.description.isNotEmpty) ...[
              SizedBox(height: AppSize.gap),
              TextSmall(
                table.description,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ]
        )),
        SizedBox(width: AppSize.spaceS),
        TableOptionsButton(table: table)
      ])
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
  /// (see [TableLiteModel.records]). When it didn't come, the row shows only
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
