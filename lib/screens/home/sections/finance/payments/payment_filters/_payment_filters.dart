import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_payments_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/filter_chip.dart';

import './payment_concept_filter.dart';
import './payment_method_filter.dart';
import './payment_state_filter.dart';

/// What narrows the history.
///
/// **Every filter is the service's and travels to the backend**, none of them
/// is applied over the rows already read: the response answers what the whole
/// filter adds up to, and a total computed over the page on screen would be a
/// different —and almost always smaller— number than the one the question was
/// about.
///
/// The direction is a pair of chips and not a dropdown because it is the cut
/// the screen is really made of: received on one side, paid on the other, and
/// it is what decides which concepts are even offered. The other three are
/// dropdowns anchored to their own chip, which keeps the bar to one line and
/// avoids four select controllers to dispose of.
class PaymentFilters extends StatelessWidget {
  const PaymentFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyPaymentsService>();
    final catalog = context.watch<MoneyCatalogService>();

    return Wrap(
      spacing: AppSize.gap,
      runSpacing: AppSize.gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SectionFilterChip(
          title: S.of(context).finance_payments_all,
          isActive: service.direction == null,
          action: () => service.filterDirection(null)
        ),
        SectionFilterChip(
          icon: CI.arrow_down,
          title: S.of(context).finance_payments_in,
          isActive: service.direction == MoneyDirection.incoming,
          action: () => service.filterDirection(MoneyDirection.incoming)
        ),
        SectionFilterChip(
          icon: CI.arrow_top,
          title: S.of(context).finance_payments_out,
          isActive: service.direction == MoneyDirection.outgoing,
          action: () => service.filterDirection(MoneyDirection.outgoing)
        ),
        PaymentConceptFilter(service: service, catalog: catalog),
        PaymentMethodFilter(service: service, catalog: catalog),
        PaymentStateFilter(service: service),
        if (service.isFiltered) SectionFilterChip(
          icon: CI.delete,
          title: S.of(context).finance_payments_clear,
          isActive: false,
          action: service.clearFilters
        )
      ]
    );
  }
}
