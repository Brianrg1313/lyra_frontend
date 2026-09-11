import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';

import '../sticky_bar.dart';
import 'summary_layout.dart';
import 'summary_row.dart';

/// The stock summary: the bottom half of the inventory section.
///
/// Up top are the tables —what the company has— and here below what's inside
/// the one that matters: its products, with the photo, the columns it chose to
/// show and what's left of each one. They're two different reads of the same
/// thing and that's why they coexist on one screen: entering a table to see if
/// there's stock left is a round trip almost nobody wants to make.
///
/// **The table isn't chosen.** The backend answers for the company's primary
/// (see [StockSummaryService]), so this panel receives no id nor depends on
/// something being selected up top.
///
/// **You touch here and not in the table.** Each row's two numbers carry their
/// buttons (see `SummaryStepper`): six came in, two were sold, three have to be
/// set aside. Tapping the row opens nothing, which was the old gesture and left
/// every movement one pixel away from going to another screen.
///
/// It's a strip of slivers and not a widget with its own scroll: the whole
/// section scrolls together, with the tables grid measuring what it needs up
/// top and the summary continuing on below. A scroll inside another would leave
/// a short list trapped in a little window in the middle of the screen.
///
/// The only thing that doesn't scroll with the rest is the column header, which
/// stays stuck at the top while there are rows below it and lets go when the
/// summary ends (see [StickyBar]).
class StockSummarySection extends StatelessWidget {
  const StockSummarySection({super.key});

  /// How many rows before the end the next stretch is requested. Enough for the
  /// page to arrive while still scrolling down, without asking for it when
  /// seeing the first row.
  static const int _lookahead = 5;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StockSummaryService>();

    // Without tables there's no summary, and there's also nothing to announce:
    // the list above is already offering to create the first one.
    if (service.status == StockSummaryStatus.missing) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(child: _Title(
        total: service.total,
        loading: service.status == StockSummaryStatus.loading
      )),
      ..._body(context, service)
    ]);
  }

  /// What's seen below the title, depending on how the read came out.
  List<Widget> _body(BuildContext context, StockSummaryService service) =>
    switch (service.status) {
      StockSummaryStatus.idle || StockSummaryStatus.loading => [
        SliverToBoxAdapter(child: SizedBox(
          height: SummaryLayout.rowHeight * 3,
          child: const Center(child: Loading())
        ))
      ],
      StockSummaryStatus.error => [
        SliverToBoxAdapter(child: SizedBox(
          height: SummaryLayout.rowHeight * 4,
          child: SectionMessage(
            icon: CI.info,
            title: S.of(context).stock_summary_error_title,
            subtitle: S.of(context).stock_summary_error_subtitle,
            action: service.retry,
            actionLabel: S.of(context).stock_summary_retry
          )
        ))
      ],
      StockSummaryStatus.empty => [
        SliverToBoxAdapter(child: SizedBox(
          height: SummaryLayout.rowHeight * 4,
          child: SectionMessage(
            icon: service.isSearching ? CI.search : CI.shop,
            title: service.isSearching
              ? S.of(context).stock_summary_search_empty
              : S.of(context).stock_summary_empty_title,
            subtitle: service.isSearching
              ? null
              : S.of(context).stock_summary_empty_subtitle
          )
        ))
      ],
      StockSummaryStatus.ready => _list(context, service),
      // It's not reached: the whole section already went blank above. This
      // branch exists because the state is part of the type and leaving it out
      // would be trusting that `if` never moves.
      StockSummaryStatus.missing => const []
    };

  /// The list itself: the column header and the rows read.
  ///
  /// The column distribution is computed once and goes down to all rows: it's
  /// the same for the header and for each product, and recomputing it per row
  /// would be repeating the same count hundreds of times per frame.
  List<Widget> _list(BuildContext context, StockSummaryService service) {
    final layout = SummaryLayout.of(context, service.columns);
    final currency = _currency(context);
    final rows = service.rows;

    return [
      // The header stays at the top while there are rows below it: on row forty
      // a column of numbers says nothing without the title that says which is
      // which, and going back to look for it up top is losing the row being
      // read. It leaves with the whole summary when the summary ends, not
      // before.
      StickyBar(
        pinned: true,
        height: SummaryLayout.headerHeight,
        child: Column(children: [
          Expanded(child: SummaryHeader(layout: layout)),
          Separator.horizontal()
        ])
      ),
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
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
      ),
      SliverToBoxAdapter(child: _Footer(service: service))
    ];
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

/// The row that separates the tables from the summary: what it's called and
/// how many products it has.
class _Title extends StatelessWidget {
  const _Title({required this.total, required this.loading});

  final int total;

  /// While reading, how many there are isn't said: during a search the previous
  /// number would still be there counting something else.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceM, bottom: AppSize.spaceXS),
      child: Row(children: [
        Expanded(child: TextMedium(
          S.of(context).stock_summary_title,
          bold: true,
          ellipsis: true
        )),
        if (!loading) ...[
          SizedBox(width: AppSize.gap),
          TextSmall(
            S.of(context).stock_summary_count(total),
            color: scheme.text.secondary
          )
        ]
      ])
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
