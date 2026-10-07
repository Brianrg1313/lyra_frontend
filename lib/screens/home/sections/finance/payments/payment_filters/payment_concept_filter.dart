import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_payments_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';

/// The concept, out of the ones the open direction offers.
///
/// With both directions on screen the two lists are offered together: a concept
/// already says which way its money went, so picking one is also picking a
/// side, and forcing the direction first would be asking twice for the same
/// thing.
class PaymentConceptFilter extends StatelessWidget {
  const PaymentConceptFilter({super.key, required this.service, required this.catalog});

  final MoneyPaymentsService service;
  final MoneyCatalogService catalog;

  List<MoneyConcept> get _concepts => switch (service.direction) {
    null => [...catalog.incoming, ...catalog.outgoing],
    final direction => catalog.of(direction)
  };

  @override
  Widget build(BuildContext context) {
    final concepts = _concepts;
    final current = catalog.concept(service.concept);

    return SectionMenuChip(
      emptyText: S.of(context).finance_select_empty,
      icon: CI.list,
      title: current?.name ?? S.of(context).finance_payment_concept,
      isActive: service.concept.isNotEmpty,
      selected: service.concept,
      // Without the catalog there is nothing to pick from. It is left offered
      // and empty rather than hidden: a control that comes and goes as a read
      // lands is harder to read than one that says it has nothing.
      options: [
        SelectOption(
          value: "",
          placeholder: S.of(context).finance_payments_any
        ),
        for (final concept in concepts) SelectOption(
          value: concept.concept,
          placeholder: concept.name,
          icon: concept.direction.isIncoming ? CI.arrow_down : CI.arrow_top
        )
      ],
      onSelected: service.filterConcept
    );
  }
}
