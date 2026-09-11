import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/money/money_payments_service.dart';
import 'package:app/services/money/money_receivable_model.dart';
import 'package:app/services/money/money_receivables_service.dart';
import 'package:app/services/money/money_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/finance/record_payment/_record_payment.dart';

import '../money_format.dart';
import 'receivables_table.dart';

/// Receivables tab: the tickets that went out on credit and have not been paid.
///
/// It is the other half of the overview's credit figure. That number says how
/// much left unpaid in a window; this list says **who owes it**, which is the
/// question somebody opens this tab to answer.
///
/// It shows only what is still owed unless asked otherwise: a list that opens
/// with every credit sale ever made buries the handful that matter. The window
/// filters by when the ticket was **sold**, and what has been collected against
/// it counts whenever it happened — a debt does not stop being owed because the
/// window moved.
///
/// Collecting is not a write of its own: the money arrives as a settlement
/// payment naming the ticket, which is the same record any other payment is, so
/// the row's action opens the same panel the payments tab does, already
/// pointing at that sale.
class FinanceReceivablesTab extends StatefulWidget {
  const FinanceReceivablesTab({super.key});

  @override
  State<FinanceReceivablesTab> createState() => _FinanceReceivablesTabState();
}

class _FinanceReceivablesTabState extends State<FinanceReceivablesTab> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because the loads notify their service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<MoneyReceivablesService>().load();

      // The record panel is drawn from these two, and from this tab it is one
      // tap away on every row. Both reads do nothing when whoever opened
      // another tab first already made them.
      context.read<MoneyCatalogService>().load();
      context.read<MoneyMethodsService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyReceivablesService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Totals(totals: service.totals, currency: service.currency),
        SizedBox(height: AppSize.spaceXS),
        _Bar(
          openOnly: service.openOnly,
          onOpenOnly: service.showOpenOnly
        ),
        SizedBox(height: AppSize.spaceXS),
        Expanded(child: _body(context, service)),
        if (service.hasMore) _More(service: service)
      ]
    );
  }

  Widget _body(BuildContext context, MoneyReceivablesService service) =>
    switch (service.status) {
      MoneyReceivablesStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).finance_receivables_error_title,
        subtitle: S.of(context).finance_receivables_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).finance_retry
      ),
      // Nobody owing anything is the good outcome, so it is not drawn as a
      // failure: it is what a shop that sells on credit and collects looks
      // like.
      MoneyReceivablesStatus.empty => SectionMessage(
        icon: CI.chack_circle,
        title: S.of(context).finance_receivables_empty_title,
        subtitle: S.of(context).finance_receivables_empty_subtitle
      ),
      MoneyReceivablesStatus.ready => ReceivablesTable(
        sales: service.sales,
        currency: service.currency,
        onCollect: _collect
      ),
      _ => const Center(child: Loading())
    };

  /// Records what a customer brought for one of their credit tickets.
  ///
  /// The panel opens on the settlement concept with the ticket already filled
  /// in: from this list the sale is not something to be looked up, it is the
  /// row that was tapped.
  Future<void> _collect(MoneyReceivable sale) async {
    final catalog = context.read<MoneyCatalogService>();

    final request = await showRecordPayment(
      context,
      concepts: [...catalog.incoming, ...catalog.outgoing],
      settlements: catalog.settlements,
      accounts: context.read<MoneyMethodsService>().methods,
      currency: context.read<BusinessService>().currency,
      ticket: sale.ticket,
      amount: sale.outstanding
    );

    if (request == null || !mounted) return;

    final recorded = await context
      .read<MoneyPaymentsService>()
      .record(context, request: request);

    if (!recorded || !mounted) return;

    // The debt this row shows just moved, and so did the money of the window
    // the payment landed in. Neither can be worked out from here.
    context.read<MoneyReceivablesService>().refresh();
    context.read<MoneyPaymentsService>().refresh();
    context.read<MoneyService>().retry();
  }
}

/// The three numbers the tab is opened for: how much was sold on credit, how
/// much of it has come in and how much is outstanding.
///
/// They are the filter's and not the page's, which is why they sit above the
/// list and not under it.
class _Totals extends StatelessWidget {
  const _Totals({required this.totals, required this.currency});

  final MoneyReceivableTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Wrap(
      spacing: AppSize.gap,
      runSpacing: AppSize.gap,
      children: [
        _Total(
          title: S.of(context).finance_receivables_sold,
          amount: moneyLabel(totals.sold, currency),
          color: scheme.text.primary
        ),
        _Total(
          title: S.of(context).finance_receivables_collected,
          amount: moneyLabel(totals.collected, currency),
          color: scheme.snackBar.success
        ),
        _Total(
          title: S.of(context).finance_receivables_outstanding,
          amount: moneyLabel(totals.outstanding, currency),
          color: scheme.snackBar.alert
        )
      ]
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.title,
    required this.amount,
    required this.color
  });

  final String title;
  final String amount;
  final Color color;

  /// A fixed width for the same reason as the summary cards: they are laid out
  /// in a [Wrap] and need a measure of their own to decide when to break.
  static const double _width = 190;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: _width,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextSmall(title, color: scheme.text.secondary, ellipsis: true),
            SizedBox(height: AppSize.gap),
            TextMedium(amount, bold: true, color: color, ellipsis: true)
          ]
        )
      )
    );
  }
}

/// The one control of the tab: whether the settled tickets are listed too.
class _Bar extends StatelessWidget {
  const _Bar({required this.openOnly, required this.onOpenOnly});

  final bool openOnly;
  final void Function(bool value) onOpenOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      FeedbackButton(
        action: () => onOpenOnly(!openOnly),
        height: AppSize.button,
        message: S.of(context).finance_receivables_open_only,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
        radius: AppSize.cornerInset(AppSize.gap),
        color: openOnly ? scheme.line : scheme.surfaceOver,
        feedbackColor: scheme.lineOver,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            openOnly ? CI.chekmark : CI.circle,
            size: AppSize.text,
            color: openOnly ? scheme.text.primary : scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(
            S.of(context).finance_receivables_open_only,
            bold: openOnly,
            multiplier: 0.9,
            color: openOnly ? scheme.text.primary : scheme.text.secondary
          )
        ])
      )
    ]);
  }
}

/// The end of the list: how many tickets are left and the button that brings
/// the next page. Same reasoning as the payments tab's — the table virtualizes
/// its rows and does not report where its scroll is.
class _More extends StatelessWidget {
  const _More({required this.service});

  final MoneyReceivablesService service;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSize.gap),
    child: Center(child: SizedBox(
      width: AppSize.action * 5,
      child: Button(
        title: service.moreFailed
          ? S.of(context).finance_retry
          : S.of(context).finance_more(
              moneyCount(context, service.total - service.sales.length)
            ),
        action: service.moreFailed ? service.retryMore : service.more
      )
    ))
  );
}
