import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_payment_request.dart';
import 'package:app/services/pos/pos_payment_method.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Records money that moved, received or paid.
///
/// It **returns the request body and writes nothing**, which is what this
/// module asks of every modal and what it has to do anyway: the money services
/// are provided by the finance section, which lives *under* the navigator this
/// panel is opened on, so they are not in scope here. The caller holds them and
/// decides what to reread afterwards — a settlement moves a ticket's debt and
/// the window's figures too, and only the tab knows which lists are on screen.
///
/// For the same reason the vocabularies come in as parameters: whoever opens
/// this makes sure they are loaded, so the panel never has to draw a form that
/// is still waiting for its own options.
///
/// Returns `null` when it was closed without recording anything.
Future<Map<String, dynamic>?> showRecordPayment(
  BuildContext context, {
  required List<MoneyConcept> concepts,
  required List<PosPaymentMethod> settlements,
  required List<MoneyMethod> accounts,
  required CurrencyModel currency,
  String ticket = "",
  double? amount
}) => showSideModal(
  context: context,
  title: S.of(context).finance_record_title,
  builder: (context) => RecordPaymentModal(
    concepts: concepts,
    settlements: settlements,
    accounts: accounts,
    currency: currency,
    ticket: ticket,
    amount: amount
  )
).then((value) => value is Map<String, dynamic> ? value : null);

/// The panel itself.
///
/// **There is no direction control.** A payment is never told which way the
/// money went: its concept already says so —`supplier` is money out,
/// `settlement` is money in— so a toggle beside the concept would be a second
/// way of saying the same thing, and one that can contradict it. The concept
/// list is offered whole, with an arrow on each option, and picking one is
/// picking a side.
///
/// **The date is not asked for either.** The backend stamps the payment now
/// unless it is told otherwise, and the case a `DATE` exists for —a supplier
/// paid on Friday and typed in on Monday— needs a date picker this design
/// system does not have yet. It is left out rather than half-built: a text
/// field for a date is how two people end up entering `03/04` meaning different
/// months.
class RecordPaymentModal extends StatefulWidget {
  const RecordPaymentModal({
    super.key,
    required this.concepts,
    required this.settlements,
    required this.accounts,
    required this.currency,
    this.ticket = "",
    this.amount
  });

  /// What a payment can be for, both directions together.
  final List<MoneyConcept> concepts;

  /// How money can move: the settlement kinds.
  final List<PosPaymentMethod> settlements;

  /// The company's own accounts, for saying which one the money landed in.
  final List<MoneyMethod> accounts;

  /// The company's currency. It is what reads what was typed —`12,50` and
  /// `12.50` are the same amount— and what the amount field's placeholder says.
  final CurrencyModel currency;

  /// The sale this payment settles, when the panel was opened from a debt. It
  /// preselects the settling concept, which is the only one that pays a ticket
  /// down.
  final String ticket;

  /// What the field opens with, which from a debt is what is still owed: the
  /// usual case is collecting the whole thing, and the number is right there.
  final double? amount;

  @override
  State<RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends State<RecordPaymentModal> {
  final _form = FormController();

  /// Longest note. It is a line somebody reads a month later, not a document.
  static const int _maxNote = 200;

  /// Longest name or contact of a counterpart, which is what the backend keeps.
  static const int _maxCounterpart = 80;

  /// What the concept picker opens on: the settling concept when a ticket was
  /// handed in, and nothing otherwise. Choosing one for somebody who has not
  /// said what the money was for would file it under a concept they never read.
  late final String _initialConcept = _settling();

  /// The one concept that pays a credit ticket down. There is exactly one in
  /// the catalog, but it is looked up and not spelled here: which code it is is
  /// the backend's to decide.
  String _settling() {
    if (widget.ticket.isEmpty) return "";

    for (final concept in widget.concepts) {
      if (concept.settles) return concept.concept;
    }

    return "";
  }

  late final _concept = InputController.select(
    key: "CONCEPT",
    form: _form,
    obligatory: true,
    initial: _initialConcept,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(
        S.of(context).finance_payment_concept
      )
    }
  );

  /// The amount. Both separators are accepted because whoever records it types
  /// the one their currency uses, and [CurrencyModel.parse] reads either.
  ///
  /// **It is a text field and not an [InputType.numeric] one**: core forces
  /// `digitsOnly` on numeric fields, so `12,50` would arrive as `1250` — a
  /// payment a hundred times what was meant. What keeps letters out is the
  /// pattern, which the validator enforces on every key.
  late final _amount = InputController(
    key: "AMOUNT",
    form: _form,
    pattern: "[0-9.,]",
    obligatory: true,
    initial: widget.amount?.toString(),
    customErrors: {
      InputError.empty: S.of(context).finance_record_amount_error,
      InputError.invalid: S.of(context).finance_record_amount_error
    }
  );

  late final _account = InputController.select(key: "ACCOUNT_ID", form: _form);
  late final _method = InputController.select(key: "METHOD", form: _form);

  late final _reference = InputController(
    key: "REFERENCE",
    form: _form,
    max: _maxCounterpart
  );

  late final _counterpart = InputController(
    key: "COUNTERPART",
    form: _form,
    max: _maxCounterpart
  );

  late final _ticket = InputController(
    key: "TICKET",
    form: _form,
    initial: widget.ticket
  );

  late final _note = InputController(key: "NOTE", form: _form, max: _maxNote);

  /// The concept currently picked, or null while none is. It is kept as state
  /// —and not read off the controller in `build`— because the ticket field
  /// appears and disappears with it, and that has to repaint.
  MoneyConcept? _picked;

