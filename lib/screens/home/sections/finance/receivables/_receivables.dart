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
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';
import 'package:app/screens/home/sections/finance/receivables/widgets/receivables_bar.dart';
import 'package:app/screens/home/sections/finance/receivables/widgets/receivables_totals.dart';
import 'package:app/screens/modals/finance/record_payment/_record_payment.dart';

import './receivables_table.dart';

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
        ReceivablesTotals(totals: service.totals, currency: service.currency),
        SizedBox(height: AppSize.spaceXS),
        ReceivablesBar(
          openOnly: service.openOnly,
          onOpenOnly: service.showOpenOnly
        ),
        SizedBox(height: AppSize.spaceXS),
        Expanded(child: _body(context, service)),
        if (service.hasMore) SectionMoreButton(
          label: S.of(context).finance_more(moneyCount(context, service.total - service.sales.length)),
          retryLabel: S.of(context).finance_retry,
          failed: service.moreFailed,
          onMore: service.more,
          onRetry: service.retryMore
        )
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
