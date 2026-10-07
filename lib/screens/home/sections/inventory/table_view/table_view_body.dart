import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './sheet.dart';

/// What is shown depends only on the **first** phase: the structure is what
/// says which the columns are, and without them there is no sheet to draw.
///
/// Once it arrives, the grid stays still: reading the records and everything
/// that comes after (saving a row, adding a column) is announced in the top
/// bar, without covering what was being written. A table with no fields is not
/// a dead end either: the empty sheet is shown, which already brings its free
/// columns to write the first title over.
class TableViewBody extends StatelessWidget {
  const TableViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<TableViewService, TableStructureStatus>(
      (service) => service.structureStatus
    );

    return switch (status) {
      TableStructureStatus.idle || TableStructureStatus.loading =>
        const Center(child: Loading()),
      TableStructureStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).product_table_view_error_title,
        subtitle: S.of(context).product_table_view_error_subtitle,
        action: context.read<TableViewService>().retry,
        actionLabel: S.of(context).product_tables_retry
      ),
      TableStructureStatus.ready => const Sheet()
    };
  }
}
