import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/sales/sales_filters/_sales_filters.dart';
import 'package:app/screens/modals/sales/sale_detail/_sale_detail.dart';
import 'package:app/screens/modals/sales/sale_fulfillment/_sale_fulfillment.dart';

import './sales_table.dart';

/// One of the two lists of the sales page: the filter bar, the board and the
/// end of it.
///
/// Both tabs are this widget with a different [section]. They are the same
/// list —same endpoint, same columns, same service— split by the one rule that
/// says a sale is finished, so writing them as two screens would be writing the
/// same screen twice and watching the copies drift.
///
/// **The search is the header's.** There is one search box in the home and it
/// searches the section being looked at, so the board reads it rather than
/// growing one of its own ([HomeService.searchQuery]) — the same way the
/// listings one section over do. It matches the three things a sale is looked
/// up by when somebody has one in hand: the ticket code off a printed slip, the
/// customer, and who sold it.
///
/// **It narrows the rows that are here and does not travel.** Every other
/// filter on this screen is the backend's, because the backend can answer them;
/// there is no `SEARCH` on `GET /sales`, and a stage is measured on read, so
/// searching on that side would mean paging the whole section down. The bar
/// says what is being searched and the empty state points at "load more"
/// instead of claiming the sale does not exist.
///
/// **It keeps its own clock.** The column somebody actually scans is how long a
/// sale has been standing where it is, and that number goes stale by simply
/// being looked at: a board opened at nine that still says "hace 2 minutos" at
/// half past is worse than one that says nothing, because it is confidently
/// wrong. So the tree is rebuilt once a minute, which is the resolution the
/// label is written at anyway (`saleWaitLabel` in `sale_format.dart`). It costs
/// a rebuild of rows that are already virtualized and it asks the backend for
/// nothing.
class SalesBoard extends StatefulWidget {
  const SalesBoard({super.key, required this.section});

  /// Which of the two lists this is.
  final SaleSection section;

  @override
  State<SalesBoard> createState() => _SalesBoardState();
}

class _SalesBoardState extends State<SalesBoard> {
  /// How often the waits are redrawn. It is the smallest step the label has, so
  /// a shorter tick would repaint without changing a character.
  static const Duration _tick = Duration(minutes: 1);

  Timer? _clock;

  /// What was typed in the header, already normalized. Only the rows listen to
  /// it: typing must not rebuild the bar above them, and it asks the backend
  /// for nothing.
  late final ValueListenable<String> _query;

