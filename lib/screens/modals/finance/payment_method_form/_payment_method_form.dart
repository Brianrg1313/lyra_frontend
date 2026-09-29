import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/money/account_mask.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_method_request.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Turns one of the company's ways of charging on, or edits the one it already
/// has.
///
/// It is **one panel for both** because it is the same sheet of data —who the
/// account is under, at which institution, and the number— and only one field
/// differs: the rail, which is picked on creation and cannot be changed
/// afterwards. "This Pago Movil is now a Zelle" is not an edit of an account
/// but another account, and the payments already recorded against the row would
/// silently change what they say they came in through.
///
/// **What it asks for is the rail's own answer and not this file's.** Every
/// rail carries a requirement sheet ([MoneyMethodField], written by
/// `model:/money/requirements.js` and handed over by `GET /business/payments`),
/// and the middle of this form is drawn from it: a Pago Movil asks for a bank
/// out of the list, a cedula or RIF and a phone, and asks for **no holder**; a
/// Zelle asks for a name and an address and no bank; cash asks for nothing at
/// all. The same sheet is what the backend refuses a write against, so the
/// panel cannot demand a field the write ignores nor let through one it
/// requires — which is what six boxes for every rail did before.
///
/// The sheet says more than which boxes there are: a bank is a searchable list
/// of the country's banks with the code each is routed by, an id is its type
/// beside its number, and a number with a national shape
/// ([MoneyMethodField.format]) is spaced as it is typed. All of it is the
/// rail's own answer, so a rail that changes what it needs changes this form
/// without an app release.
///
/// **Every account is in one currency and may charge a commission.** The
/// currency is picked out of what the company can price ([currencies]: the
/// main one and its exchange currencies), except on a rail that only moves one
/// ([MoneyRail.currency]) — a Pago Movil is bolivars whatever is picked. The
/// commission is a fixed amount in that currency or a percentage, and the
/// backend adds it to the charge.
///
/// It **returns the request body and writes nothing**, like every modal here:
/// `MoneyMethodsService` is provided by the finance section, which lives under
/// the navigator this panel is opened on. The caller knows whether it handed in
/// a [method], so it knows which of the two writes the body is for.
///
/// Returns `null` when it was closed without saving.
Future<Map<String, dynamic>?> showPaymentMethodForm(
  BuildContext context, {
  required List<MoneyRail> rails,
  required Map<String, List<MoneyMethodField>> sheets,
  required Map<String, List<MoneyPaymentOption>> options,
  MoneyCurrencies currencies = const MoneyCurrencies(main: ""),
  MoneyMethod? method
}) => showSideModal(
  context: context,
  title: method == null
    ? S.of(context).finance_method_create_title
    : S.of(context).finance_method_edit_title,
  builder: (context) => PaymentMethodFormModal(
    rails: rails,
    sheets: sheets,
    options: options,
    currencies: currencies,
    method: method
  )
).then((value) => value is Map<String, dynamic> ? value : null);

/// The panel itself.
class PaymentMethodFormModal extends StatefulWidget {
  const PaymentMethodFormModal({
    super.key,
    required this.rails,
    required this.sheets,
    required this.options,
    this.currencies = const MoneyCurrencies(main: ""),
    this.method
  });

  /// What the company may turn on: the rails available in its country. Empty
  /// when that catalog did not arrive, and then there is nothing to create —
  /// which the panel says instead of drawing an empty picker.
  final List<MoneyRail> rails;

  /// What each rail asks to be filled in, by rail code.
  final Map<String, List<MoneyMethodField>> sheets;

  /// The lists the closed fields are filled from (`banks`, `documents`,
  /// `networks`), already narrowed to the company's country.
  final Map<String, List<MoneyPaymentOption>> options;

  /// What the company can price: an account in any other currency would take
  /// money nothing converts. Empty when the setup did not arrive, and then the
  /// currency is not asked (the backend reads a missing one as the main).
  final MoneyCurrencies currencies;

  /// The account being edited, or null when one is being added.
  final MoneyMethod? method;

