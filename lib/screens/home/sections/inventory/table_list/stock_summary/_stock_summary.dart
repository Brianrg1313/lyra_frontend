import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/services/stock/sources/stock_source.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';

import '../inventory_bar.dart';
import 'summary_layout.dart';
import 'summary_row.dart';

/// The stock summary of the open table: the section's view while the cells switch is off.
///
/// It owns the summary of [tableId] ([StockSummaryService]) and the section keys it by
/// the table, so picking another one reads another summary from the start.
///
/// **You touch here and not in the table.** Each row's two numbers carry their
/// buttons (see `SummaryStepper`): six came in, two were sold, three have to be
/// set aside. Tapping the row opens nothing, which was the old gesture and left
/// every movement one pixel away from going to another screen.
///
/// The column header stays fixed on top and the rows scroll below it: on row forty a
/// column of numbers says nothing without the title that says which is which.
///
/// **The header search box searches it** through the backend (`MATCH`): of a table with
/// hundreds of thousands of rows only a few pages are in memory. Hence the breather
/// ([_StockSummarySectionState._debounce]) between typing and reading.
class StockSummarySection extends StatefulWidget {
  const StockSummarySection({
    super.key,
    required this.tableId,
    required this.parts,
    this.status = const [],
    this.source
  });

  final String tableId;
  final InventoryBarParts parts;

  /// The summary's source; null reads `Sources.stock`. A seam for tests.
  final StockSource? source;

  /// What the section adds to the bar's status (an upload in flight).
  final List<Widget> status;

  @override
  State<StockSummarySection> createState() => _StockSummarySectionState();
}

class _StockSummarySectionState extends State<StockSummarySection> {
  late final _summary = StockSummaryService(source: widget.source, tableId: widget.tableId);

  late final ValueListenable<String> _query;

  /// Without it every letter would be a request —and the second-to-last could
  /// answer after the last—; with it, it reads once you stop typing.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery..addListener(_onSearch);

    // Loads notify their listeners; deferred to the first frame so a rebuild
    // isn't triggered while the tree is still being mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _summary.load(query: _query.value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onSearch);
    _summary.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _summary.search(_query.value)
    );
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StockSummaryService>.value(
    value: _summary,
    child: Surface(child: Column(children: [
      _Bar(parts: widget.parts, status: widget.status),
      Separator.horizontal(),
      const Expanded(child: _Body())
    ]))
  );
}

/// The section's bar, with how many products the summary has. While reading, how many
/// there are isn't said: during a search the previous number would still be there
/// counting something else.
class _Bar extends StatelessWidget {
  const _Bar({required this.parts, required this.status});

  final InventoryBarParts parts;
  final List<Widget> status;

  @override
  Widget build(BuildContext context) {
    final (total, counted) = context.select<StockSummaryService, (int, bool)>(
      (service) => (
        service.total,
        service.status == StockSummaryStatus.ready || service.status == StockSummaryStatus.empty
      )
    );

    return InventoryBar(parts: parts, status: [
      ...status,
      if (counted) TextSmall(
        S.of(context).stock_summary_count(total),
        color: ThemeColor.of(context).text.secondary,
        ellipsis: true
      )
    ]);
  }
}

/// What's seen below the bar, depending on how the read came out.
class _Body extends StatelessWidget {
  const _Body();

  /// How many rows before the end the next stretch is requested. Enough for the
  /// page to arrive while still scrolling down, without asking for it when
  /// seeing the first row.
  static const int _lookahead = 5;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StockSummaryService>();

    return switch (service.status) {
      StockSummaryStatus.idle || StockSummaryStatus.loading => const Center(child: Loading()),
      StockSummaryStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).stock_summary_error_title,
        subtitle: S.of(context).stock_summary_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).stock_summary_retry
      ),
      // `missing` is a company without tables, where the section shows the templates
      // instead of a summary; a table deleted from under it reads the same as empty.
      StockSummaryStatus.empty || StockSummaryStatus.missing => SectionMessage(
        icon: service.isSearching ? CI.search : CI.shop,
        title: service.isSearching
          ? S.of(context).stock_summary_search_empty
          : S.of(context).stock_summary_empty_title,
        subtitle: service.isSearching
          ? null
          : S.of(context).stock_summary_empty_subtitle
      ),
      StockSummaryStatus.ready => _list(context, service)
    };
  }

  /// The column header and the rows read.
  ///
  /// The column distribution is computed once and goes down to all rows: it's
  /// the same for the header and for each product, and recomputing it per row
  /// would be repeating the same count hundreds of times per frame.
  Widget _list(BuildContext context, StockSummaryService service) {
    final layout = SummaryLayout.of(context, service.columns);
    final currency = _currency(context);
    final rows = service.rows;

    return Padding(
      padding: EdgeInsets.only(left: AppSize.padding, right: AppSize.spaceXS),
      child: Column(children: [
        SizedBox(
          height: SummaryLayout.headerHeight,
          child: Column(children: [
            Expanded(child: SummaryHeader(layout: layout)),
            Separator.horizontal()
          ])
        ),
        Expanded(child: ListView.builder(
          itemCount: rows.length + 1,
          itemBuilder: (context, index) {
            if (index == rows.length) return _Footer(service: service);

            // The next stretch is requested while the end of the current one is
            // drawn. The service makes sure asking too much does nothing.
            if (index >= rows.length - _lookahead) service.more();

            return SummaryProductRow(
              row: rows[index],
              layout: layout,
              currency: currency,
              // The zebra alternates by position in the list, just like in the
              // spreadsheet: the odd ones are the painted ones.
              zebra: index.isOdd
            );
          }
        ))
      ])
    );
  }

  /// The currency the company charges with, which is what any price column of
  /// the summary is written in.
  ///
  /// They're two subscriptions and not one: the company says **in which
  /// currency** it charges and the catalog says **how it's written**. They are
  /// read once here and go down to the rows; reading them in each cell would be
  /// subscribing the whole list to the catalog.
  CurrencyModel _currency(BuildContext context) {
    final code = context.select<BusinessService, String>(
      (business) => business.currencyCode
    );

    return context.select<CurrencyCatalogService, CurrencyModel>(
      (catalog) => catalog.resolve(code)
    );
  }
}

/// The end of the list: what's happening with the next stretch.
///
/// While more rows come down you see they're coming, and if the stretch didn't
/// arrive retrying is offered. With everything read it takes up nothing: a list
/// that already ended doesn't have to say so.
class _Footer extends StatelessWidget {
  const _Footer({required this.service});

  final StockSummaryService service;

  @override
  Widget build(BuildContext context) {
    if (service.moreFailed) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
        child: Center(child: SizedBox(
          width: AppSize.action * 4,
          child: Button(
            title: S.of(context).stock_summary_retry,
            action: service.retryMore
          )
        ))
      );
    }

    if (!service.hasMore) return SizedBox(height: AppSize.spaceS);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
      child: const Center(child: Loading())
    );
  }
}
