import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// What the amount modal hands back: the two things a typed-in line needs.
///
/// It is a class and not a pair of values because it travels through
/// `showModal`, which returns `dynamic`: the caller gets one thing it can check
/// the type of instead of unpacking a map whose keys nothing verifies.
class PosAmountEntry {
  const PosAmountEntry({required this.label, required this.price});

  /// What the line is called on the ticket.
  final String label;

  /// Unit price. Zero is allowed —something thrown in with the sale is still a
  /// line the ticket should show— and negative is not: a discount is not a
  /// charge, and pretending it is would make the total right and the ticket a
  /// lie.
  final double price;
}

/// Charges something the catalog does not have: a delivery, a repair, a fee, a
/// product that has not been imported yet.
///
/// It is two fields because that is what such a line is — what it is called and
/// what it costs. The quantity is not asked for: it starts at one and is moved
/// with the same +/− buttons every other line of the ticket has, so there is
/// only one place a quantity is changed.
///
/// **It returns a [PosAmountEntry] and writes nothing.** The ticket's service
/// (`PosCartService`) is provided by the POS page, which lives *under* the
/// navigator this modal is opened on, so it is not in scope here — the panel
/// that opened it is the one holding it. That is the shape the modals module
/// asks for anyway: a modal returns a value and the caller decides.
class PosAmountModal extends StatefulWidget {
  const PosAmountModal({super.key, required this.currency});

  /// The currency the company charges with. It is only used to read what was
  /// typed —`12,50` and `12.50` are the same amount to
  /// [CurrencyModel.parse]— and to say in the field's label which money this
  /// price is in.
  final CurrencyModel currency;

  @override
  State<PosAmountModal> createState() => _PosAmountModalState();
}

class _PosAmountModalState extends State<PosAmountModal> {
  final _form = FormController();

  /// Same width as the rest of the single-purpose modals: the dialog measures
  /// its content, and two short fields would leave it narrower than its button.
  static const double _width = 400;

  /// Longest concept. It is a line on a ticket, not a description.
  static const int _maxLabel = 60;

  late final _label = InputController(
    key: "LABEL",
    form: _form,
    max: _maxLabel,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(
        S.of(context).pos_amount_concept
      ),
      InputError.long: S.of(context).form_long_ma(
        S.of(context).pos_amount_concept
      )
    }
  );

  /// The price. Both separators are accepted because whoever is at the counter
  /// types the one their currency uses, and [CurrencyModel.parse] reads either.
  ///
  /// **It is a text field and not an [InputType.numeric] one**, which is what it
  /// looks like it should be: core forces `digitsOnly` on numeric fields, so a
  /// price typed `12,50` arrives as `1250` — the separator is swallowed and the
  /// charge is a hundred times what was meant. Numeric there means whole units
  /// (the stock quantity field is the case it was written for). What keeps
  /// letters out here is the pattern, which the text validator enforces on every
  /// key. The counter is desktop-only, so no phone keyboard is lost by it.
  late final _price = InputController(
    key: "PRICE",
    form: _form,
    pattern: "[0-9.,]",
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).pos_amount_price_error,
      InputError.invalid: S.of(context).pos_amount_price_error
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
              S.of(context).pos_amount_subtitle,
              lines: 2,
              color: scheme.text.secondary
            )
          ),
          Input(
            title: S.of(context).pos_amount_concept,
            placeholder: S.of(context).pos_amount_concept_placeholder,
            controller: _label,
            leftIcon: Icon(CI.receipt, color: scheme.icon),
            autofocus: true,
            next: _price.focus
          ),
          Input(
            title: S.of(context).pos_amount_price,
            // The placeholder carries the symbol —`$0`, `0€`— because it is the
            // only thing on the form that says which money is being typed, and
            // the counter charges in exactly one.
            placeholder: widget.currency.write(
              S.of(context).pos_amount_price_placeholder
            ),
            controller: _price,
            leftIcon: Icon(CI.wallet, color: scheme.icon),
            onSubmit: _submit
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).pos_amount_add, action: _submit)
        ]
      )
    );
  }

  /// Reads both fields and closes with the line, or leaves the wrong one in red.
  ///
  /// The concept is checked through its controller and the price by hand: the
  /// field's own validator only knows the pattern, and `,,` passes a pattern of
  /// digits and separators without being a number. What it does buy is that the
  /// error clears itself on the next key, so nothing has to listen for that.
  void _submit() {
    if (!_label.validate(_label)) return;

    final price = CurrencyModel.parse(_price.text.trim());

    if (price == null || price < 0) {
      _price.status.setStatus(
        InputStatus.error,
        _price.text.trim().isEmpty ? InputError.empty : InputError.invalid
      );
      _price.focus.requestFocus();

      return;
    }

    _price.status.setStatus(InputStatus.valid, null);

    Navigator.pop(context, PosAmountEntry(
      label: _label.text.trim(),
      price: price
    ));
  }
}
