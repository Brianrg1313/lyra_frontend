import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/import_source.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/inventory/create_table/_create_table.dart';
import 'package:app/screens/modals/inventory/import_table/_import_table.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'import_button.dart';
import 'sticky_bar.dart';
import 'table_card.dart';
import 'table_row.dart';
import 'stock_summary/_stock_summary.dart';

/// Inventory: it's the content of the `inventory` section of the home.
///
/// They are **two areas, one on top of the other**, and answer two different
/// questions:
///
/// 1. **The tables** ([TablesService], `GET /inventory/products/builder/list/`):
///    what the company has loaded. It goes at the top, in a grid, with the
///    create and import actions in the bar.
/// 2. **The stock summary** ([StockSummaryService],
///    `POST /inventory/stock/summary/`): what's inside what it sells. It goes
///    below, as a list, with each product's photo and what's left of it.
///
/// They are together because they are the same question split in two: opening a
/// table to see if there's stock left is a round trip almost nobody makes, so
/// what needs to be looked at often is on the first screen. The summary doesn't
/// depend on a table being selected: the backend answers for the company's
/// primary and says which one it was.
///
/// **Both areas scroll together**: the grid measures what it needs and the
/// summary continues below, in a single scroll. With a separate scroll for each,
/// the summary would get stuck in a little window in the bottom half of the
/// screen.
///
/// **Everything** travels on that same scroll, the action bar included, and
/// there are two rows that don't leave it entirely (see [StickyBar]):
///
/// * The top bar hides when scrolling down and comes back as soon as you scroll
///   the other way, without having to go all the way back up.
/// * The summary's column header sticks to the top while there are rows of it
///   below, and leaves with the summary when the summary ends. With the bar in
///   view it sticks below it, not behind it.
///
/// The screen is split into parts so each one repaints on its own: the top bar
/// listens to nothing and draws once, the body listens to the tables service
/// (which is what changes on load), and the list listens only to what was typed
/// in the search box. That's why the search text arrives as a [ValueListenable]
/// and not as screen state: with `setState` each letter would rebuild the bar
/// and its buttons too.
///
/// **The header search box searches both areas**, each as it can: tables are
/// filtered right here (there are few and they're already in memory) and the
/// summary is filtered by the backend (`MATCH`), because from a table of
/// hundreds of thousands of rows in memory there are stretches. Hence the
/// summary search travels with a breather ([_debounce]) and the tables' doesn't:
/// one is a read and the other is looking at a list you already have.
class InventorySection extends StatefulWidget {
  const InventorySection({super.key});

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  /// What was typed in the header search box, already normalized. The section
  /// doesn't have its own: the top bar is the same for all and searches over
  /// whichever is being looked at. Only the list listens to it.
  late final ValueListenable<String> _query;

  /// `true` while the file is being picked and the table created with it.
  /// Only the import button listens to it, which is the one that shows it.
  ///
  /// It doesn't cover the whole import: what follows —the backend typing the
  /// columns and then the rows being uploaded— happens with the table already
  /// in the list and shows in its row, not in the button, so another one can be
  /// imported in the meantime.
  final _importing = ValueNotifier<bool>(false);

  /// The stock summary of the bottom area. Owned by the section and discarded
  /// when leaving it: the shell remounts it on company change, so there's
  /// nothing to invalidate on its own.
  final _summary = StockSummaryService();

  /// The breather between typing and reading the summary. Without it, every
  /// letter would be a request —and the second-to-last could answer after the
  /// last—; with it, it reads once you stop typing.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery
      ..addListener(_onSearch);