  @override
  void initState() {
    super.initState();

    _query = context.read<HomeService>().searchQuery;

    _clock = Timer.periodic(_tick, (_) {
      if (mounted) setState(() {});
    });

    // Deferred to the first frame because both reads notify their service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<SalesService>().open(widget.section);

      // The vocabulary the filter bar and the handover panel are drawn from.
      // It does nothing when the other tab already read it: it depends on
      // neither the company nor the section.
      context.read<SalesCatalogService>().load();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _clock = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SalesService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The count and the controls are one row (`SalesFilters`): two halves
        // of the same question, and a board is short of lines.
        const SalesFilters(),
        Expanded(child: _body(context, service)),
        // No count of what is left, unlike the money's: with a state filter on,
        // what is left is unknown here (the total counts the section and the
        // filter narrows the page), and a number that is right only half the
        // time is worse than none.
        if (service.hasMore) SectionMoreButton(
          label: S.of(context).sales_more,
          retryLabel: S.of(context).sales_retry,
          failed: service.moreFailed,
          onMore: service.more,
          onRetry: service.retryMore
        )
      ]
    );
  }

  Widget _body(BuildContext context, SalesService service) =>
    switch (service.status) {
      SalesStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).sales_error_title,
        subtitle: S.of(context).sales_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).sales_retry
      ),
      SalesStatus.empty => _empty(context, service),
      SalesStatus.ready => ValueListenableBuilder<String>(
        valueListenable: _query,
        builder: (context, query, _) => _rows(context, service, query)
      ),
      _ => const Center(child: Loading())
    };

  /// The board, narrowed to what was typed in the header.
  ///
  /// A search that matches nothing is not the same news as an empty section:
  /// the rows are there and the search is what is hiding them, and the sale
  /// somebody is looking for may be further down a list that is read a page at
  /// a time. So it says that, and does not offer to clear filters that are not
  /// what is filtering.
  Widget _rows(BuildContext context, SalesService service, String query) {
    final sales = _search(service.sales, query);

    if (sales.isEmpty) {
      return SectionMessage(
        icon: CI.search,
        title: S.of(context).sales_search_empty_title,
        subtitle: S.of(context).sales_search_empty_subtitle
      );
    }

    return SalesTable(
      sales: sales,
      catalog: context.watch<SalesCatalogService>(),
      onOpen: _open
    );
  }

  /// The three things a sale is looked up by. The code is the one somebody
  /// reads off a printed slip; the two names are what they have when there is
  /// no slip — a customer on the phone, a seller asking about their own
  /// morning.
  ///
  /// The query arrives trimmed and lowercased from [HomeService], so it is the
  /// row that is lowered here and nothing else.
  List<SaleModel> _search(List<SaleModel> sales, String query) {
    if (query.isEmpty) return sales;

    return sales.where((sale) =>
      sale.ticket.toLowerCase().contains(query) ||
      sale.customer.toLowerCase().contains(query) ||
      sale.seller.toLowerCase().contains(query)
    ).toList();
  }

  /// Nothing to show, which on this screen is three different pieces of news.
  ///
  /// A filter that matched nothing is the one with something to do about it, so
  /// it is the only one with a button. An empty `process` list is the good
  /// outcome —nothing is owed to anybody— and an empty `done` list is a company
  /// that has not finished a sale yet; neither is a failure and neither is
  /// drawn as one.
  Widget _empty(BuildContext context, SalesService service) {
    if (service.isFiltered) {
      return SectionMessage(
        icon: CI.search,
        title: S.of(context).sales_empty_filter_title,
        subtitle: S.of(context).sales_empty_filter_subtitle,
        action: service.clearFilters,
        actionLabel: S.of(context).sales_clear
      );
    }

    return widget.section == SaleSection.process
      ? SectionMessage(
          icon: CI.chack_circle,
          title: S.of(context).sales_empty_process_title,
          subtitle: S.of(context).sales_empty_process_subtitle
        )
      : SectionMessage(
          icon: CI.sale,
          title: S.of(context).sales_empty_done_title,
          subtitle: S.of(context).sales_empty_done_subtitle
        );
  }

  /// Opens one sale in full.
  ///
  /// The panel reads it for itself (`GET /sales/detail/:ID`) and writes
  /// nothing, so there is usually nothing to do when it closes: the board is
  /// live over the socket, and a movement on the sale that was open arrives the
  /// same way as any other. What it can come back with is a **request** — one
  /// of the two writes this screen makes, and neither is one the panel can make
  /// itself: `SalesService` is provided here, under the navigator the panel
  /// opens on.
  ///
  /// What follows opens after the panel has closed and not over it, which is
  /// why this waits: one panel at a time, and by then the sale it is about has
  /// just been read on screen.
  ///
  /// The catalog is handed over rather than read inside, for the same reason
  /// the handover panel takes its modes: a side modal opens on a navigator
  /// above this section's providers.
  Future<void> _open(SaleModel sale) async {
    final asked = await showSaleDetail(
      context,
      sale: sale,
      catalog: context.read<SalesCatalogService>()
    );

    if (asked == null || !mounted) return;

    switch (asked) {
      case SaleDetailRequest.approve:
        await _approve(sale);
      case SaleDetailRequest.fulfil:
        await _fulfil(sale);
    }
  }

  /// **Says the payment arrived**, which closes the sale.
  ///
  /// The customer says the money is sent —that is what puts the sale at "Pago
  /// por verificar"— and nothing in this platform can see a bank: the transfer
  /// happened somewhere else and the comprobante is a photo in a conversation.
  /// So a person looks at it on the panel and says so here.
  ///
  /// It is confirmed first, and the confirmation is not ceremony: this is the
  /// one action on the screen that states a fact about money nobody counted,
  /// and taking it back is another screen's job — the conversation is reopened
  /// from the bandeja. The wording is what it is going to claim.
  Future<void> _approve(SaleModel sale) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).sales_approve_title,
      message: S.of(context).sales_approve_message,
      confirmText: S.of(context).sales_approve_confirm,
      cancelText: S.of(context).sales_approve_cancel
    );

    if (!confirmed || !mounted) return;

    final approved = await context
      .read<SalesService>()
      .approve(context, sale: sale);

    if (!approved || !mounted) return;

    FloatFlag.of(context).message(S.of(context).sales_approve_done);
  }

  /// Records how a sale reached its customer. It is asked for from the sale's
  /// own panel: the board has no column of actions.
  ///
  /// The panel returns the body and writes nothing —it opens on a navigator
  /// this section's services are not in scope of— so the write is made here.
  /// Nothing is reread afterwards: the answer carries the sale with the
  /// stage it now reads as, and the service writes the row from it. If that
  /// stage moved it to the other list, the row leaves this one on its own.
  Future<void> _fulfil(SaleModel sale) async {
    final catalog = context.read<SalesCatalogService>();

    final request = await showSaleFulfillment(
      context,
      sale: sale,
      modes: catalog.handover
    );

    if (request == null || !mounted) return;

    final recorded = await context
      .read<SalesService>()
      .fulfil(context, request: request);

    if (!recorded || !mounted) return;

    FloatFlag.of(context).message(S.of(context).sales_handover_saved);
  }
}
