import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';

/// The open table, in the place of the section's title, and the switch to another: the
/// same anchor as the header's business selector, unfolding the company's tables.
///
/// Creating and importing live at the end of that list, as creating a company does in
/// the business selector: they are a new table, and the list is where tables are chosen.
/// Creating is written in the list itself (the name, Enter), which is all a table needs to
/// exist; its columns are written in the sheet.
class TableSelector extends StatelessWidget {
  const TableSelector({
    super.key,
    required this.tables,
    required this.table,
    required this.onSelect,
    required this.onCreate,
    this.onImport,
    this.stageOf
  });

  final List<TableLiteModel> tables;

  /// The open one.
  final TableLiteModel table;

  final void Function(TableLiteModel table) onSelect;

  /// Creates a blank table named as typed; answers its id, or null if it was not created
  /// (the service already said why).
  final Future<String?> Function(String name) onCreate;

  /// Null where importing isn't offered (`inventory.import`).
  final void Function()? onImport;

  /// What a table's import is up to, to say it in its row.
  final TableImportStage? Function(String tableId)? stageOf;

  /// The import option's value: never a table id (those are uuids).
  static const _import = "\u0000import";

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Builder(builder: (anchor) => FeedbackButton(
      action: () => _open(anchor),
      color: scheme.input.fill,
      height: AppSize.action,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      message: S.of(context).inventory_table_selector,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TableDot(color: table.color),
          SizedBox(width: AppSize.gap),
          Flexible(child: TextMedium(table.title, bold: true, ellipsis: true)),
          SizedBox(width: AppSize.gap),
          Icon(CI.arrow_down, color: scheme.text.secondary)
        ]
      )
    ));
  }

  Future<void> _open(BuildContext anchor) async {
    final s = S.of(anchor);

    final picked = await showSelectMenu(
      context: anchor,
      selected: table.id,
      maxOptions: 7,
      searchPlaceholder: tables.length > 6 ? s.inventory_table_search : null,
      emptyText: s.product_tables_search_empty,
      options: [
        for (final option in tables) SelectOption(
          value: option.id,
          placeholder: option.title,
          leading: TableDot(color: option.color),
          subtitle: _subtitle(s, option)
        ),
        if (onImport != null) SelectOption(
          value: _import,
          placeholder: s.import_table,
          icon: Icons.file_upload_outlined
        )
      ],
      createText: s.create_table,
      createPlaceholder: s.table_title_placeholder,
      onCreate: (name) async {
        final id = await onCreate(name);
        return id == null ? null : SelectOption(value: id, placeholder: name);
      }
    );

    if (picked == null) return;

    if (picked.value == _import) {
      onImport?.call();
      return;
    }

    for (final option in tables) {
      if (option.id == picked.value) return onSelect(option);
    }

    // Just created: not in the list yet, which reloads behind.
    onSelect(TableLiteModel(id: picked.value, title: picked.placeholder));
  }

  /// What tells a table apart in the list: an import still running, then being the
  /// primary one, then its description.
  String? _subtitle(S s, TableLiteModel option) {
    final stage = stageOf?.call(option.id);

    if (stage != null) {
      return switch (stage) {
        TableImportStage.preparing => s.import_table_preparing,
        TableImportStage.loading => s.import_table_loading
      };
    }

    if (option.primary) return s.table_primary;

    return option.description.isEmpty ? null : option.description;
  }
}

/// A table's colour, as a dot: an adornment, so a colour that doesn't read is no dot.
class TableDot extends StatelessWidget {
  const TableDot({super.key, required this.color});

  /// Flutter ARGB literal (`0xFF2196F3`).
  final String color;

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(color);

    return Container(
      width: AppSize.text * 0.75,
      height: AppSize.text * 0.75,
      decoration: BoxDecoration(
        color: parsed == null ? ThemeColor.of(context).text.secondary : Color(parsed),
        shape: BoxShape.circle
      )
    );
  }
}