  @override
  State<PaymentMethodFormModal> createState() => _PaymentMethodFormModalState();
}

class _PaymentMethodFormModalState extends State<PaymentMethodFormModal> {
  /// The three fields that are on every rail: which one it is, what the company
  /// calls this account and what the customer has to do beyond sending the
  /// money. They live in their own form because they survive a change of rail.
  final _form = FormController();

  /// The account itself, rebuilt whenever the rail changes.
  ///
  /// It is a **new** [FormController] and not the same one emptied, because a
  /// controller is memoized by key inside its form and `obligatory` is written
  /// when it is created: the `ACCOUNT` of a Zelle is required and the one of a
  /// cheque does not exist, and reusing the instance would keep the first
  /// answer for the second rail.
  FormController _account = FormController();

  /// The sheet being drawn: what the selected rail asks for.
  List<MoneyMethodField> _fields = const [];

  /// The controllers of that sheet, by key.
  ///
  /// They are held here and not read back out of [_account]: a controller only
  /// registers itself in its form when the input that draws it mounts
  /// (`InputController.findForm`), so the form knows them a frame after this
  /// does — and this has to hand them to the inputs that will do the
  /// registering.
  Map<String, InputController> _controllers = const {};

  /// Rail the sheet belongs to. Fixed on an edit, picked on a creation.
  late String _code = widget.method?.code ?? "";

  /// How long each field is kept, by column. They are the backend's own column
  /// ceilings (`model:/money/methods.js`): a shorter one here would refuse an
  /// account the server accepts, and a longer one would let it be truncated
  /// after it was saved.
  static const Map<String, int> _limits = {
    "holder": 120,
    "document": 40,
    "institution": 80,
    "account": 120
  };

  /// Longest name the company can give an account.
  static const int _maxLabel = 64;

  /// Longest instruction. It is what the customer is told to do beyond sending
  /// the money.
  static const int _maxInstructions = 255;

  bool get _isEdit => widget.method != null;

  /// Whether the sheet's controllers were built. See [didChangeDependencies].
  bool _built = false;

