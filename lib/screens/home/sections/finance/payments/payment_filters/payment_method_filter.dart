import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_payments_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';

/// How the money moved: the settlement kinds, which is the same vocabulary the
/// counter's picker is drawn from.
class PaymentMethodFilter extends StatelessWidget {
  const PaymentMethodFilter({super.key, required this.service, required this.catalog});

  final MoneyPaymentsService service;
  final MoneyCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final current = service.method;

    return SectionMenuChip(
      emptyText: S.of(context).finance_select_empty,
      icon: CI.cashbox,
      title: _name(current) ?? S.of(context).finance_payment_method,
      isActive: current.isNotEmpty,
      selected: current,
      options: [
        SelectOption(
          value: "",
          placeholder: S.of(context).finance_payments_any
        ),
        for (final method in catalog.settlements) SelectOption(
          value: method.method,
          placeholder: method.name
        )
      ],
      onSelected: service.filterMethod
    );
  }

  String? _name(String code) {
    if (code.isEmpty) return null;

    for (final method in catalog.settlements) {
      if (method.method == code) return method.name;
    }

    return code;
  }
}
