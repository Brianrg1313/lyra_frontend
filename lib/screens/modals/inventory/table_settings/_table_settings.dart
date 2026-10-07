import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/capabilities/capability_service.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import 'agent_block.dart';
import 'channels_block.dart';
import 'columns_block.dart';
import 'columns_table.dart';
import 'summary_block.dart';

/// Opens [tableId] settings in the side panel.
///
/// It is the only door to the card and that is why it is one function and not
/// two loose calls: it is entered from the table menu in the list and from the
/// settings button of the spreadsheet, and both have to open the same thing,
/// with the same width and with the same title.
///
/// It goes to the side and not in the usual centered box because the card is
/// read **against the table**: it opens over where one was —the list or the
/// spreadsheet— and that remains in view next to it, which is what was being
/// looked at when it was wanted to know what columns it is made of. On a phone
/// there is no "next to" and [showSideModal] falls on its own into the bottom
/// sheet.
///
/// The width is told to the panel instead of letting the content ask for it:
/// the card arranges itself with two [LayoutBuilder] —one splits the card into
/// two columns and another splits each row of columns into two lines— and a
/// `LayoutBuilder` does not know how to answer how much it measures until they
/// tell it how much it has. With the minimum and maximum widths equal, the
/// panel is born measured and nobody asks the inside.
Future<void> showTableSettings(BuildContext context, String tableId) async {
  // In a narrow window the window rules: the panel lets the page that
  // accompanies it be seen, and one of 600 over one of 900 covers it whole.
  final width = math.min(
    _panelWidth,
    MediaQuery.of(context).size.width * .55
  );

  // The inventory summary that stays below the panel, if there is one: it
  // opens from the table list, which has it below, but also from the
  // spreadsheet, where it does not exist. Whoever opens takes it noted because
  // inside it can no longer be asked for: the panel hangs from the navigator
  // and not from the section tree, so its providers do not reach here.
  final summary = context.read<StockSummaryService?>();

  await showSideModal(
    context: context,
    title: S.of(context).table_settings_title,
    minWidth: width,
    maxWidth: width,
    builder: (BuildContext context) => TableSettingsModal(
      tableId: tableId,
      summary: summary
    )
  );
}

/// Width of the panel in a window that is enough for it.
///
/// It comes from what the column list needs: its four controls arrange
/// themselves two per row from `AppSize.action * 3.2` each (see
/// [TableColumnsTable]), and on top of that go the panel margins, the card's
/// and the block's. What is left over is extra air on purpose: two wide cells
/// let a long type —"Date and time"— or a column description be read whole,
/// which is what this panel comes to answer.
double get _panelWidth => AppSize.action * 13 + AppSize.padding * 4;

/// The settings of a table: everything there is to know about it **except its
/// rows**. It opens with [showTableSettings], both from the table menu in the
/// list and from the settings button of the spreadsheet.
///
/// It answers five questions:
///
/// 1. **What it is and how big it is** — the name, the description, how many
///    records, how many columns and how many bots read it.
/// 2. **What the model sees** — how much of the table a bot that reads it can
///    use.
/// 3. **Who is reading it** — the connected channels, including the ones that
///    arrive without having chosen it (see [TableChannelsBlock]).
/// 4. **When something happened** — when it was created, when its structure
///    last changed and when the last data point came in. They are different
///    dates and they are shown different (see [TableDatesBlock]).
/// 5. **What it is made of** — its columns, one by one, with their type and
///    visibility (see [TableColumnsBlock]).
///
/// The dates go after the channels because they are the query data of the
/// card: they are looked up when it is already known that something is being
/// searched —how long since a record came in, when the structure was touched—,
/// while the two previous ones are the ones looked at when entering without
/// searching anything.
///
/// The columns go at the end and alone, and not because they are the last
/// thing that matters: they are a table of five cells per row and need the
/// whole width of the panel. Put in one of the two halves they would end with
/// three hundred pixels for the column name, its type, its visibility and its
/// options.
///
/// Everything is read in a single request (`GET /inventory/products/builder/details/<id>`): the endpoint
/// gathers what lives in three different databases precisely so that this card
/// does not have to make three trips. It is an expensive read and that is why
/// it is **not in the structure** that draws the spreadsheet, which is asked
/// for on every click.
///
/// What is **written** from here is written in the row where it is read,
/// without forms in between: the two texts that someone writes —the title and
/// the description, see [TableSummaryBlock]— and, from each column, its type,
/// its visibility and the options of its list (see [TableColumnsTable]). They
/// are the data points that are looked at comparing the whole table, and that
/// is why they are corrected where they were compared and not opening the
/// spreadsheet column by column.
///
/// What is not written here keeps being edited where it is seen: the row
/// values in the spreadsheet itself, which table a bot reads from the bot.
///
/// **What is touched is seen while it is touched.** Turning on or off the
/// summary of a column —or changing its type— re-reads the inventory summary
/// that stayed next to the panel (see [StockSummaryService.syncColumns]), which
/// is precisely where that checkbox is noticed. Choosing blindly and seeing
/// the result when closing, arranging the summary would be four round trips.
///
/// Which table arrives by constructor and not from the URL: the panel mounts
/// over the page and not in its place, so the address keeps being the one of
/// what is below —the list or the spreadsheet— and says nothing about which
/// card was opened.
///
/// It also does not listen to the business change, unlike the screens tied to
/// an id: while the panel is open the selector stays behind its veil, so the
/// table being looked at cannot stop being of the active business.
///
/// The service ([TableDetailService]) is owned by this panel and not by the
/// app scope: it is the state of a table that is being looked at, and it is
/// also precisely what is not convenient to cache —this is opened to see how
/// the table is now, not how it was the last time—.
class TableSettingsModal extends StatefulWidget {
  const TableSettingsModal({
    super.key,
    required this.tableId,
    this.summary
  });

