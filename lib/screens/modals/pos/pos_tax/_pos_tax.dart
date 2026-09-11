import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Sets the tax percentage charged on the ticket being rung up.
///
/// **The rate is not in the data.** Neither the business profile nor `/pos/`
/// carries one today, so it is set at the counter and starts at zero (see
/// [PosInvoiceService]); when the backend has a rate of its own, this modal is what
/// stops being the only way to change it, not what changes.
///
/// It is a percentage the way the checkout endpoint takes it —`16`, never
/// `0.16`— which is also how it reads on a ticket, so there is no conversion
/// hiding between what is typed and what is charged.
///
/// It closes returning the rate as a `double`, and nothing when it is
/// dismissed. Like the amount modal, it writes to no service: the ticket is
/// provided by the POS page, below the navigator this is opened on.
class PosTaxModal extends StatefulWidget {
  const PosTaxModal({super.key, required this.rate});

  /// What is being charged right now, so the field opens on it instead of
  /// empty: most of the time the rate is corrected, not written from nothing.
  final double rate;

  @override
  State<PosTaxModal> createState() => _PosTaxModalState();
}

class _PosTaxModalState extends State<PosTaxModal> {
  final _form = FormController();

  static const double _width = 400;

  /// The rate as it goes in the field: `16` and not `16.0`, because a whole
  /// percentage is what almost every one of them is and the trailing zero is
  /// noise somebody has to delete before typing.
  String get _initial {
    final rate = widget.rate;

    return rate == rate.roundToDouble()
      ? rate.toStringAsFixed(0)
      : rate.toString();
  }

  /// Half-point rates exist, so the separators are accepted here for the same
  /// reason they are on a price — and, for the same reason, this is **not** an
  /// [InputType.numeric] field: core forces `digitsOnly` on those, which would
  /// turn a rate of `8,5` into `85`. See the note in `PosAmountModal`.
  late final _rate = InputController(
    key: "TAX",
    form: _form,
    initial: _initial,
    pattern: "[0-9.,]",
    customErrors: {
      InputError.empty: S.of(context).pos_tax_error,
      InputError.invalid: S.of(context).pos_tax_error
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
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextMedium(
              S.of(context).pos_tax_subtitle,
              lines: 2,
              color: scheme.text.secondary
            )
          ),
          Input(
            title: S.of(context).pos_tax_input,
            placeholder: S.of(context).pos_tax_placeholder,
            controller: _rate,
            leftIcon: Icon(CI.discount, color: scheme.icon),
            autofocus: true,
            onSubmit: _submit
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).save, action: _submit)
        ]
      )
    );
  }

  /// Reads the rate and closes with it.
  ///
  /// The empty field is **zero and not an error**: emptying the box is how a
  /// counter stops charging tax, and making that the one thing it cannot say
  /// would send whoever does not charge VAT looking for a switch that is not
  /// there.
  void _submit() {
    final written = _rate.text.trim();

    if (written.isEmpty) {
      Navigator.pop(context, 0.0);
      return;
    }

    final rate = CurrencyModel.parse(written);

    if (rate == null || rate < 0 || rate > PosInvoiceService.maxTax) {
      _rate.status.setStatus(InputStatus.error, InputError.invalid);
      _rate.focus.requestFocus();

      return;
    }

    _rate.status.setStatus(InputStatus.valid, null);

    Navigator.pop(context, rate);
  }
}
