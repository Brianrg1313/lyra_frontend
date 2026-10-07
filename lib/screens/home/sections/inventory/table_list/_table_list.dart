import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/capabilities/capability_service.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/import_source.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/inventory/create_table/_create_table.dart';
import 'package:app/screens/modals/inventory/import_table/_import_table.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';

import 'import_button.dart';
import 'inventory_bar.dart';
import 'inventory_start.dart';
import 'stock_summary/_stock_summary.dart';
import 'table_options.dart';
import 'table_selector.dart';
import 'view_toggle.dart';

/// Inventory: the content of the `inventory` section of the home, **one table at a
/// time**.
///
/// The bar's title is the open table ([TableSelector]): picking another one switches
/// the whole section to it. The bar's right end carries the open table's options
/// ([TableOptionsButton]: rename, settings, delete), the import and create, whatever the
/// view. Next to the selector, the cells switch ([InventoryViewToggle]) shows the open table as its
/// stock summary ([StockSummarySection]: photo, the columns chosen for it and what's
/// left) or as every cell of it ([TableViewSection], the sheet). Both are the account's
/// choices and are remembered (`PreferencesService`): which table, per company, and
/// which view.
///
/// Which table opens: the link's (`/home/inventory/:id`), else the one last open in this
/// company, else the primary one, else the first. A table that is gone (deleted, another
/// company's link) falls to the next on its own.
///
/// A company with no table sees [InventoryStart] instead: the templates for its
/// activity, a blank table and the import. The templates are read there and only there.
///
/// A table still being imported is not opened in either view (its columns are untyped
/// and its rows not up yet, which reads as an import that failed): what's open shows
/// what the import is up to until it lands.
class InventorySection extends StatefulWidget {
  const InventorySection({super.key});

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  /// The table asked for: the link's, a pick or a just created one. What opens is
  /// resolved against the list on each build ([_open]).
  String? _picked;

  /// `true` while the file is being picked and the table created with it; the import
  /// button shows it. What follows —the backend typing the columns, the rows going
  /// up— shows on the table.
  final _importing = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    _picked = Navis.currentArgs?["id"];

    // Loads notify their listeners; deferred to the first frame so a rebuild
    // isn't triggered while the tree is still being mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _importing.dispose();
    super.dispose();
  }

  /// Asks for the tables of the active company. The service caches per company,
  /// so this call doesn't hit the backend again if they're already loaded.
  void _load({bool force = false}) => context.read<TablesService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  /// The table that opens, among [tables] (never empty).
  TableLiteModel _open(List<TableLiteModel> tables) {
    final remembered = PreferencesService().recall(RememberedSelection.table);

    for (final id in [_picked, remembered]) {
      for (final table in tables) {
        if (id != null && table.id == id) return table;
      }
    }

    for (final table in tables) {
      if (table.primary) return table;
    }

    return tables.first;
  }

  void _select(String id) {
    setState(() => _picked = id);
    PreferencesService().remember(RememberedSelection.table, id);

    // A table's link would keep naming the one it opened, and the last page is
    // what the app reopens on: back to the section's own path.
    if (Navis.currentKey.value == TableViewSection.routeKey) {
      Navis.push(context, "/home/inventory");
    }
  }

  /// A blank table through the create modal, which answers its id.
  Future<void> _createWithModal() async {
    final id = await showModal(
      context: context,
      title: S.of(context).create_table,
      builder: (BuildContext context) => const CreateTableModal()
    );

    if (!mounted || id is! String) return;

    _created(id);
  }

  /// A table was just created: it opens, and the list (left stale by the service)
  /// reads it.
  void _created(String id) {
    _select(id);
    _load();
  }

  /// Opens the import modal: the list of sources a table's content can come
  /// from ([ImportTableModal]). The modal only answers which one was chosen; today
  /// the only source is the spreadsheet.
  Future<void> _import() async {
    if (_importing.value) return;

    final source = await showModal(
      context: context,
      title: S.of(context).import_table,
      builder: (BuildContext context) => const ImportTableModal()
    );

    if (!mounted || source != ImportSource.spreadsheet) return;

    await _importSpreadsheet();
  }

  /// Imports a table from a file picked in the system dialog.
  ///
  /// **This ends before the import.** What's expected here is that the table
  /// exists, which is the only fast thing: typing its columns takes the backend
  /// a good half minute and only then are the rows uploaded (see
  /// [TablesService.import]). That goes on by itself and shows on the table.
  ///
  /// The only ending not signaled from here is `failed`: the service already
  /// showed the backend's error, which says more than a generic text.
  Future<void> _importSpreadsheet() async {
    if (_importing.value) return;

    // Busy before the dialog and not just while uploading: the dialog is a
    // system window and a second click would open another, entering both tables.
    _importing.value = true;

    final TableImportResult result;

    try {
      final file = await pickImportFile(
        label: S.of(context).import_table_file_type
      );

      if (file == null || !mounted) return;

      result = await context.read<TablesService>().import(context, file);
    } finally {
      if (mounted) _importing.value = false;
    }

    if (!mounted) return;

    switch (result) {
      case TableImportResult.started:
        FloatFlag.of(context).message(S.of(context).import_table_started);
      case TableImportResult.unsupported:
        FloatFlag.of(context).error(
          message: S.of(context).import_table_unsupported
        );
      case TableImportResult.failed:
        break;
    }

    _load();
  }

  void Function()? get _importAction =>
    CapabilityService().shows("inventory.import") ? _import : null;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();
    final tables = service.tables;

    // A reload keeps the tables it had in view: only a first read covers the section.
    if (tables.isEmpty) {
      return switch (service.status) {
        TablesStatus.error => Surface(child: SectionMessage(
          icon: CI.info,
          title: S.of(context).product_tables_error_title,
          subtitle: S.of(context).product_tables_error_subtitle,
          action: () => _load(force: true),
          actionLabel: S.of(context).product_tables_retry
        )),
        TablesStatus.empty => InventoryStart(
          onCreated: _created,
          onBlank: _createWithModal,
          onImport: _importAction,
          importing: _importing
        ),
        _ => const Surface(child: Center(child: Loading()))
      };
    }

    final table = _open(tables);
    final stage = service.importStage(table.id);

    final parts = InventoryBarParts(
      selector: TableSelector(
        tables: tables,
        table: table,
        onSelect: (table) => _select(table.id),
        stageOf: service.importStage
      ),
      controls: const [InventoryViewToggle()],
      actions: [
        TableOptionsButton(table: table),
        if (_importAction != null) ImportButton(action: _import, loading: _importing),
        Button(
          width: null,
          title: S.of(context).create_table,
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          action: _createWithModal
        )
      ]
    );

    if (stage != null) {
      return Surface(child: Column(children: [
        InventoryBar(parts: parts),
        Separator.horizontal(),
        Expanded(child: SectionMessage(
          icon: CI.documents_excel,
          title: switch (stage) {
            TableImportStage.preparing => S.of(context).import_table_preparing,
            TableImportStage.loading => S.of(context).import_table_loading
          },
          subtitle: S.of(context).import_table_busy
        ))
      ]));
    }

    return ValueListenableBuilder<InventoryView>(
      valueListenable: PreferencesService().inventoryView,
      builder: (context, view, _) => switch (view) {
        InventoryView.summary => StockSummarySection(
          key: ValueKey("summary_${table.id}"),
          tableId: table.id,
          parts: parts
        ),
        InventoryView.sheet => TableViewSection(
          key: ValueKey("sheet_${table.id}"),
          tableId: table.id,
          parts: parts
        )
      }
    );
  }
}