  final String tableId;

  /// The inventory summary that keeps being seen next to the panel, when the
  /// card was opened from the section that has it. Null if it was opened from
  /// the spreadsheet: there there is none to notify.
  final StockSummaryService? summary;

  @override
  State<TableSettingsModal> createState() => _TableSettingsModalState();
}

class _TableSettingsModalState extends State<TableSettingsModal> {
  // Owned by the panel: created when it opens and released when it closes.
  // See the class note about why it is not cached.
  late final _service = TableDetailService(onSummaryChanged: _syncSummary);

  @override
  void initState() {
    super.initState();

    // The load is deferred to the first frame so as not to notify while the
    // tree mounts, same as the rest of the screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _service.load(widget.tableId);

      // The network catalog is what gives a name and icon to each channel
      // that reads the table. It is cached for the whole session, so if the
      // channels section was already visited this does not hit the backend,
      // and if it fails the list is drawn the same with the raw network code.
      context.read<ChannelCatalogService>().load();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  /// Carries a column change of this table to the inventory summary.
  ///
  /// Who decides if it matters is the summary and not this panel: it summarizes
  /// the main table of the business, which is not necessarily the one opened
  /// here (see [StockSummaryService.syncColumns]).
  void _syncSummary() => widget.summary?.syncColumns(widget.tableId);

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider<TableDetailService>.value(
      value: _service,
      child: Column(children: [
        _Header(tableId: widget.tableId),
        SizedBox(height: AppSize.gap),
        const Expanded(child: _Body())
      ])
    );
}

/// Which table these settings are, and the button to re-read them.
///
/// The name goes in here and not in the title of the panel because **it
/// changes from the card itself**: it is renamed in the first row (see
/// [TableSummaryBlock]) and a title that was passed to the panel when it
/// opened would stay with the old one. Up top stays what does not change —that
/// these are the settings of a table— and here, which one.
///
/// The name is given by the detail, which is the one that brings the real one;
/// until it arrives, the one the table list already had cached is shown and,
/// if it is not even there (the card was opened with the list unloaded), a
/// generic one. It is the same path the spreadsheet header takes, and for the
/// same reason: the card is drawn with the name already put instead of
/// premiering it one frame later.
class _Header extends StatelessWidget {
  const _Header({required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final cached = context.select<TablesService, String>(
      (tables) => _cachedTitle(tables.tables, tableId)
    );

    // From the service, **resolved text** is taken and not the detail: the
    // rest it brings —twenty columns, the channels— says nothing of this bar,
    // and with the object it would be repainted for everything.
    final (name, color, reloading) = context
      .select<TableDetailService, (String, Color?, bool)>(
        (service) => (
          service.detail.name,
          service.detail.tint,
          service.isReloading
        )
      );

    final title = name.isNotEmpty
      ? name
      : cached.isNotEmpty ? cached : S.of(context).product_table_view_title;

    return Row(children: [
      if (color != null) ...[
        Container(
          width: AppSize.text * 0.75,
          height: AppSize.text * 0.75,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)
        ),
        SizedBox(width: AppSize.spaceXS)
      ],
      Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
      SizedBox(width: AppSize.spaceS),
      // While it re-reads, the button gives way to the spinner: they are the
      // same thing in two moments, and leaving the two would run the whole
      // bar.
      if (reloading)
        SizedBox(
          width: AppSize.action,
          height: AppSize.action,
          child: Center(child: SizedBox(
            width: AppSize.text,
            height: AppSize.text,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          ))
        )
      else
        FeedbackButton(
          action: context.read<TableDetailService>().refresh,
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).table_settings_refresh,
          child: Center(child: Icon(
            Icons.refresh,
            size: AppSize.spaceM,
            color: scheme.text.primary
          ))
        )
    ]);
  }