  late final _rail = InputController.select(
    key: "CODE",
    form: _form,
    obligatory: true,
    initial: widget.method?.code,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(
        S.of(context).finance_method_rail
      )
    }
  );

  late final _label = InputController(
    key: "LABEL",
    form: _form,
    max: _maxLabel,
    initial: widget.method?.label
  );

  late final _instructions = InputController(
    key: "INSTRUCTIONS",
    form: _form,
    max: _maxInstructions,
    initial: widget.method?.instructions
  );

  /// The currency the account takes, when the rail leaves it to the company.
  late final _currency = InputController.select(
    key: "CURRENCY",
    form: _form,
    initial: _initialCurrency()
  );

  /// How the commission is charged. Its own form, like the value beside it:
  /// neither is required, and both are checked by hand in [_readFee].
  final _feeForm = FormController();

  late MoneyFeeType _feeType = widget.method?.fee.type ?? MoneyFeeType.none;

  late final _feeTypeInput = InputController.select(
    key: "FEE_TYPE",
    form: _feeForm,
    initial: _feeType.value
  );

  late final _feeValue = InputController(
    key: "FEE",
    form: _feeForm,
    pattern: "[0-9.,]",
    initial: widget.method == null || widget.method!.fee.isNone
      ? null
      : _plain(widget.method!.fee.value),
    customErrors: {
      InputError.empty: S.of(context).finance_method_fee_error,
      InputError.invalid: S.of(context).finance_method_fee_error
    }
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Not in `initState`: the controllers' errors are written strings, and
    // reading `S` is looking up an inherited widget, which is only allowed once
    // the element has its dependencies.
    if (!_built) {
      _built = true;
      _buildAccount();
    }
  }

  @override
  void dispose() {
    _account.dispose();
    _feeForm.dispose();
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
      // The panel is as tall as the window and the form is not: the fields of a
      // bank transfer plus the button do not fit on a short screen, and a
      // `Column` that does not fit overflows instead of shortening. The bottom
      // padding is the panel's own, which leaves it out so that whatever
      // scrolls reaches the edge; the button is the last thing here and must
      // not sit on it.
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).finance_method_subtitle,
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          // On an edit the rail is written, not offered: it is the one thing
          // about an account that cannot change. Showing a disabled picker
          // would invite the click that this form has no answer for.
          if (_isEdit)
            _Rail(name: widget.method!.name, code: widget.method!.code)
          else if (widget.rails.isEmpty)
            const _NoRails()
          else
            SelectInput(
              title: S.of(context).finance_method_rail,
              placeholder: S.of(context).finance_method_rail_placeholder,
              controller: _rail,
              options: [
                for (final rail in widget.rails) SelectOption(
                  value: rail.code,
                  placeholder: rail.name,
                  subtitle: rail.methodName.isEmpty ? null : rail.methodName
                )
              ],
              emptyText: S.of(context).finance_select_empty,
              leftIcon: Icon(CI.discount_card, color: scheme.icon),
              onSelected: _onRail
            ),
          // Both of the fields every rail carries are optional, and both say
          // so: on a form whose middle is mostly required, one that says
          // nothing reads as required too. A method with no name is read by
          // its rail's, and one with no instructions simply has none.
          Input(
            title: _title(
              context,
              S.of(context).finance_method_label,
              required: false
            ),
            placeholder: S.of(context).finance_method_label_placeholder,
            controller: _label,
            leftIcon: Icon(CI.bookmark, color: scheme.icon)
          ),
          ..._accountInputs(context),
          ..._currencyInputs(context),
          _feeInputs(context),
          Input(
            title: _title(
              context,
              S.of(context).finance_method_instructions,
              required: false
            ),
            placeholder: S.of(context).finance_method_instructions_placeholder,
            controller: _instructions,
            leftIcon: Icon(CI.edit, color: scheme.icon),
            onSubmit: _submit
          ),
          SizedBox(height: AppSize.spaceM),
          Button(
            title: S.of(context).save,
            // With no rail to pick from there is nothing this form can create,
            // so the button does not pretend otherwise.
            action: !_isEdit && widget.rails.isEmpty ? () {} : _submit
          )
        ]
      )
    );
  }

  /// The rail being added or edited, when the catalog has it.
  MoneyRail? get _railOf {
    for (final rail in widget.rails) {
      if (rail.code == _code) return rail;
    }

    return null;
  }

  /// The currency the rail moves, when it only moves one.
  String get _railCurrency => _railOf?.currency ?? "";

  /// What the currency starts as: what the row holds, else the main one —
  /// which is what an account with none is read as.
  String? _initialCurrency() {
    final stored = widget.method?.currency ?? "";
    if (stored.isNotEmpty) return stored;

    final main = widget.currencies.main;
    return main.isEmpty ? null : main;
  }

  /// The currency the account ends up in: the rail's when it has one, the
  /// picked one otherwise.
  String get _chosenCurrency =>
    _railCurrency.isNotEmpty ? _railCurrency : _currency.value.trim();

  /// The currency field, or the rail's fixed one, plus a warning when it is one
  /// the company cannot price: a Pago Movil in bolivars with no bolivar rate
  /// configured takes money the charge cannot be converted into.
  List<Widget> _currencyInputs(BuildContext context) {
    final codes = widget.currencies.codes;
    if (_code.isEmpty || codes.isEmpty) return const [];

    final scheme = ThemeColor.of(context);
    final catalog = CurrencyCatalogService();
    final chosen = _chosenCurrency;

    return [
      if (_railCurrency.isNotEmpty)
        _Note(
          icon: CI.wallet,
          text: S.of(context).finance_method_currency_fixed(
            _currencyTitle(catalog.resolve(_railCurrency))
          )
        )
      else
        SelectInput(
          title: S.of(context).finance_method_currency,
          placeholder: S.of(context).finance_method_currency_placeholder,
          controller: _currency,
          options: [
            for (final code in codes) SelectOption(
              value: code,
              placeholder: _currencyTitle(catalog.resolve(code)),
              subtitle: code == widget.currencies.main
                ? S.of(context).finance_currency_main
                : null,
              chosen: code
            )
          ],
          emptyText: S.of(context).finance_select_empty,
          searchable: false,
          leftIcon: Icon(CI.wallet, color: scheme.icon),
          // Redrawn: the commission's amount is in this currency.
          onSelected: (_) => setState(() {})
        ),
      if (chosen.isNotEmpty && !codes.contains(chosen))
        _Note(
          icon: CI.info,
          alert: true,
          text: S.of(context).finance_method_currency_missing(chosen)
        )
    ];
  }

  String _currencyTitle(CurrencyModel currency) =>
    "${currency.code} - ${currency.name}";

  /// The commission: how it is charged and how much. The amount box is only
  /// drawn once there is a commission, and the option says what it is
  /// measured in — the account's currency, or a percentage.
  Widget _feeInputs(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final currency = _chosenCurrency.isNotEmpty
      ? _chosenCurrency
      : widget.currencies.main;

    final type = SelectInput(
      flex: 3,
      placeholder: S.of(context).finance_method_fee_none,
      controller: _feeTypeInput,
      options: [
        SelectOption(
          value: MoneyFeeType.none.value,
          placeholder: S.of(context).finance_method_fee_none
        ),
        SelectOption(
          value: MoneyFeeType.percent.value,
          placeholder: S.of(context).finance_method_fee_percent
        ),
        SelectOption(
          value: MoneyFeeType.fixed.value,
          placeholder: currency.isEmpty
            ? S.of(context).finance_method_fee_fixed
            : S.of(context).finance_method_fee_fixed_in(currency)
        )
      ],
      emptyText: S.of(context).finance_select_empty,
      searchable: false,
      onSelected: (option) => setState(
        () => _feeType = MoneyFeeType.from(option.value)
      )
    );

    final title = _title(
      context,
      S.of(context).finance_method_fee,
      required: false
    );

    if (_feeType == MoneyFeeType.none) {
      return InputRow(title: title, children: [type]);
    }

    return InputRow(
      title: title,
      spacing: AppSize.gap,
      children: [
        type,
        Input(
          flex: 2,
          placeholder: _feeType == MoneyFeeType.percent ? "3" : "0.00",
          controller: _feeValue,
          leftIcon: Icon(CI.discount, color: scheme.icon)
        )
      ]
    );
  }

  /// The commission as it was typed, or null when what was typed is not one
  /// (the box is flagged and focused). A percentage is under a hundred: a
  /// commission of the whole sale is a typo, not a rail.
  MoneyFee? _readFee() {
    if (_feeType == MoneyFeeType.none) return const MoneyFee();

    final value = CurrencyModel.parse(_feeValue.text.trim());
    final valid = value != null &&
      value > 0 &&
      (_feeType != MoneyFeeType.percent || value < 100);

    if (!valid) {
      _feeValue.status.setStatus(
        InputStatus.error,
        _feeValue.text.trim().isEmpty ? InputError.empty : InputError.invalid
      );
      _feeValue.focus.requestFocus();

      return null;
    }

    _feeValue.status.setStatus(InputStatus.valid, null);

    return MoneyFee(type: _feeType, value: value);
  }

  /// A figure as it is typed back: no grouping, no trailing zeros.
  static String _plain(double value) => value
    .toStringAsFixed(4)
    .replaceFirst(RegExp(r"\.?0+$"), "");

  /// The middle of the form: what this rail asks for, in the order it asks.
  ///
  /// A rail with nothing to fill in —cash, a card terminal— says so instead of
  /// leaving a hole between the name and the instructions: a form that jumps
  /// from one to the other reads like one that failed to load.
  List<Widget> _accountInputs(BuildContext context) {
    if (_code.isEmpty) return const [];

    if (_fields.isEmpty) return const [_NoFields()];

    return [for (final field in _fields) _input(context, field)];
  }

  /// One field of the sheet, drawn as its type asks for.
  Widget _input(BuildContext context, MoneyMethodField field) {
    final scheme = ThemeColor.of(context);
    final options = _optionsOf(field);
    final title = _title(context, field.label, required: field.required);

    // A closed field with an empty catalog is drawn as text and not as an empty
    // dropdown: a country whose banks are not listed can still be paid by
    // transfer, and the backend applies the same rule before it validates.
    // Searchable, which is what a list of twenty-five banks has to be, and the
    // code is on the line rather than under it: `0134` finds Banesco as surely
    // as its name does, and the two together are what gets read back out to a
    // customer.
    if (field.type == "select" && options.isNotEmpty) {
      return SelectInput(
        title: title,
        placeholder: field.hint,
        controller: _controller(field.key),
        options: [
          for (final option in options) SelectOption(
            value: option.code,
            placeholder: option.title
          )
        ],
        emptyText: S.of(context).finance_select_empty,
        leftIcon: Icon(_icon(field), color: scheme.icon)
      );
    }

    // An id is two answers and one value: the type —which is also what says
    // whether the holder is a person or a company— and the number. They share
    // one label because that is what they are: one document.
    if (field.type == "document" && options.isNotEmpty) {
      return InputRow(
        title: title,
        spacing: AppSize.gap,
        children: [
          SelectInput(
            flex: 2,
            placeholder: S.of(context).finance_method_document_type,
            controller: _controller(_typeKey(field)),
            // Picked as the document is named out loud —`V - Cédula`, because
            // nobody chooses between `V` and `J`, they choose between the two
            // pieces of paper on their desk— and kept as the letter alone: it
            // is what the row stores, it is what gets dictated in front of the
            // number, and this box is a third of a line wide.
            options: [
              for (final option in options) SelectOption(
                value: option.code,
                placeholder: option.title,
                chosen: option.code
              )
            ],
            emptyText: S.of(context).finance_select_empty,
            searchable: false
          ),
          Input(
            flex: 4,
            placeholder: field.hint,
            controller: _controller(field.key)
          )
        ]
      );
    }

    return Input(
      title: title,
      placeholder: field.hint,
      controller: _controller(field.key),
      leftIcon: Icon(_icon(field), color: scheme.icon),
      formatters: _formatters(field)
    );
  }

  /// The mask of a field, when its rail gives it one. It is a formatter and not
  /// a correction on submit: the separators appear as the digits do, so what is
  /// on screen is what will be saved.
  List<TextInputFormatter>? _formatters(MoneyMethodField field) =>
    field.format.isEmpty
      ? null
      : [AccountMaskFormatter(AccountMask(field.format))];

  /// A field's label, with the word that says it can be left empty. Marked on
  /// the optional ones and not on the required ones: on a form where most
  /// fields are needed, the exception is what is worth writing down.
  String _title(BuildContext context, String label, {required bool required}) =>
    required
      ? label
      : "$label · ${S.of(context).finance_method_optional}";

  /// Builds the controllers of the selected rail's sheet.
  ///
  /// The previous form is let go of **after** the frame: the inputs that were
  /// drawing its controllers are still mounted while this runs, and they only
  /// let go of them when the tree that replaced them is built.
  void _buildAccount() {
    final previous = _account;

    _account = FormController();
    _controllers = {};
    _fields = widget.sheets[_code] ?? const [];

    for (final field in _fields) {
      final options = _optionsOf(field);
      final empty = {
        InputError.empty: S.of(context).form_empty_ma(field.label)
      };

      if (field.type == "select" && options.isNotEmpty) {
        _controllers[field.key] = InputController.select(
          key: field.key,
          form: _account,
          obligatory: field.required,
          initial: _stored(field.field),
          customErrors: empty
        );

        continue;
      }

      if (field.type == "document" && options.isNotEmpty) {
        final document = _document(_stored(field.field), options);

        _controllers[_typeKey(field)] = InputController.select(
          key: _typeKey(field),
          form: _account,
          obligatory: field.required,
          initial: document.$1,
          customErrors: empty
        );

        _controllers[field.key] = InputController(
          key: field.key,
          form: _account,
          // The type travels joined to the number in one column, so what the
          // number may be as long as is what is left of it after the longest
          // prefix of the catalog and its separator.
          max: _max(field.field) - _reserve(options),
          pattern: _documentPattern,
          obligatory: field.required,
          initial: document.$2,
          customErrors: empty
        );

        continue;
      }

      if (field.type == "email") {
        _controllers[field.key] = InputController.email(
          key: field.key,
          form: _account,
          obligatory: field.required,
          initial: _stored(field.field),
          customErrors: empty
        );

        continue;
      }

      _controllers[field.key] = InputController(
        key: field.key,
        form: _account,
        max: _max(field.field),
        pattern: field.type == "phone" ? _phonePattern : "IGNORE",
        obligatory: field.required,
        initial: _initial(field),
        customErrors: empty
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  /// Another rail was picked: the account is another account.
  void _onRail(SelectOption option) {
    if (option.value == _code) return;

    setState(() {
      _code = option.value;
      _buildAccount();
    });
  }

  /// Reads the form and closes with the body.
  ///
  /// What is checked here is what the rail asks for and nothing else: the name
  /// and the instructions are optional on every rail, and the account is
  /// validated by the controllers the sheet built — which is the same statement
  /// the backend refuses the write against.
  void _submit() {
    if (!_isEdit && !_rail.validate(_rail)) return;
    if (!_account.validate()) return;

    final fee = _readFee();
    if (fee == null) return;

    // Only when the form asked: with no setup to pick from, nothing is sent and
    // the backend keeps (or assumes) the main currency.
    final currency = widget.currencies.codes.isEmpty ? null : _chosenCurrency;

    final fields = {
      for (final field in _fields) field.field: _value(field)
    };

    Navigator.pop(context, _isEdit
      ? updateMoneyMethodRequest(
          id: widget.method!.id,
          // The name and the instructions travel empty too: the backend writes
          // only the keys it receives, so a field left out could never be
          // cleared from here. A column this rail does not have is not sent and
          // does not need to be: the account is read against the sheet, and what
          // it does not name ends up empty on the row anyway.
          label: _label.text,
          instructions: _instructions.text,
          fields: fields,
          currency: currency,
          fee: fee
        )
      : createMoneyMethodRequest(
          code: _rail.value,
          label: _label.text,
          instructions: _instructions.text,
          fields: fields,
          currency: currency ?? "",
          fee: fee
        ));
  }

  /// What is written in a field when the panel opens: what the row holds, put
  /// through the rail's mask. An account saved before the rail had one —or from
  /// somewhere that did not apply it— is read in the shape the field is going
  /// to keep it in, instead of changing under the first keystroke.
  String _initial(MoneyMethodField field) {
    final value = _stored(field.field);

    return field.format.isEmpty
      ? value
      : AccountMask(field.format).apply(value);
  }

  /// What one field of the sheet ended up holding. A document is the type and
  /// the number joined, which is how it is stored, dictated and read back; a
  /// field with a shape travels in it, which is also what the backend stores it
  /// as.
  String _value(MoneyMethodField field) {
    final value = field.format.isEmpty
      ? _controller(field.key).value.trim()
      : AccountMask(field.format).apply(_controller(field.key).value);

    if (field.type != "document" || _optionsOf(field).isEmpty) return value;

    final type = _controller(_typeKey(field)).value.trim();

    return type.isEmpty || value.isEmpty ? value : "$type-$value";
  }

  /// The controller of a key of the sheet. It exists: they are built from the
  /// same list this reads.
  InputController _controller(String key) => _controllers[key]!;

  /// Key of the select that carries a document's type. It is a field of the
  /// form and not of the row —the type is stored joined to the number— so it is
  /// named apart from the column.
  String _typeKey(MoneyMethodField field) => "${field.key}_TYPE";

  /// The catalog a field is filled from, or empty when it is free text.
  List<MoneyPaymentOption> _optionsOf(MoneyMethodField field) =>
    field.options.isEmpty ? const [] : widget.options[field.options] ?? const [];

  /// What the account being edited holds in a column, raw: the bank's **code**
  /// and not its name, because that is what the picker preselects with.
  String _stored(String field) => switch (field) {
    "holder" => widget.method?.holder ?? "",
    "document" => widget.method?.document ?? "",
    "institution" => widget.method?.institution ?? "",
    "account" => widget.method?.account ?? "",
    _ => ""
  };

  /// Splits a stored id into the type somebody picked and the number they
  /// typed. A value with no known prefix is all number: it is what an account
  /// saved before the catalog existed looks like.
  (String, String) _document(String value, List<MoneyPaymentOption> options) {
    final at = value.indexOf("-");

    if (at <= 0) return ("", value);

    final type = value.substring(0, at).toUpperCase();
    final known = options.any((option) => option.code.toUpperCase() == type);

    return known ? (type, value.substring(at + 1)) : ("", value);
  }

  /// Room the longest type of a catalog takes inside the column, separator
  /// included.
  int _reserve(List<MoneyPaymentOption> options) => options.fold(
    1,
    (longest, option) => math.max(longest, option.code.length + 1)
  );

  int _max(String field) => _limits[field] ?? 120;

  /// An id carries dots and dashes in half the countries that issue one, and
  /// letters in the ones that prefix it.
  static const String _documentPattern = "[A-Za-z0-9.-]";

  /// A phone is written with spaces, dashes and a country code as often as not.
  static const String _phonePattern = "[0-9 +()-]";

  /// The icon beside a field, taken from what it is and not from which column
  /// it writes: the same `account` is a phone on a Pago Movil and an address on
  /// a Zelle.
  IconData _icon(MoneyMethodField field) {
    if (field.type == "phone") return CI.phone;
    if (field.type == "email") return CI.mail;
    if (field.type == "document") return CI.employee_badge;

    return switch (field.field) {
      "holder" => CI.user,
      "institution" => CI.store,
      "document" => CI.employee_badge,
      _ => CI.key
    };
  }
}

/// The rail of an account being edited: read-only, because it is the one thing
/// about it that cannot change.
class _Rail extends StatelessWidget {
  const _Rail({required this.name, required this.code});

  final String name;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          Icon(CI.discount_card, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextMedium(
            name.isNotEmpty ? name : code,
            bold: true,
            multiplier: 0.9,
            ellipsis: true
          )),
          TextSmall(
            S.of(context).finance_method_rail_fixed,
            color: scheme.text.secondary,
            multiplier: 0.9
          )
        ])
      )
    );
  }
}

