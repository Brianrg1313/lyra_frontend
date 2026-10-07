import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';

import './profile_field_frame.dart';
import './profile_text_action.dart';

/// Since when the company exists, loaded in three fields: the year is typed,
/// the month is chosen and the day is typed.
///
/// Before it was a single text field in which you had to write `2019-05-03`,
/// with the format explained in a help below. Nobody writes a date that way:
/// it's written as it's said, and what was loaded —`3/5/2019`, `05-03-19`— the
/// backend rejected for format without the sheet being able to say which one
/// was the good format.
///
/// The month is the only one of the three that **is chosen**, and not on a
/// whim: it's the only one that isn't a number. Written as a number you have
/// to know if it goes before or after the day —which is exactly what changes
/// from country to country— and chosen by its name that question doesn't
/// exist. It's also where how many days the date has comes from, which is what
/// gets validated.
///
/// The order is the saved date's (`YYYY-MM-DD`) and not any language's: the
/// three fields are in view and each one says what it is, so there's nothing
/// to deduce from the order.
class BusinessProfileIncorporation extends StatefulWidget {
  const BusinessProfileIncorporation({super.key, required this.date});

  /// The saved date, or `null` if the company hasn't loaded it yet.
  final DateTime? date;

  @override
  State<BusinessProfileIncorporation> createState() =>
    _BusinessProfileIncorporationState();
}

