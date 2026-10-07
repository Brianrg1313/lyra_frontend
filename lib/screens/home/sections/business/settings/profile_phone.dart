import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';

import './country_flag.dart';
import './profile_field_frame.dart';
import './profile_select.dart';
import './profile_text_action.dart';

/// The company's phone: the country code is chosen and the number is typed.
///
/// They're two fields and not one because they're two distinct data with two
/// distinct ways of being loaded. The code is a closed list —the countries the
/// platform has enabled— and nobody remembers any country's but their own; the
/// number is the only thing that truly has to be typed. Written together in a
/// text field, what happened was the usual: the number was loaded without a
/// code, or with `(0212)`, or with spaces, and the backend rejected it —it
/// only accepts digits and a `+` (`0-9+`, up to 16)— without the sheet knowing
/// how to explain why.
///
/// The code is shown with the country's flag, which is how it's recognized:
/// `+58` is Venezuela for whoever already knows, the flag is for everyone.
///
/// It's saved with a button and not when done typing, the opposite of the other
/// data that are chosen ([ProfileSelectField]): a half-typed number is a valid
/// number for any validation, so saving just because the field lost focus
/// would send broken phones. The button appears when there's something
/// different from what's saved, and disappears when there isn't.
class BusinessProfilePhone extends StatefulWidget {
  const BusinessProfilePhone({
    super.key,
    required this.phone,
    required this.country
  });

  /// The phone as it's saved (`+584121234567`), or empty.
  final String phone;

  /// The country where the company operates. It's where the proposed code comes
  /// from when the company hasn't loaded any phone yet: its country's is the
  /// one it'll want almost always.
  final String country;

  @override
  State<BusinessProfilePhone> createState() => _BusinessProfilePhoneState();
}

class _BusinessProfilePhoneState extends State<BusinessProfilePhone> {
  final _form = FormController();

  /// The last thing the backend accepted. It's what it's compared against to
  /// know if there's something to save, and what's returned to if the send
  /// fails.
  late String _saved = widget.phone;

  /// The country chosen in the dropdown.
  ///
  /// It's kept apart and the field's controller isn't asked: the dropdown
  /// resolves which option belongs to it only upon mounting, and by then this
  /// row has already decided —in the same build— whether there's something to
  /// save. Asking it, the sheet would open with the save button set without
  /// anyone having touched anything.
  late String _dial = _initialCode;

  /// The country of the saved phone, or the company's if the phone carries no
  /// code (or there's no phone yet).
  late final _code = InputController.select(
    key: "PHONE_CODE",
    form: _form,
    initial: _initialCode
  );

  late final _number = InputController(
    key: "PHONE_NUMBER",
    form: _form,
    initial: _split.number,
    pattern: "[0-9]",
    type: InputType.numeric,
    min: 4,
    // The backend accepts 16 characters counting the `+`, and the country code
    // takes up to three. It's the same cap E.164 puts on the whole number.
    max: 12,
    customErrors: _errors
  );

  /// The errors name the datum as the sheet names it. They're the usual ones:
  /// the only thing that changes is what they're talking about.
  Map<InputError, String> get _errors => {
    InputError.empty: S.of(context).form_empty_ma(
      S.of(context).business_profile_phone
    ),
    InputError.invalid: S.of(context).form_invalid_ma(
      S.of(context).business_profile_phone
    ),
    InputError.long: S.of(context).form_long_ma(
      S.of(context).business_profile_phone
    ),
    InputError.incomplete: S.of(context).form_incomplete_ma(
      S.of(context).business_profile_phone
    )
  };

  String get _initialCode {
    final country = CountryCatalogService().byPhone(widget.phone);
    if (country != null) return country.code;

    // Without a saved phone nothing is proposed if the country isn't either: a
    // code put alone is a datum nobody loaded.
    return widget.phone.isEmpty ? widget.country : "";
  }

  ({String dial, String number}) get _split =>
    CountryCatalogService().splitPhone(widget.phone);