/// What is drawn instead of the picker when the rail catalog did not arrive.
///
/// It is said and not hidden: a form that silently drops its first field looks
/// like one that never asked for it, and what is missing here is a read that
/// can be tried again from the tab.
class _NoRails extends StatelessWidget {
  const _NoRails();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          Icon(CI.info, size: AppSize.text, color: scheme.snackBar.alert),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            S.of(context).finance_method_no_rails,
            lines: 2,
            color: scheme.text.secondary
          ))
        ])
      )
    );
  }
}

/// What is drawn where the account would go for a rail that has none: cash, a
/// card terminal, the store's own tab. Nothing is asked because there is
/// nothing a customer has to be told beyond the method itself.
class _NoFields extends StatelessWidget {
  const _NoFields();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          Icon(CI.info, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            S.of(context).finance_method_nothing,
            lines: 2,
            color: scheme.text.secondary
          ))
        ])
      )
    );
  }
}

/// A line of the form that is read, not filled in: the currency a rail is
/// fixed to, or the warning that the one picked has no rate.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.alert = false});

  final IconData icon;
  final String text;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          Icon(
            icon,
            size: AppSize.text,
            color: alert ? scheme.snackBar.alert : scheme.icon
          ),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            text,
            lines: 3,
            color: scheme.text.secondary
          ))
        ])
      )
    );
  }
}
