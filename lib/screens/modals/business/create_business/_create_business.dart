import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show Catalogs;

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_language.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'notice.dart';

class CreateBusinessModal extends StatefulWidget {
  const CreateBusinessModal({super.key});

  @override
  State<CreateBusinessModal> createState() => _CreateBusinessModalState();
}

class _CreateBusinessModalState extends State<CreateBusinessModal> {
  final _form = FormController();

  /// Letters (with accents and diaeresis), N/n, digits and the usual
  /// punctuation of a legal name: `Acme S.A.`, `Foo & Bar, Ltd.`
  static const _legalNamePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,\\-]";

  late final _legalName = InputController(
    key: "LEGAL_NAME",
    form: _form,
    pattern: _legalNamePattern,
    min: 3,
    max: 100,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).business_legal_name_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).business_legal_name_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).business_legal_name_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).business_legal_name_input)
    }
  );

  late final _type = InputController.select(
    key: "ACTIVITY_TYPE",
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).business_type_input)
    }
  );

  /// The business types come from [BusinessActivity] and not from a list
  /// written here: it is the same catalog the profile uses to translate a type
  /// when the backend returns it, so what is chosen when creating the business
  /// is read back later under that name.
  ///
  /// The `value` travels to the backend and is not translated; only the
  /// `placeholder` is localizable.
  late final _types = [
    for (final activity in BusinessActivity.catalog)
      SelectOption(value: activity.value, placeholder: activity.label(context))
  ];

  /// A master's one company (the welcome of a master set up without it, `business.md` B-1): no
  /// backend infers where it is, so the form asks for the country, the main currency and the
  /// language, from the catalogue the engine ships. Cloud verification doesn't apply (B-6).
  final _single = CapabilityService().singleCompany;

  // Created only when drawn: in the cloud they never join the form.
  late final _country = InputController.select(key: "COUNTRY", form: _form, obligatory: true);
  late final _currency = InputController.select(key: "CURRENCY", form: _form, obligatory: true);
  late final _language = InputController.select(
    key: "LANGUAGE",
    form: _form,
    obligatory: true,
    initial: BusinessLanguage.from(Localizations.localeOf(context).languageCode)?.tag ?? BusinessLanguage.en.tag
  );

  /// Remounts the currency field when the country proposes one, so it shows it.
  int _currencyShown = 0;
  bool _currencyPicked = false;

  static final _countries = [
    for (final row in Catalogs.countryRows)
      SelectOption(value: row["code"] as String, placeholder: row["name"] as String)
  ];

  static final _currencies = [
    for (final row in Catalogs.currencyRows)
      SelectOption(
        value: row["code"] as String,
        placeholder: "${row["code"]} · ${row["name"]}",
        chosen: row["code"] as String
      )
  ];

  static final _languages = [
    for (final language in BusinessLanguage.values) SelectOption(value: language.tag, placeholder: language.name)
  ];

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// A country proposes the money it quotes in, until a currency is picked by hand. The currency
  /// is fixed from then on (B-5).
  ///
  /// The text is written here, in the tap, and not by the remounted field: in its `initState` the
  /// field it replaces is still listening to the same controller, and a write there throws.
  void _proposeCurrency(SelectOption country) {
    if (_currencyPicked) return;

    final code = Catalogs.country(country.value)?["currency"] as String?;
    final currency = _currencies.where((option) => option.value == code).firstOrNull;
    if (currency == null) return;

    _currency.selectedValue = currency.value;
    _currency.textController.text = currency.selection;
    setState(() => _currencyShown++);
  }

  /// The fields scroll, the button stays: a master's form (country, currency, language) is taller
  /// than a short window leaves under the modal's image, and the modal doesn't scroll its body.
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Its bar goes in the modal's right padding.
        Flexible(child: ScrollableWidget(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.spaceS),
              child: TextMedium(S.of(context).create_business_subtitle)
            ),
            Input(
              placeholder: S.of(context).business_legal_name_input,
              title: S.of(context).business_legal_name_input,
              controller: _legalName,
              leftIcon: Icon(CI.store, color: ThemeColor.of(context).icon),
              next: _type.focus
            ),
            SelectInput(
              placeholder: S.of(context).business_type_placeholder,
              title: S.of(context).business_type_input,
              emptyText: S.of(context).business_type_empty,
              controller: _type,
              options: _types
            ),
            if (_single) ...[
              SelectInput(
                placeholder: S.of(context).lan_master_country,
                title: S.of(context).lan_master_country,
                controller: _country,
                options: _countries,
                emptyText: S.of(context).lan_master_no_match,
                onSelected: _proposeCurrency
              ),
              InputRow(children: [
                SelectInput(
                  key: ValueKey(_currencyShown),
                  placeholder: S.of(context).lan_master_currency,
                  title: S.of(context).lan_master_currency,
                  controller: _currency,
                  options: _currencies,
                  emptyText: S.of(context).lan_master_no_match,
                  onSelected: (_) => _currencyPicked = true
                ),
                SelectInput(
                  placeholder: S.of(context).lan_master_language,
                  title: S.of(context).lan_master_language,
                  controller: _language,
                  options: _languages,
                  searchable: false
                )
              ]),
              TextSmall(S.of(context).lan_master_currency_note, lines: 3, color: ThemeColor.of(context).subtitle)
            ] else ...[
              SizedBox(height: AppSize.spaceXS),
              const CreateBusinessNotice()
            ]
          ]
        )),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).create_business,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    context.read<BusinessService>().createBusiness(context, _form.data)
      .then((_) {
        if (!mounted) return;
        _form.loading.value = false;
        Navigator.pop(context, true);
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;
      });
  }
}