class _BusinessProfileIncorporationState
  extends State<BusinessProfileIncorporation> {
  final _form = FormController();

  /// The last thing the backend accepted, as it travels (`2019-05-03`) or
  /// empty.
  late String _saved = _iso(widget.date);

  /// The chosen month (`01`..`12`), or empty.
  ///
  /// It's kept apart and the dropdown isn't asked for the same reason as in
  /// the phone: the dropdown resolves which option belongs to it only upon
  /// mounting, and by then this row has already decided whether there's
  /// something to save.
  late String _month = _pad(widget.date?.month);

  late final _year = InputController(
    key: "INCORPORATION_YEAR",
    form: _form,
    initial: widget.date == null ? "" : "${widget.date!.year}",
    pattern: "[0-9]",
    type: InputType.numeric,
    min: 4,
    max: 4,
    customErrors: _errors
  );

  late final _monthInput = InputController.select(
    key: "INCORPORATION_MONTH",
    form: _form,
    initial: _month
  );

  late final _day = InputController(
    key: "INCORPORATION_DAY",
    form: _form,
    initial: widget.date == null ? "" : _pad(widget.date!.day),
    pattern: "[0-9]",
    type: InputType.numeric,
    min: 1,
    max: 2,
    customErrors: _errors
  );

  /// The errors name the datum as the sheet names it: the three fields are
  /// one single date, so they talk about the date and not about "the year" or
  /// "the day".
  Map<InputError, String> get _errors => {
    InputError.empty: S.of(context).form_empty_ma(
      S.of(context).business_profile_incorporation
    ),
    InputError.invalid: S.of(context).form_invalid_ma(
      S.of(context).business_profile_incorporation
    ),
    InputError.long: S.of(context).form_long_ma(
      S.of(context).business_profile_incorporation
    ),
    InputError.incomplete: S.of(context).form_incomplete_ma(
      S.of(context).business_profile_incorporation
    )
  };

  /// Whether what's typed is already being listened to. Once only and not in
  /// `initState`: touching the controllers is building them, and their errors
  /// are written in the app's language, which can't be read there yet.
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_listening) return;
    _listening = true;

    // Typing a digit can make the save button appear (or disappear), so the
    // row redraws with each key.
    _year.textController.addListener(_listener);
    _day.textController.addListener(_listener);
  }

  @override
  void didUpdateWidget(BusinessProfileIncorporation old) {
    super.didUpdateWidget(old);

    // The profile was re-read and the date ended up different: it wasn't this
    // row (there [_saved] would already be up to date), so it's aligned.
    if (_iso(widget.date) != _saved) {
      _saved = _iso(widget.date);
      _reset();
    }
  }

  @override
  void dispose() {
    if (_listening) {
      _year.textController.removeListener(_listener);
      _day.textController.removeListener(_listener);
    }

    _form.dispose();
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: CI.calendar,
    label: S.of(context).business_profile_incorporation,
    action: _changed ? ProfileTextAction(
      label: S.of(context).save,
      action: _save
    ) : null,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppSize.action * 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: AppSize.action * 2, child: Input(
            controller: _year,
            placeholder: S.of(context).business_profile_incorporation_year,
            radius: AppSize.cornerInset(AppSize.gap),
            onSubmit: _save
          )),
          SizedBox(width: AppSize.gap),
          // The month takes the width that's left over: it's the only one of
          // the three that carries a word and not two digits.
          Expanded(child: SelectInput(
            key: ValueKey("incorporation_month_$_saved"),
            controller: _monthInput,
            options: _months(context),
            placeholder: S.of(context).business_profile_incorporation_month,
            emptyText: S.of(context).business_profile_select_empty,
            radius: AppSize.cornerInset(AppSize.gap),
            buttonSpace: false,
            onSelected: (option) => setState(() => _month = option.value)
          )),
          SizedBox(width: AppSize.gap),
          SizedBox(width: AppSize.action * 1.8, child: Input(
            controller: _day,
            placeholder: S.of(context).business_profile_incorporation_day,
            radius: AppSize.cornerInset(AppSize.gap),
            onSubmit: _save
          ))
        ]
      )
    )
  );

  /// The twelve months with their name, in the app's language.
  ///
  /// The names aren't written by this app: they're brought by `intl`, with the
  /// data loaded by `GlobalMaterialLocalizations` —the same place the Flutter
  /// calendar's month names come from—, so translating the app isn't writing
  /// twelve more words.
  List<SelectOption> _months(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.MMMM(locale);

    return [
      for (int month = 1; month <= 12; month++) SelectOption(
        value: _pad(month),
        placeholder: format.format(DateTime(2000, month))
      )
    ];
  }

  /// The date as it travels (`2019-05-03`), or empty if the three fields all
  /// are —which is how it's cleared— or if they don't yet form a date.
  String get _value {
    final year = _year.value.trim();
    final day = _day.value.trim();

    if (year.isEmpty || _month.isEmpty || day.isEmpty) return "";

    return "$year-$_month-${day.padLeft(2, "0")}";
  }

  bool get _changed => _value != _saved;

  Future<void> _save() async {
    if (!_changed) return;

    final value = _value;
    if (value.isNotEmpty && !_valid) return;

    _form.loading.value = true;

    final saved = await context.read<BusinessService>().editProfile(
      context,
      "INCORPORATION_DATE",
      value
    );

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown by the service and what was
    // typed stays in the row to correct it.
    if (!saved) return;

    setState(() => _saved = value);
  }

  /// Whether the three fields form a date that exists.
  ///
  /// The length and digits are looked at by the form; what it can't look at is
  /// whether the date **is a date**: February 31 passes any field validation
  /// and doesn't exist, and a four-digit year can be in the future.
  /// Each error is marked in the field that has to be corrected.
  bool get _valid {
    if (!_form.validate()) return false;

    final year = int.tryParse(_year.value.trim());
    final day = int.tryParse(_day.value.trim());

    // A company wasn't incorporated next year, and not in the sixteenth
    // century either: what there is there is a mistyped year.
    if (year == null || year < _minYear || year > DateTime.now().year) {
      _year.status.setStatus(InputStatus.error, InputError.invalid);
      return false;
    }

    final month = int.tryParse(_month);

    // The day is validated against **its** month: `DateTime` doesn't complain
    // about a February 31, it moves it to March 2, so what's checked is that
    // the date that comes out is the one that was written.
    final date = day == null || month == null
      ? null
      : DateTime(year, month, day);

    if (date == null || date.month != month || date.day != day) {
      _day.status.setStatus(InputStatus.error, InputError.invalid);
      return false;
    }

    return true;
  }

  /// The oldest year accepted. No companies registered here from before, and
  /// a three-digit year typed by mistake is all that arrives below it.
  static const int _minYear = 1800;

  /// Leaves the three fields showing what's saved.
  void _reset() {
    final date = widget.date;

    _year.textController.text = date == null ? "" : "${date.year}";
    _day.textController.text = date == null ? "" : _pad(date.day);

    _month = _pad(date?.month);
    _monthInput.selectedValue = _month.isEmpty ? null : _month;
  }

  /// The date as the backend expects it (`YYYY-MM-DD`), or empty.
  static String _iso(DateTime? value) =>
    value == null ? "" : value.toIso8601String().split("T").first;

  /// A two-digit number, which is how the month and day travel.
  static String _pad(int? value) =>
    value == null ? "" : "$value".padLeft(2, "0");
}
