import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/pos/pos_payment_method.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// How a ticket was paid, as this modal answers it.
class PosCheckoutEntry {
  const PosCheckoutEntry({required this.method, this.reference = ""});

  /// The backend's code for the method (`cash`, `transfer`), never its name:
  /// the name is what is read on screen and the code is what is stored on the
  /// sale.
  final String method;

  /// The payment's reference, empty on the methods that do not carry one.
  final String reference;
}

/// The last step of a sale: how the customer is paying it.
///
/// **It asks for the two things the backend cannot work out.** How it was paid
/// is the answer to "how much came in through the drawer and how much by
/// transfer", which is the first question anybody closing a register asks and
/// can only be asked if the method travelled with the sale. The reference is
/// the number the company writes down for the payments that have one — a
/// transfer's, a card terminal's authorization code — because a payment nobody
/// can find again cannot be reconciled with the bank.
///
/// **The total is shown and not asked for.** The backend prices the invoice
/// from its own lines and refuses to take a figure from the client at all, so
/// what is drawn here is what will be charged, not something being confirmed.
///
/// The methods come in as a parameter and are not read from a service: this
/// opens on the navigator, which is above the POS page that provides them.
///
/// It closes returning a [PosCheckoutEntry], and nothing when it is dismissed.
class PosCheckoutModal extends StatefulWidget {
  const PosCheckoutModal({
    super.key,
    required this.methods,
    required this.currency,
    required this.total
  });

  /// The accepted methods, in the backend's order. Never empty: the footer does
  /// not open this without them.
  final List<PosPaymentMethod> methods;

  final CurrencyModel currency;

  /// What the ticket comes to. It is the counter's figure — the backend
  /// computes its own from the lines — and they are the same number, because
  /// every line on the screen is one the backend answered with.
  final double total;

  @override
  State<PosCheckoutModal> createState() => _PosCheckoutModalState();
}

class _PosCheckoutModalState extends State<PosCheckoutModal> {
  final _form = FormController();

  static const double _width = 420;

  /// What is chosen right now. It is kept as the whole method and not as its
  /// code because what the modal does next depends on its flags — whether to
  /// ask for a reference at all.
  late PosPaymentMethod _method = widget.methods.firstWhere(
    (method) => method.isDefault,
    orElse: () => widget.methods.first
  );

  late final _picker = InputController.select(
    key: "METHOD",
    form: _form,
    initial: _method.method,
    obligatory: true
  );

  late final _reference = InputController(
    key: "REFERENCE",
    form: _form,
    customErrors: {
      InputError.empty: S.of(context).pos_checkout_reference_error,
      InputError.invalid: S.of(context).pos_checkout_reference_error
    }
  );

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
          // The amount opens the modal because it is what is being agreed: the
          // method below it is how, and this is how much.
          Surface.over(
            radius: AppSize.cornerInset(AppSize.gap),
            padding: EdgeInsets.all(AppSize.padding),
            child: Row(children: [
              Expanded(child: TextSmall(
                S.of(context).pos_checkout_total,
                ellipsis: true,
                color: scheme.text.secondary
              )),
              SizedBox(width: AppSize.gap),
              Flexible(child: TextMedium(
                _amount,
                bold: true,
                multiplier: 1.25,
                ellipsis: true,
                textAlign: TextAlign.right
              ))
            ])
          ),
          SizedBox(height: AppSize.spaceM),
          SelectInput(
            title: S.of(context).pos_checkout_method,
            controller: _picker,
            options: [
              for (final method in widget.methods)
                SelectOption(value: method.method, placeholder: method.name)
            ],
            placeholder: S.of(context).pos_checkout_method_placeholder,
            emptyText: S.of(context).pos_checkout_method_empty,
            // Eleven fixed options with names two words long: a search box over
            // them would be a control nobody types into.
            searchable: false,
            leftIcon: Icon(CI.wallet, color: scheme.icon),
            onSelected: _pick
          ),
          // Only for the methods that carry one. A reference box next to cash is
          // a field whoever is at the counter has to learn to ignore.
          if (_method.reference) ...[
            SizedBox(height: AppSize.gap),
            Input(
              title: S.of(context).pos_checkout_reference,
              placeholder: S.of(context).pos_checkout_reference_placeholder,
              controller: _reference,
              leftIcon: Icon(CI.qr_code, color: scheme.icon),
              autofocus: true,
              onSubmit: _submit
            )
          ],
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).pos_checkout_confirm, action: _submit)
        ]
      )
    );
  }

  /// The total, written the way the company charging it writes it.
  String get _amount {
    final written = widget.total.toStringAsFixed(widget.currency.decimals);

    return widget.currency.label(written) ?? written;
  }

  void _pick(SelectOption option) {
    final method = widget.methods.firstWhere(
      (entry) => entry.method == option.value,
      orElse: () => _method
    );

    if (method.method == _method.method) return;

    setState(() => _method = method);
  }

  /// Closes with what was chosen.
  ///
  /// The reference is **required** on the methods that carry one and not merely
  /// offered: it is the only thing that ties the sale to the movement in the
  /// bank, and a transfer registered without it is one nobody can match at
  /// closing time.
  void _submit() {
    final reference = _reference.text.trim();

    if (_method.reference && reference.isEmpty) {
      _reference.status.setStatus(InputStatus.error, InputError.empty);
      _reference.focus.requestFocus();

      return;
    }

    Navigator.pop(context, PosCheckoutEntry(
      method: _method.method,
      reference: _method.reference ? reference : ""
    ));
  }
}