    // Loads notify their listeners; they are deferred to the first frame so a
    // rebuild isn't triggered while the tree is still being mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _load();
      _summary.load(query: _query.value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onSearch);
    _importing.dispose();
    _summary.dispose();
    super.dispose();
  }

  /// Asks for the tables of the active company. The service caches per company,
  /// so this call doesn't hit the backend again if they're already loaded.
  void _load({bool force = false}) => context.read<TablesService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  /// Something was typed in the header search box.
  ///
  /// Tables filter themselves (the [_List] listens to them); the only thing to
  /// do from here is re-read the summary, and only once you've stopped typing.
  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _summary.search(_query.value)
    );
  }

  /// How much the action bar measures: the row of its buttons, the line that
  /// separates it from what follows, and that line's air.
  ///
  /// It's written and not measured because the bar scrolls on its own
  /// ([StickyBar]) and that requires knowing how much it occupies before
  /// drawing it: from its height come how much it moved and how much is left in
  /// view.
  double get _barHeight => AppSize.button + AppSize.spaceXS * 2 + 1;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StockSummaryService>.value(
    value: _summary,
    child: Surface(
      padding: EdgeInsets.fromLTRB(
        AppSize.padding, AppSize.spaceXS,
        AppSize.spaceXS, AppSize.spaceXS
      ),
      // **One single scroll for the whole section, bar included.** What you
      // come to look at here is the inventory, and on a laptop screen the
      // summary starts at the very bottom: leaving the bar pinned would be
      // giving a row of every screen to two buttons used once in a while.
      // It hides when scrolling down and comes back as soon as you scroll the
      // other way, without having to go up to the tables to create one (see
      // [StickyBar]).
      child: CustomScrollView(slivers: [
        StickyBar(
          floating: true,
          height: _barHeight,
          child: Column(children: [
            Expanded(child: Row(children: [
              Expanded(child: TextMedium(
                S.of(context).inventory,
                bold: true,
                ellipsis: true
              )),
              SizedBox(width: AppSize.gap),
              ImportButton(action: _import, loading: _importing),
              SizedBox(width: AppSize.gap),
              Button(
                width: null,
                title: S.of(context).create_table,
                leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
                action: _create
              )
            ])),
            Separator.horizontal(
              margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
            )
          ])
        ),
        _Body(
          query: _query,
          onCreate: _create,
          onRetry: _retry
        )
      ])
    )
  );

  /// Retries the whole section. The one that failed is the tables list —it's
  /// the one that covers the screen with its error— but the summary may have
  /// failed in the same fall, and there the button you see is this one.
  void _retry() {
    _load(force: true);
    _summary.retry();
  }

  /// Opens the create modal. The table is created empty (title, description and
  /// color); when the modal closes the list is reloaded to show it.
  ///
  /// If a table was created, [TablesService.create] left the cache in `idle`
  /// and the reload repopulates it; if it was cancelled, the cache stays `ready`
  /// and [_load] returns without hitting the backend. The section doesn't
  /// unmount when opening the modal (it stays behind), so no one else would
  /// trigger this reload.
  Future<void> _create() async {
    await showModal(
      context: context,
      title: S.of(context).create_table,
      builder: (BuildContext context) => const CreateTableModal()
    );

    if (!mounted) return;

    _load();
    _summaryAfterNewTable();
  }

  /// Re-reads the summary if the table that was just created or imported could
  /// have been **the first** one of the company.
  ///
  /// Only in that case: the table that's created is born empty and the summary
  /// is of the primary table, so adding a second one doesn't change a single
  /// row of what's being looked at. The only thing that changes the summary is
  /// going from having no table —where the backend answers that there's nothing
  /// to summarize— to having the first one, which is born as the primary.
  void _summaryAfterNewTable() {
    if (_summary.status == StockSummaryStatus.missing) _summary.refresh();
  }

  /// Opens the import modal: the list of sources a table's content can come
  /// from ([ImportTableModal]).
  ///
  /// The modal doesn't import anything, it only answers which one was chosen;
  /// the flow of each source opens from here. Today the only one that exists is
  /// the spreadsheet, so any other answer —closing it without choosing included—
  /// does nothing.
  ///
  /// The [_importing] lock is checked before opening the modal so the system
  /// dialog isn't reached with an upload already in progress, but it isn't
  /// touched here: [_importSpreadsheet], which is the one that takes time,
  /// turns it on.
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

  /// Imports a table from a file: the spreadsheet is picked in the system
  /// dialog and uploaded. You get here by choosing "upload spreadsheet" in
  /// [_import].
  ///
  /// The dialog is already filtered to spreadsheets and CSVs
  /// ([pickImportFile]), so there's nothing to validate before uploading;
  /// `unsupported` only appears if the name was typed by hand in a dialog that
  /// doesn't filter (Linux, macOS).
  ///
  /// **This ends before the import.** What's expected here is that the table
  /// exists, which is the only fast thing: typing its columns takes the backend
  /// a good half minute and only then are the rows uploaded (see
  /// [TablesService.import]). That continues on its own, is seen in the table's
  /// row while it lasts, and a flag signals when it ends, whether well or badly.
  ///
  /// The list reloads no matter what: if the table was created, the service
  /// left the cache expired and [_load] brings it —empty and halfway built,
  /// which is how it is—; if nothing was created, the cache stays `ready` and
  /// the call doesn't hit the backend.
  ///
  /// The only ending not signaled from here is `failed`: that error was already
  /// shown by the service with the backend's error, which says more than
  /// a generic text.
  Future<void> _importSpreadsheet() async {
    if (_importing.value) return;

    // It's marked busy before opening the dialog and not just when uploading:
    // the dialog is a system window and while it's open the button is still
    // there, so without this a second click would open another and both tables
    // would end up being entered.
    _importing.value = true;

    final TableImportResult result;

    try {
      final file = await pickImportFile(
        label: S.of(context).import_table_file_type
      );

      // The dialog was closed without choosing anything, or the section left
      // while it was open (it can be open for a good while).
      if (file == null || !mounted) return;

      result = await context.read<TablesService>().import(context, file);
    } finally {
      // Once the section is unmounted the notifier no longer exists: it was
      // released in [dispose] while the file was travelling.
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
    _summaryAfterNewTable();
  }
}

