import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';

import './table_dot.dart';

/// The open table, in the place of the section's title, and the switch to another: the
/// same anchor as the header's business selector, unfolding the company's tables.
/// Creating and importing are the bar's own buttons, not options of this list.
class TableSelector extends StatelessWidget {
  const TableSelector({
    super.key,
    required this.tables,
    required this.table,
    required this.onSelect,
    this.stageOf
  });

  final List<TableLiteModel> tables;

  /// The open one.
  final TableLiteModel table;

  final void Function(TableLiteModel table) onSelect;

  /// What a table's import is up to, to say it in its row.
  final TableImportStage? Function(String tableId)? stageOf;

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
        )
      ]
    );

    if (picked == null) return;

    for (final option in tables) {
      if (option.id == picked.value) return onSelect(option);
    }
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
