import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// What a person said arrived: everything ([amount] null) or only part of it.
typedef PaymentApproval = ({double? amount, String? currency});

/// Asks before **approving a payment** (`PUT /aries/v1/chats/stage`, `STAGE: paid`),
/// from the conversation desk and from the sales board.
///
/// An empty amount is "all of it arrived". An amount is only what came: short
/// of the total, the backend keeps it on the same ticket and asks the customer
/// for the rest. The currency is picked among the company's (main first, read
/// here: the modal opens above the section's providers); none picked = the
/// ticket's own.
///
/// Returns the approval and writes nothing (the caller's service does), or
/// `null` when it was closed without approving.
Future<PaymentApproval?> showApprovePayment(BuildContext context) {
  final profile = context.read<BusinessService>().profile;
  final currencies = profile == null
    ? const <String>[]
    : {if (profile.currency.isNotEmpty) profile.currency, ...profile.currencies}.toList();

  return showModal(
    context: context,
    title: S.of(context).payment_approve_title,
    builder: (context) => ApprovePaymentModal(currencies: currencies)
  ).then((value) => value is PaymentApproval ? value : null);
}

class ApprovePaymentModal extends StatefulWidget {
  const ApprovePaymentModal({super.key, this.currencies = const []});

  final List<String> currencies;

  @override
  State<ApprovePaymentModal> createState() => _ApprovePaymentModalState();
}

class _ApprovePaymentModalState extends State<ApprovePaymentModal> {
  final _form = FormController();

  late final _amount = InputController(
    key: "AMOUNT",
    form: _form,
    pattern: "[0-9.,]",
    max: 16
  );

  late final _currency = InputController.select(key: "CURRENCY", form: _form, initial: "");

  static const double _width = 400;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextSmall(S.of(context).payment_approve_message, color: scheme.text.secondary),
          SizedBox(height: AppSize.spaceM),
          Input(
            title: S.of(context).payment_approve_amount,
            placeholder: S.of(context).payment_approve_amount_hint,
            controller: _amount,
            onSubmit: _submit
          ),
          if (widget.currencies.length > 1) ...[
            SizedBox(height: AppSize.spaceS),
            SelectInput(
              title: S.of(context).payment_approve_currency,
              placeholder: S.of(context).payment_approve_currency_sale,
              controller: _currency,
              options: [
                SelectOption(value: "", placeholder: S.of(context).payment_approve_currency_sale),
                for (final code in widget.currencies) SelectOption(value: code, placeholder: code)
              ]
            )
          ],
          SizedBox(height: AppSize.spaceXS),
          TextSmall(S.of(context).payment_approve_partial, color: scheme.text.secondary),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).payment_approve_confirm, action: _submit)
        ]
      )
    );
  }

  void _submit() {
    final raw = _amount.value.trim();
    final amount = raw.isEmpty ? null : CurrencyModel.parse(raw);

    if (raw.isNotEmpty && (amount == null || amount <= 0)) {
      FloatFlag.of(context).alert(message: S.of(context).payment_approve_invalid);
      return;
    }

    final currency = _currency.value;

    Navigator.pop<PaymentApproval>(context, (
      amount: amount,
      currency: amount == null || currency.isEmpty ? null : currency
    ));
  }
}