/// The body of the section: the only thing that listens to [TablesService], so
/// loading, failing or bringing the tables doesn't rebuild the top bar.
///
/// The three states that aren't "there are tables" cover the whole body,
/// summary included, and that's what's right: without tables there's no stock
/// to summarize, and a company that couldn't read its own shouldn't see half
/// the inventory as if everything were fine. They take up whatever screen is
/// left below the bar ([SliverFillRemaining]) and no less: a half-screen
/// message stuck at the top with air below reads as a screen error, not as the
/// notice it is.
///
/// It's a sliver, like everything that goes in this section: the scroll is a
/// single one and the bar starts it (see [InventorySection]).
class _Body extends StatelessWidget {
  const _Body({
    required this.query,
    required this.onCreate,
    required this.onRetry
  });

  final ValueListenable<String> query;
  final void Function() onCreate;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();

    return switch (service.status) {
      TablesStatus.loading || TablesStatus.idle => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Loading())
      ),
      TablesStatus.error => SliverFillRemaining(
        hasScrollBody: false,
        child: SectionMessage(
          icon: CI.info,
          title: S.of(context).product_tables_error_title,
          subtitle: S.of(context).product_tables_error_subtitle,
          action: onRetry,
          actionLabel: S.of(context).product_tables_retry,
          actionIcon: CI.plus
        )
      ),
      TablesStatus.empty => SliverFillRemaining(
        hasScrollBody: false,
        child: SectionMessage(
          icon: CI.list,
          title: S.of(context).product_tables_empty_title,
          subtitle: S.of(context).product_tables_empty_subtitle,
          action: onCreate,
          actionLabel: S.of(context).create_table,
          actionIcon: CI.plus
        )
      ),
      TablesStatus.ready => _List(tables: service.tables, query: query)
    };
  }
}

/// The two areas, one below the other and in a single scroll: the tables on
/// top —measuring what they need— and the stock summary continuing on below.
///
/// It only listens to the search box: writing in it touches neither the bar nor
/// the service, it only filters these tables again. The summary isn't filtered
/// here —the backend re-reads it— and that's why it doesn't hang from this
/// `builder`: it's a sliver that draws itself with whatever its own service
/// has.
///
/// The tables filter looks at the title and the description, like the
/// connections one: a table is searched for by how the company called it
/// —"wholesale prices"— and that's also the only phrase where the remembered
/// word can be.
///
/// What's searched already comes normalized by [HomeService.search] (no spaces
/// at the edges and lowercase), so here only the table's text is lowered.
class _List extends StatelessWidget {
  const _List({required this.tables, required this.query});

  final List<TableLiteModel> tables;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(slivers: [
    ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (context, value, _) {
        final filtered = value.isEmpty
          ? tables
          : tables.where((table) =>
              table.title.toLowerCase().contains(value) ||
              table.description.toLowerCase().contains(value)
            ).toList();

        // It's not the same as the empty section: there are tables, but none is
        // called like that. That's why creating one isn't offered, which would
        // be creating it with the name being searched, and why the message takes
        // the height of a card and not the screen: below, the summary
        // continues, which is searching the same and may have found something.
        if (filtered.isEmpty) {
          return SliverToBoxAdapter(child: SizedBox(
            height: TableCard.height,
            child: SectionMessage(
              icon: CI.search,
              title: S.of(context).product_tables_search_empty
            )
          ));
        }

        // On desktop tables go in a grid and on the phone in rows: it's the same
        // list and the same options, laid out according to the width available.
        // A row across a monitor is a short title and half a meter of air; a
        // card on a phone screen doesn't even fit one per row.
        //
        // The tablet goes with the grid: at that width two columns already fit.
        // It's not distributed with `DeviceSelector` like the rest of the app
        // because what's chosen are slivers and not widgets.
        return Responsive.of(context).isPhone
          ? _Rows(tables: filtered)
          : _Grid(tables: filtered);
      }
    ),
    const StockSummarySection()
  ]);
}

/// The tables in a grid, which is how they look on desktop.
///
/// The columns aren't a fixed number but whatever fits: the grid distributes
/// whatever width it has into as many as fit without going past
/// [TableCard.maxWidth], so the same screen shows three tables per row with the
/// side bar open and four with it closed, and they all end up the same width.
///
/// The height is set by the card ([TableCard.height]) instead of coming from a
/// ratio: what stacks inside measures what it measures —two description lines,
/// a title row—, and with `childAspectRatio` that height would depend on the
/// window's width.
class _Grid extends StatelessWidget {
  const _Grid({required this.tables});

  final List<TableLiteModel> tables;

  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    itemCount: tables.length,
    gridDelegate: TableCard.grid,
    itemBuilder: (context, index) => TableCard(table: tables[index])
  );
}

/// The tables in rows, which is how they look on the phone: one below the
/// other at full width, which is all there is.
class _Rows extends StatelessWidget {
  const _Rows({required this.tables});

  final List<TableLiteModel> tables;

  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: tables.length,
    separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
    itemBuilder: (context, index) => TableListRow(table: tables[index])
  );
}