  /// Title of the table according to the cached list, or empty if it is not
  /// loaded yet.
  static String _cachedTitle(List<TableLiteModel> tables, String id) {
    for (final table in tables) {
      if (table.id == id && table.title.isNotEmpty) return table.title;
    }
    return "";
  }
}

/// The body, which depends only on the state of the single read of the card.
///
/// Without a detail there is no card to draw —everything it shows comes from
/// it— so the wait is the blank panel and the error takes it whole, with the
/// re-read as the way out. A **re-read** does not go through here: it is
/// announced above and what there is stays where it is.
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    // The detail goes in the same `select` as the state and is not read
    // apart: a re-read leaves the state in `ready` and changes only the
    // object, so looking at the state on its own the card would stay with the
    // previous read.
    final (status, detail) = context
      .select<TableDetailService, (TableDetailStatus, TableDetailModel)>(
        (service) => (service.status, service.detail)
      );

    return switch (status) {
      TableDetailStatus.idle || TableDetailStatus.loading =>
        const Center(child: Loading()),
      TableDetailStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).table_settings_error_title,
        subtitle: S.of(context).table_settings_error_subtitle,
        action: context.read<TableDetailService>().retry,
        actionLabel: S.of(context).product_tables_retry
      ),
      TableDetailStatus.ready => _Details(detail: detail)
    };
  }
}

/// The card: above, two halves that are read separately —**what this table
/// is** (what it has, when it changed) and **what it is being used for** (how
/// much the model sees, who reads it)— and below, taking the whole width, what
/// columns it is made of.
///
/// In the panel the two halves stack in the order of above read in a row,
/// which is the order in which the questions are asked; the cut in two stays
/// for the width in which both fit, which is that of the whole window.
///
/// The columns go below and unbroken because they are a table, not a data
/// point: five cells per row need the whole width, and they are also as long
/// as the table has columns, so above they would push everything else out of
/// the screen.
class _Details extends StatelessWidget {
  const _Details({required this.detail});

  final TableDetailModel detail;

  /// Width from which the card opens into two columns. The same as the channel
  /// form: it is the width at which two columns of data are still read.
  static double get _twoColumns => AppSize.action * 16;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // The air of the card is put by the scroll and not by a `Padding`
      // outside: the bar has to sit against the edge, not inside the margin.
      // That is why it is discounted here before splitting into columns.

      // A width without measurement cannot be passed to the halves: the
      // minimum to split is taken, which leaves a single column.
      final available = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _twoColumns - 1;

      final split = available >= _twoColumns;

      // To the floor: two halves that add a hair more than the width because
      // of floating point rounding do not fit in the same row, and the [Wrap]
      // lowers the second —one column when there was room for two—.
      final column = split
        ? ((available - AppSize.spaceM) / 2).floorToDouble()
        : available;

      return ScrollableWidget(
        showBar: false,
        children: [
          Wrap(
            spacing: AppSize.spaceS,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(width: column, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TableSummaryBlock(detail: detail)]
              )),
              SizedBox(width: column, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agents and channels are the cloud's (I-5): not offered, not drawn.
                  if (CapabilityService().shows("channels")) ...[
                    TableAgentBlock(detail: detail),
                    TableChannelsBlock(detail: detail)
                  ],
                  TableDatesBlock(detail: detail)
                ]
              ))
            ]
          ),
          TableColumnsBlock(detail: detail)
        ]
      );
    }
  );
}