import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_payments_service.dart';

// WIDGETS
import 'package:core/form.dart';

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
        _Chip(
          title: S.of(context).finance_payments_all,
          isActive: service.direction == null,
          action: () => service.filterDirection(null)
        ),
        _Chip(
          icon: CI.arrow_down,
          title: S.of(context).finance_payments_in,
          isActive: service.direction == MoneyDirection.incoming,
          action: () => service.filterDirection(MoneyDirection.incoming)
        ),
        _Chip(
          icon: CI.arrow_top,
          title: S.of(context).finance_payments_out,
          isActive: service.direction == MoneyDirection.outgoing,
          action: () => service.filterDirection(MoneyDirection.outgoing)
        ),
        _ConceptFilter(service: service, catalog: catalog),
        _MethodFilter(service: service, catalog: catalog),
        _StateFilter(service: service),
        if (service.isFiltered) _Chip(
          icon: CI.delete,
          title: S.of(context).finance_payments_clear,
          isActive: false,
          action: service.clearFilters
        )
      ]
    );
  }
}

/// The concept, out of the ones the open direction offers.
///
/// With both directions on screen the two lists are offered together: a concept
/// already says which way its money went, so picking one is also picking a
/// side, and forcing the direction first would be asking twice for the same
/// thing.
class _ConceptFilter extends StatelessWidget {
  const _ConceptFilter({required this.service, required this.catalog});

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

    return _MenuChip(
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

/// How the money moved: the settlement kinds, which is the same vocabulary the
/// counter's picker is drawn from.
class _MethodFilter extends StatelessWidget {
  const _MethodFilter({required this.service, required this.catalog});

  final MoneyPaymentsService service;
  final MoneyCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final current = service.method;

    return _MenuChip(
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

/// Which movements are listed: the ones that count, the annulled ones, or both.
///
/// It opens on the recorded ones and not on all of them because that is what
/// the figures are: a voided payment stays in the history saying what was
/// believed at the time, and mixing it in by default would make the list
/// disagree with its own totals.
class _StateFilter extends StatelessWidget {
  const _StateFilter({required this.service});

  final MoneyPaymentsService service;

  /// The backend's `all`, which has no [MoneyPaymentStatus] of its own. It is
  /// spelled here and not in the enum because it is a filter and never the
  /// state of a payment.
  static const String _all = "all";

  @override
  Widget build(BuildContext context) => _MenuChip(
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

/// A chip that opens its list anchored to itself.
///
/// It is [showSelectMenu] and not a [SelectInput] on purpose: an input would
/// need a controller of its own —created, rebuilt when the options change and
/// disposed— to hold a value this bar already reads off the service.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.selected,
    required this.options,
    required this.onSelected
  });

  final IconData icon;
  final String title;
  final bool isActive;

  /// The value currently on, so the open list shows its tick.
  final String selected;

  final List<SelectOption> options;
  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context) => _Chip(
    icon: icon,
    title: title,
    isActive: isActive,
    trailing: CI.arrow_down,
    action: () async {
      final option = await showSelectMenu(
        context: context,
        options: options,
        selected: selected,
        emptyText: S.of(context).finance_select_empty
      );

      if (option != null) onSelected(option.value);
    }
  );
}

/// One control of the bar. The active ones are filled with the line colour, the
/// same as the summary's range picker: the table below is where the colour that
/// means something lives.
class _Chip extends StatelessWidget {
  const _Chip({
    this.icon,
    required this.title,
    required this.isActive,
    required this.action,
    this.trailing
  });

  final IconData? icon;
  final String title;
  final bool isActive;
  final void Function() action;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = isActive ? scheme.text.primary : scheme.text.secondary;

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: title,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.line : scheme.surfaceOver,
      feedbackColor: scheme.lineOver,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSize.text, color: color),
            SizedBox(width: AppSize.gap)
          ],
          TextMedium(title, bold: isActive, multiplier: 0.9, color: color),
          if (trailing != null) ...[
            SizedBox(width: AppSize.gap),
            Icon(trailing, size: AppSize.text * 0.8, color: color)
          ]
        ]
      )
    );
  }
}
