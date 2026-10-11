import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_payments_service.dart';
import 'package:app/services/money/money_receivables_service.dart';
import 'package:app/services/money/money_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';
import 'package:app/screens/home/sections/finance/payments/payment_filters/_payment_filters.dart';
import 'package:app/screens/home/sections/finance/payments/widgets/payments_bar.dart';
import 'package:app/screens/home/sections/finance/payments/widgets/payments_totals.dart';
import 'package:app/screens/modals/finance/record_payment/_record_payment.dart';

import './payments_table.dart';

/// Payments tab: everything the company received and everything it paid, one
/// movement per row.
///
/// **A sale's own payment is not here.** The ticket already is that record, so
/// what this list holds is the money around it —a supplier paid on Friday, a
/// customer settling their tab— which is also the only money that is recorded
/// by hand. The overview adds this list and the register's takings; this is one
/// of the two halves.
///
/// Recording and voiding both live here because both are writes against this
/// list, and both end by rereading it: the totals belong to the whole filter,
/// which is a number only the backend has. A void also gives a settled ticket
/// its debt back, so the receivables are reread with it.
class FinancePaymentsTab extends StatefulWidget {
  const FinancePaymentsTab({super.key});

  @override
  State<FinancePaymentsTab> createState() => _FinancePaymentsTabState();
}

class _FinancePaymentsTabState extends State<FinancePaymentsTab> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because both loads notify their service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<MoneyPaymentsService>().load();

      // The catalog is what the filters and the record panel are drawn from. It
      // is read here and not by the panel so the concept and method filters are
      // already populated when somebody reaches for them.
      context.read<MoneyCatalogService>().load();

      // The company's accounts are one of the panel's fields —which of them the
      // money landed in— and this tab may be the first one opened. Both reads
      // do nothing when whoever got here first already made them. Where the
      // accounts tab isn't there yet (a master), there are none to name.
      if (FinanceTab.methods.isShown) context.read<MoneyMethodsService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyPaymentsService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentsBar(onRecord: _record),
        SizedBox(height: AppSize.spaceXS),
        // The filters stay in view through every state, the empty one included:
        // an empty list is very often a filter that matched nothing, and hiding
        // the controls would leave no way back but a reload.
        const PaymentFilters(),
        SizedBox(height: AppSize.spaceXS),
        // The company's currency and not the rows': the totals are the
        // filter's, so they are there before any row is and stay when the
        // filter matches none. Every amount in this list is stamped in it —
        // nothing is ever converted — so it is the right one for both.
        PaymentsTotals(
          totals: service.totals,
          currency: context.select<BusinessService, String>(
            (business) => business.currencyCode
          )
        ),
        SizedBox(height: AppSize.spaceXS),
        Expanded(child: _body(context, service)),
        if (service.hasMore) SectionMoreButton(
          label: S.of(context).finance_more(moneyCount(context, service.total - service.payments.length)),
          retryLabel: S.of(context).finance_retry,
          failed: service.moreFailed,
          onMore: service.more,
          onRetry: service.retryMore
        )
      ]
    );
  }

  Widget _body(BuildContext context, MoneyPaymentsService service) =>
    switch (service.status) {
      MoneyPaymentsStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).finance_payments_error_title,
        subtitle: S.of(context).finance_payments_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).finance_retry
      ),
      // A filter that matched nothing and a company that has recorded nothing
      // are different answers and get different copy: the first one has a way
      // out, which is clearing the filter.
      MoneyPaymentsStatus.empty => service.isFiltered
        ? SectionMessage(
            icon: CI.search,
            title: S.of(context).finance_payments_none_title,
            subtitle: S.of(context).finance_payments_none_subtitle,
            action: service.clearFilters,
            actionLabel: S.of(context).finance_payments_clear
          )
        : SectionMessage(
            icon: CI.receipt,
            title: S.of(context).finance_payments_empty_title,
            subtitle: S.of(context).finance_payments_empty_subtitle,
            action: _record,
            actionLabel: S.of(context).finance_payments_record,
            actionIcon: CI.plus
          ),
      MoneyPaymentsStatus.ready => PaymentsTable(
        payments: service.payments,
        onVoid: _annul
      ),
      _ => const Center(child: Loading())
    };

  /// Opens the panel that records a movement, and writes what it hands back.
  ///
  /// The panel is opened on a navigator the section's services are not in scope
  /// of, so it builds a request body and this tab is what writes it — which is
  /// also the shape the modals module asks for. The vocabularies are handed in
  /// for the same reason, already read (see [initState]).
  Future<void> _record() async {
    final request = await showRecordPayment(
      context,
      concepts: _concepts,
      settlements: context.read<MoneyCatalogService>().settlements,
      accounts: context.read<MoneyMethodsService>().usable,
      currency: context.read<BusinessService>().currency
    );

    if (request == null || !mounted) return;

    final recorded = await context
      .read<MoneyPaymentsService>()
      .record(context, request: request);

    if (!recorded || !mounted) return;

    // A recorded settlement pays a credit ticket down, and the summary of the
    // window it landed in is no longer what it says. Neither can be worked out
    // from here, so both are asked again.
    context.read<MoneyService>().retry();
    context.read<MoneyReceivablesService>().refresh();
  }

  /// Both halves of the concept catalog, in one list: the concept is what
  /// decides which way the money went, so the panel offers them together.
  List<MoneyConcept> get _concepts {
    final catalog = context.read<MoneyCatalogService>();

    return [...catalog.incoming, ...catalog.outgoing];
  }

  /// Annuls a movement, after asking.
  ///
  /// It is a destructive confirmation, so it is [showAlertModal] and not a
  /// modal of its own — and the reason the backend accepts is not asked for
  /// here: a void from a table is somebody undoing what they just typed, and a
  /// panel with a text field would turn one gesture into a form.
  Future<void> _annul(MoneyPayment payment) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).finance_payment_void_title,
      message: S.of(context).finance_payment_void_message(
        moneyLabel(payment.amount, payment.currency)
      ),
      confirmText: S.of(context).finance_payment_void,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    final voided = await context
      .read<MoneyPaymentsService>()
      .annul(context, id: payment.id);

    if (!voided || !mounted) return;

    // Voiding a settlement gives its ticket the debt back, and it comes off the
    // window's figures either way.
    context.read<MoneyService>().retry();
    context.read<MoneyReceivablesService>().refresh();
  }
}
