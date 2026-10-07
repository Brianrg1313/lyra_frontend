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
import 'package:app/screens/home/sections/_section/section_message.dart';

import './summary_footer.dart';
import './summary_header.dart';
import './summary_layout.dart';
import './summary_product_row.dart';

/// What's seen below the bar, depending on how the read came out.
class SummaryBody extends StatelessWidget {
  const SummaryBody({super.key});

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
  ///
  /// It's measured on the list's width, so the header and every row leave out the
  /// same columns when they don't all fit (see [SummaryLayout.of]).
  Widget _list(BuildContext context, StockSummaryService service) {
    final currency = _currency(context);
    final rows = service.rows;

    return Padding(
      padding: EdgeInsets.only(left: AppSize.padding, right: AppSize.spaceXS),
      child: LayoutBuilder(builder: (context, constraints) {
        final layout = SummaryLayout.of(
          context,
          service.columns,
          width: constraints.maxWidth - SummaryLayout.rowPadding.horizontal
        );

        return Column(children: [
          SizedBox(
            height: SummaryLayout.headerHeight,
            child: Column(children: [
              Expanded(child: SummaryHeader(
                layout: layout,
                sort: service.sort,
                onSort: service.sortBy
              )),
              Separator.horizontal()
            ])
          ),
          Expanded(child: ListView.builder(
            itemCount: rows.length + 1,
            itemBuilder: (context, index) {
              if (index == rows.length) return SummaryFooter(service: service);

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
        ]);
      })
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