  /// Whether what's typed is already being listened to. It's once only, and
  /// not in `initState`: touching [_number] is building it, and its errors are
  /// written in the app's language, which can't be read there yet.
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_listening) return;
    _listening = true;

    // Typing a digit can make the save button appear (or disappear), so the
    // row redraws with each key.
    _number.textController.addListener(_listener);
  }

  @override
  void didUpdateWidget(BusinessProfilePhone old) {
    super.didUpdateWidget(old);

    // The profile was re-read and the phone ended up different: it wasn't this
    // row (there [_saved] would already be up to date), so it's aligned.
    if (widget.phone != _saved) {
      _saved = widget.phone;
      _reset();
    }
  }

  @override
  void dispose() {
    if (_listening) _number.textController.removeListener(_listener);
    _form.dispose();
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // The catalog is watched: if a region is enabled with the sheet open,
    // its code appears in the list without reloading anything.
    final catalog = context.watch<CountryCatalogService>();

    return ProfileFieldFrame(
      icon: CI.phone,
      label: S.of(context).business_profile_phone,
      description: S.of(context).business_profile_phone_note,
      action: _changed ? ProfileTextAction(
        label: S.of(context).save,
        action: _save
      ) : null,
      child: ConstrainedBox(
        // Wider than the sheet's other rows because they're two fields and not
        // one: with the width of a single field, the number —which is what
        // truly gets typed— was left narrower than the code.
        constraints: BoxConstraints(maxWidth: AppSize.action * 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _codeWidth, child: SelectInput(
              key: ValueKey("phone_code_$_saved"),
              controller: _code,
              options: _options(catalog),
              placeholder: S.of(context).business_profile_phone_code,
              emptyText: S.of(context).business_profile_select_empty,
              radius: AppSize.cornerInset(AppSize.gap),
              buttonSpace: false,
              onSelected: (option) => setState(() => _dial = option.value)
            )),
            SizedBox(width: AppSize.gap),
            Expanded(child: Input(
              controller: _number,
              placeholder: S.of(context).business_profile_phone_number,
              radius: AppSize.cornerInset(AppSize.gap),
              onSubmit: _save
            ))
          ]
        )
      )
    );
  }

  /// Width of the codes list: what the flag, the longest code (`+507`) and the
  /// arrow measure, and nothing more.
  ///
  /// It's on purpose much narrower than the number. The two fields aren't worth
  /// the same: the code is three digits chosen once and the number is the only
  /// thing typed, so the width has to say which of the two is the datum.
  /// Also it's the width of the dropdown hanging from it, and from there that
  /// it isn't any smaller: the countries' names are read there.
  static double get _codeWidth => AppSize.action * 2.6;

  /// One code per enabled country, with its flag. The dial is what's read in
  /// the closed field and the name what's searched for when choosing.
  List<SelectOption> _options(CountryCatalogService catalog) => [
    for (final country in catalog.countries)
      if (country.phone.isNotEmpty) SelectOption(
        value: country.code,
        placeholder: country.dial,
        subtitle: country.name,
        leading: CountryFlag(country: country)
      )
  ];

  /// The phone as it travels: `+`, code and number, with nothing in between.
  ///
  /// Without a number there's no phone even though there's a code: empty is
  /// sent, which is how the datum is cleared. Without a code what was typed is
  /// sent as is —it's what the old text field did— instead of inventing a
  /// country.
  String get _value {
    final number = _number.value.trim();
    if (number.isEmpty) return "";

    final dial = CountryCatalogService().byCode(_dial)?.phone;
    if (dial == null || dial.isEmpty) return number;

    return "+$dial$number";
  }

  bool get _changed => _value != _saved;

  Future<void> _save() async {
    if (!_changed) return;

    // An empty number is clearing the phone, and that's allowed: nearly the
    // whole profile is optional. What isn't sent is a half-written number.
    final value = _value;
    if (value.isNotEmpty && !_form.validate()) return;

    _form.loading.value = true;

    final saved = await context.read<BusinessService>().editProfile(
      context,
      "PHONE",
      value
    );

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown by the service and what was
    // typed stays in the row to correct it: going back what was typed would be
    // losing it twice.
    if (!saved) return;

    setState(() => _saved = value);
  }

  /// Leaves both fields showing what's saved.
  void _reset() {
    _number.textController.text = CountryCatalogService()
      .splitPhone(_saved)
      .number;

    _dial = _initialCode;
    _code.selectedValue = _dial;
  }
}
