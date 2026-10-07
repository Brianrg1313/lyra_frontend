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
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/finance/record_payment/_record_payment.dart';

import '../finance_tab.dart';
import '../money_format.dart';
import 'payment_filters.dart';
import 'payments_table.dart';

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
        _Bar(onRecord: _record),
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
        _Totals(
          totals: service.totals,
          currency: context.select<BusinessService, String>(
            (business) => business.currencyCode
          )
        ),
        SizedBox(height: AppSize.spaceXS),
        Expanded(child: _body(context, service)),
        if (service.hasMore) _More(service: service)
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
      accounts: context.read<MoneyMethodsService>().methods,
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

/// The one action of the tab, on its own line above the filters: everything
/// else here reads, and this is the only thing that writes.
class _Bar extends StatelessWidget {
  const _Bar({required this.onRecord});

  final void Function() onRecord;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Button(
        width: null,
        title: S.of(context).finance_payments_record,
        leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
        action: onRecord
      )
    ]
  );
}

/// What the whole filter adds up to, in each direction.
///
/// It is deliberately not the sum of the rows on screen: the list is one page
/// of a filter that can run into thousands of movements, and "cuanto llevo
/// pagado a proveedores este mes" is a question about the filter.
class _Totals extends StatelessWidget {
  const _Totals({required this.totals, required this.currency});

  final MoneyPaymentTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      _Total(
        icon: CI.arrow_down,
        label: S.of(context).finance_payments_in,
        value: totals.income.total,
        count: totals.income.count,
        currency: currency,
        color: scheme.snackBar.success
      ),
      SizedBox(width: AppSize.spaceM),
      _Total(
        icon: CI.arrow_top,
        label: S.of(context).finance_payments_out,
        value: totals.expense.total,
        count: totals.expense.count,
        currency: currency,
        color: scheme.snackBar.error
      )
    ]);
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.icon,
    required this.label,
    required this.value,
    required this.count,
    required this.currency,
    required this.color
  });

  final IconData icon;
  final String label;
  final double value;
  final int count;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: AppSize.text, color: color),
      SizedBox(width: AppSize.gap),
      TextSmall("$label:", color: scheme.text.secondary),
      SizedBox(width: AppSize.gap),
      TextMedium(
        moneyLabel(value, currency),
        bold: true,
        multiplier: 0.9,
        color: color
      ),
      SizedBox(width: AppSize.gap),
      TextSmall(
        "(${moneyCount(context, count)})",
        color: scheme.text.secondary,
        multiplier: 0.9
      )
    ]);
  }
}

/// The end of the list: how many movements are left and the button that brings
/// the next page.
///
/// It is a button and not an infinite scroll because the table virtualizes its
/// own rows and does not report where it is: asking for the next page as the
/// last row appears would mean reaching inside it for a scroll position it
/// deliberately does not hand out.
class _More extends StatelessWidget {
  const _More({required this.service});

  final MoneyPaymentsService service;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSize.gap),
    child: Center(child: SizedBox(
      width: AppSize.action * 5,
      child: Button(
        title: service.moreFailed
          ? S.of(context).finance_retry
          : S.of(context).finance_more(
              moneyCount(context, service.total - service.payments.length)
            ),
        action: service.moreFailed ? service.retryMore : service.more
      )
    ))
  );
}
