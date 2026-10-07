import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_payments_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';

/// Which movements are listed: the ones that count, the annulled ones, or both.
///
/// It opens on the recorded ones and not on all of them because that is what
/// the figures are: a voided payment stays in the history saying what was
/// believed at the time, and mixing it in by default would make the list
/// disagree with its own totals.
class PaymentStateFilter extends StatelessWidget {
  const PaymentStateFilter({super.key, required this.service});

  final MoneyPaymentsService service;

  /// The backend's `all`, which has no [MoneyPaymentStatus] of its own. It is
  /// spelled here and not in the enum because it is a filter and never the
  /// state of a payment.
  static const String _all = "all";

  @override
  Widget build(BuildContext context) => SectionMenuChip(
    emptyText: S.of(context).finance_select_empty,
    icon: CI.eye,
    title: switch (service.state) {
      MoneyPaymentStatus.recorded => S.of(context).finance_payments_recorded,
      MoneyPaymentStatus.voided => S.of(context).finance_payments_voided,
      null => S.of(context).finance_payments_any_state
    },
    isActive: service.state != MoneyPaymentStatus.recorded,
    selected: service.state?.value ?? _all,
    options: [
      SelectOption(
        value: MoneyPaymentStatus.recorded.value,
        placeholder: S.of(context).finance_payments_recorded
      ),
      SelectOption(
        value: MoneyPaymentStatus.voided.value,
        placeholder: S.of(context).finance_payments_voided
      ),
      SelectOption(
        value: _all,
        placeholder: S.of(context).finance_payments_any_state
      )
    ],
    onSelected: (value) => service.filterState(
      value == _all ? null : MoneyPaymentStatus.from(value)
    )
  );
}