  @override
  void initState() {
    super.initState();

    // Only a lookup in a list handed in by the caller: no inherited widget is
    // touched, so it is safe here, unlike the controllers above.
    _picked = _conceptOf(_initialConcept);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Same width as the rest of the panels of this app.
  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      // The panel is as tall as the window and the form is not: eight fields
      // plus the button do not fit on a short screen, and a `Column` that does
      // not fit overflows instead of shortening. The bottom padding is the
      // panel's own, which leaves it out so that whatever scrolls reaches the
      // edge; the button is the last thing here and must not sit on it.
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).finance_record_subtitle,
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          SelectInput(
            title: S.of(context).finance_payment_concept,
            placeholder: S.of(context).finance_record_concept_placeholder,
            controller: _concept,
            options: _conceptOptions(context),
            emptyText: S.of(context).finance_select_empty,
            leftIcon: Icon(CI.list, color: scheme.icon),
            onSelected: (option) => setState(
              () => _picked = _conceptOf(option.value)
            )
          ),
          Input(
            title: S.of(context).finance_payment_amount,
            // The placeholder carries the symbol —`$0`, `0€`— because it is
            // the only thing on the form that says which money this is in, and
            // the amount is never converted.
            placeholder: widget.currency.write("0"),
            controller: _amount,
            leftIcon: Icon(CI.wallet, color: scheme.icon)
          ),
          // The ticket only exists on the concepts that allow one; the backend
          // refuses it on the rest, so it is not offered there either.
          if (_picked?.ticket ?? false) Input(
            title: S.of(context).finance_payment_ticket,
            placeholder: S.of(context).finance_record_ticket_placeholder,
            controller: _ticket,
            leftIcon: Icon(CI.receipt, color: scheme.icon)
          ),
          SelectInput(
            title: S.of(context).finance_record_account,
            placeholder: S.of(context).finance_record_account_placeholder,
            controller: _account,
            options: _accountOptions(context),
            emptyText: S.of(context).finance_select_empty,
            leftIcon: Icon(CI.discount_card, color: scheme.icon)
          ),
          SelectInput(
            title: S.of(context).finance_payment_method,
            placeholder: S.of(context).finance_record_method_placeholder,
            controller: _method,
            options: [
              for (final method in widget.settlements) SelectOption(
                value: method.method,
                placeholder: method.name
              )
            ],
            emptyText: S.of(context).finance_select_empty,
            leftIcon: Icon(CI.cashbox, color: scheme.icon)
          ),
          Input(
            title: S.of(context).finance_payment_reference,
            placeholder: S.of(context).finance_record_reference_placeholder,
            controller: _reference,
            leftIcon: Icon(CI.key, color: scheme.icon)
          ),
          Input(
            title: S.of(context).finance_payment_counterpart,
            placeholder: S.of(context).finance_record_counterpart_placeholder,
            controller: _counterpart,
            leftIcon: Icon(CI.user, color: scheme.icon)
          ),
          Input(
            title: S.of(context).finance_payment_note,
            placeholder: S.of(context).finance_record_note_placeholder,
            controller: _note,
            leftIcon: Icon(CI.edit, color: scheme.icon),
            onSubmit: _submit
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).finance_record_save, action: _submit)
        ]
      )
    );
  }

  /// Both halves of the catalog in one list, each option carrying the arrow of
  /// its direction: the concept is what decides which way the money went, so
  /// this list is also the direction picker.
  List<SelectOption> _conceptOptions(BuildContext context) => [
    for (final concept in widget.concepts) SelectOption(
      value: concept.concept,
      placeholder: concept.name,
      icon: concept.direction.isIncoming ? CI.arrow_down : CI.arrow_top,
      subtitle: concept.direction.isIncoming
        ? S.of(context).finance_payments_in
        : S.of(context).finance_payments_out
    )
  ];

  /// The company's accounts, plus the option of naming none: a payment in cash
  /// did not land in any of them, and forcing one would file it under an
  /// account it never touched.
  List<SelectOption> _accountOptions(BuildContext context) => [
    SelectOption(
      value: "",
      placeholder: S.of(context).finance_record_no_account
    ),
    for (final account in widget.accounts) SelectOption(
      value: account.id,
      placeholder: account.title,
      subtitle: account.subtitle.isEmpty ? null : account.subtitle
    )
  ];

  MoneyConcept? _conceptOf(String code) {
    if (code.isEmpty) return null;

    for (final concept in widget.concepts) {
      if (concept.concept == code) return concept;
    }

    return null;
  }

  /// Reads the form and closes with the body, or leaves the wrong field in red.
  ///
  /// The amount is checked by hand and not only through its controller: the
  /// field's validator knows the pattern, and `,,` passes a pattern of digits
  /// and separators without being a number. Zero is refused too — a payment of
  /// nothing is a row that says money moved when none did.
  void _submit() {
    if (!_concept.validate(_concept)) return;

    final amount = CurrencyModel.parse(_amount.text.trim());

    if (amount == null || amount <= 0) {
      _amount.status.setStatus(
        InputStatus.error,
        _amount.text.trim().isEmpty ? InputError.empty : InputError.invalid
      );
      _amount.focus.requestFocus();

      return;
    }

    _amount.status.setStatus(InputStatus.valid, null);

    final account = _account.selectedValue ?? "";

    Navigator.pop(context, recordPaymentRequest(
      concept: _concept.value,
      amount: amount,
      // The settlement kind is only sent when no account was named: the backend
      // takes it from the account, and sending both would let a transfer into a
      // bank account be filed as cash.
      method: account.isEmpty ? _method.selectedValue ?? "" : "",
      accountId: account,
      reference: _reference.text,
      counterpartName: _counterpart.text,
      note: _note.text,
      // The concepts that take no ticket are not offered the field, so whatever
      // it still holds from a previous pick must not travel.
      ticket: (_picked?.ticket ?? false) ? _ticket.text : ""
    ));
  }
}
