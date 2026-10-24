import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_methods_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './form_section.dart';

/// Which of the company's payment accounts whoever carries this delivery takes
/// when the order arrives, one check per account.
///
/// **Per delivery and not per account**: the company's riders may take cash and
/// a Pago Movil at the door while the app's take only cash, so the same account
/// is a yes for one and a no for the other. None checked is a delivery paid
/// before it goes out.
///
/// The accounts are their own read ([accounts]): failing to get them takes
/// this part down and nothing else, and the form then leaves the saved list as
/// it was. Adding one is a whole other sheet, so with none it says where.
class DeliveryDoorMethodsField extends StatelessWidget {
  const DeliveryDoorMethodsField({
    super.key,
    required this.accounts,
    required this.selected,
    required this.onToggle
  });

  final MoneyMethodsService accounts;
  final Set<String> selected;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: accounts,
      builder: (context, _) => FormSection(
        title: S.of(context).business_delivery_on_delivery,
        note: S.of(context).business_delivery_on_delivery_note,
        child: switch (accounts.status) {
          MoneyMethodsStatus.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, method) in accounts.methods.indexed) ...[
                if (index > 0) SizedBox(height: AppSize.gap),
                SettingsToggle(
                  value: selected.contains(method.id),
                  label: method.title,
                  // The institution and the number: what tells two accounts of
                  // the same rail apart.
                  message: method.subtitle.isEmpty ? null : method.subtitle,
                  toggle: () => onToggle(method.id)
                )
              ]
            ]
          ),
          MoneyMethodsStatus.empty => _Note(text: S.of(context).business_delivery_on_delivery_empty),
          MoneyMethodsStatus.error || MoneyMethodsStatus.locked => _Note(
            text: S.of(context).business_delivery_on_delivery_error,
            action: accounts.retry
          ),
          _ => const Align(alignment: Alignment.centerLeft, child: Loading())
        }
      )
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.action});

  final String text;
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;

    return Row(children: [
      Expanded(child: TextSmall(text, lines: 3, color: ThemeColor.of(context).text.secondary)),
      if (action != null) ...[
        SizedBox(width: AppSize.gap),
        Button(title: S.of(context).finance_retry, action: action, width: null)
      ]
    ]);
  }
}
