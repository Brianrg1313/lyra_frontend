import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_currency_request.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';

/// Adds an exchange currency, or changes the rate of one the company already
/// takes.
///
/// It is **one panel for both**, like the account form, and the one field that
/// differs is the currency: picked on creation, fixed on an edit. "These
/// bolivars are now pesos" is not a new rate but another currency, and the
/// payments already recorded in it would change what they say they were.
///
/// The rate is always written **one unit of the main currency in this one**
/// (`1 USD = 36.52 VES`), because that is how a shop says it and how the
/// backend stores it. With the official mode no figure is asked for: the rate
/// is the feed's, and a box to type it into would let anybody call their own
/// figure official.
///
/// It **returns the request body and writes nothing**, like every modal here.
/// Returns `null` when it was closed without saving.
Future<Map<String, dynamic>?> showExchangeCurrencyForm(
  BuildContext context, {
  required String main,
  List<String> taken = const [],
  MoneyExchange? exchange
}) => showSideModal(
  context: context,
  title: exchange == null
    ? S.of(context).finance_currency_create_title
    : S.of(context).finance_currency_edit_title,
  builder: (context) => ExchangeCurrencyFormModal(
    main: main,
    taken: taken,
    exchange: exchange
  )
).then((value) => value is Map<String, dynamic> ? value : null);

/// The panel itself.
class ExchangeCurrencyFormModal extends StatefulWidget {
  const ExchangeCurrencyFormModal({
    super.key,
    required this.main,
    this.taken = const [],
    this.exchange
  });

  /// The main currency's code: what every rate here is a price of.
  final String main;

  /// Exchange currencies the company already takes. They are not offered
  /// again: one currency has one rate.
  final List<String> taken;

  /// The one being edited, or null when one is being added.
  final MoneyExchange? exchange;

  @override
  State<ExchangeCurrencyFormModal> createState() =>
    _ExchangeCurrencyFormModalState();
}

class _ExchangeCurrencyFormModalState extends State<ExchangeCurrencyFormModal> {
  final _form = FormController();

  /// The rate box lives in a form of its own: it is only drawn with the custom
  /// mode, and a controller registered in [_form] would still be validated
  /// while hidden. It is checked by hand in [_submit].
  final _rateForm = FormController();

  late MoneyRateMode _mode = widget.exchange?.mode ?? MoneyRateMode.official;

  bool get _isEdit => widget.exchange != null;

  late final _currency = InputController.select(
    key: "CURRENCY",
    form: _form,
    obligatory: true,
    initial: widget.exchange?.currency,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(
        S.of(context).finance_currency
      )
    }
  );

  late final _modeInput = InputController.select(
    key: "MODE",
    form: _form,
    initial: _mode.value
  );

  /// Both separators are accepted: a rate is typed the way its currency writes
  /// numbers, and [CurrencyModel.parse] reads either.
  late final _rate = InputController(
    key: "RATE",
    form: _rateForm,
    pattern: "[0-9.,]",
    initial: _initialRate(),
    customErrors: {
      InputError.empty: S.of(context).finance_currency_rate_error,
      InputError.invalid: S.of(context).finance_currency_rate_error
    }
  );

  /// The custom figure the company wrote before, even when it is on the
  /// official rate now: switching back should not make it type it again.
  String? _initialRate() {
    final value = widget.exchange?.custom;
    return value == null ? null : _plain(value);
  }

  /// A rate as it is typed: no grouping, up to four decimals, no trailing
  /// zeros. `36.5` and not `36.5000`.
  static String _plain(double value) => value
    .toStringAsFixed(4)
    .replaceFirst(RegExp(r"\.?0+$"), "");

  @override
  void dispose() {
    _rateForm.dispose();
    _form.dispose();
    super.dispose();
  }

  /// Same width as the rest of the panels of this app.
  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final catalog = CurrencyCatalogService();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).finance_currency_form_subtitle(widget.main),
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          if (_isEdit)
            _Fixed(currency: catalog.resolve(widget.exchange!.currency))
          else
            SelectInput(
              title: S.of(context).finance_currency,
              placeholder: S.of(context).finance_currency_placeholder,
              controller: _currency,
              options: [
                for (final currency in _offered(catalog)) SelectOption(
                  value: currency.code,
                  placeholder: "${currency.code} - ${currency.name}",
                  chosen: currency.code
                )
              ],
              emptyText: S.of(context).finance_select_empty,
              leftIcon: Icon(CI.wallet, color: scheme.icon),
              // Redrawn so the rate box says which currency it is a price in.
              onSelected: (_) => setState(() {})
            ),
          SelectInput(
            title: S.of(context).finance_currency_mode,
            placeholder: S.of(context).finance_currency_mode,
            controller: _modeInput,
            options: [
              SelectOption(
                value: MoneyRateMode.official.value,
                placeholder: S.of(context).finance_currency_mode_official,
                subtitle: S.of(context).finance_currency_mode_official_hint
              ),
              SelectOption(
                value: MoneyRateMode.custom.value,
                placeholder: S.of(context).finance_currency_mode_custom,
                subtitle: S.of(context).finance_currency_mode_custom_hint
              )
            ],
            emptyText: S.of(context).finance_select_empty,
            searchable: false,
            leftIcon: Icon(CI.chart, color: scheme.icon),
            onSelected: (option) => setState(
              () => _mode = MoneyRateMode.from(option.value)
            )
          ),
          if (_mode == MoneyRateMode.custom) Input(
            title: S.of(context).finance_currency_rate(
              widget.main,
              _code.isEmpty ? "…" : _code
            ),
            placeholder: widget.exchange?.official == null
              ? "0.00"
              : _plain(widget.exchange!.official!),
            controller: _rate,
            leftIcon: Icon(CI.edit, color: scheme.icon),
            onSubmit: _submit
          ),
          ..._official(context),
          if (_mode == MoneyRateMode.custom) const _Disclaimer(),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).save, action: _submit)
        ]
      )
    );
  }

  /// The currency picked so far: fixed on an edit, the select's on a creation.
  String get _code => _isEdit
    ? widget.exchange!.currency
    : (_currency.selectedValue ?? "");

  /// Legal tender the company does not take yet, the main one left out. Crypto
  /// is not offered: none of its rates come from the feed the official mode
  /// reads.
  List<CurrencyModel> _offered(CurrencyCatalogService catalog) {
    final taken = {
      widget.main.toUpperCase(),
      for (final code in widget.taken) code.toUpperCase()
    };

    return [
      for (final currency in catalog.fiat)
        if (!taken.contains(currency.code)) currency
    ];
  }

  /// The feed's rate, when this currency has one: beside the custom box it is
  /// how far the company's figure is from it, and under the official mode it
  /// is what is going to be charged. A new currency has none yet —the backend
  /// only asks the feed for the currencies a company takes— so it says the
  /// rate arrives once saved.
  List<Widget> _official(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final official = widget.exchange?.official;

    final text = official == null
      ? S.of(context).finance_currency_official_pending
      : S.of(context).finance_currency_official_today(
          moneyRateLabel(widget.main, official, _code)
        );

    return [
      Padding(
        padding: EdgeInsets.only(bottom: AppSize.spaceXS),
        child: Surface.over(
          padding: EdgeInsets.all(AppSize.spaceXS),
          child: Row(children: [
            Icon(CI.info, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextSmall(
              text,
              lines: 3,
              color: scheme.text.secondary
            ))
          ])
        )
      )
    ];
  }

  /// Reads the form and closes with the body.
  ///
  /// The rate is checked by hand: the pattern lets `,,` through, and a rate of
  /// zero is not a rate.
  void _submit() {
    if (!_isEdit && !_currency.validate(_currency)) return;

    double? rate;

    if (_mode == MoneyRateMode.custom) {
      rate = CurrencyModel.parse(_rate.text.trim());

      if (rate == null || rate <= 0) {
        _rate.status.setStatus(
          InputStatus.error,
          _rate.text.trim().isEmpty ? InputError.empty : InputError.invalid
        );
        _rate.focus.requestFocus();

        return;
      }

      _rate.status.setStatus(InputStatus.valid, null);
    }

    Navigator.pop(context, saveMoneyExchangeRequest(
      currency: _code,
      mode: _mode,
      rate: rate
    ));
  }
}

/// The currency of the rate being edited: read-only, because another currency
/// is another row.
class _Fixed extends StatelessWidget {
  const _Fixed({required this.currency});

  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          Icon(CI.wallet, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextMedium(
            "${currency.code} - ${currency.name}",
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

/// What is said while a custom rate is being set: the figure is the company's
/// and so is what it charges with it. The official rate points at a published
/// source; this one points at nobody but the business, and a customer who
/// disputes a conversion disputes it with the business, not with the platform.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CI.info, size: AppSize.text, color: scheme.chart.serious),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextSmall(
              S.of(context).finance_currency_custom_disclaimer,
              lines: 4,
              color: scheme.text.secondary
            ))
          ]
        )
      )
    );
  }
}
