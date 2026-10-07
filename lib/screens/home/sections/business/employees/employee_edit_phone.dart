import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextEditingValue, TextInputFormatter, TextSelection;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/phone_plan.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/country_flag.dart';

import './employee_card.dart';
import './employee_edit.dart';

/// A phone edited like the company's own (`BusinessProfilePhone`): the
/// country code is chosen, with its flag, and only the digits of the number
/// are typed. It travels as `+`, code and number, the only shape the backend
/// takes (`0-9+`).
///
/// The number is checked against the code's plan ([PhonePlan]): its length,
/// and the trunk `0` written at home (`0412 …`) is dropped as it is typed,
/// since `+58 0412 …` is no one's phone.
///
/// It asks for the whole row while open ([EmployeeWiden]): the code and the
/// number side by side do not fit in half of it.
class EmployeePhoneFact extends StatefulWidget implements EmployeeTile {
  const EmployeePhoneFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onSave,
    this.country = "",
    this.empty,
    this.enabled = true
  });

  final IconData icon;
  @override
  final String label;

  /// The phone as saved (`+584121234567`), or empty.
  @override
  final String value;

  /// ISO country whose code is offered when the saved phone carries none.
  final String country;

  final String? empty;
  final bool enabled;

  /// Sends the whole phone; an empty one erases it.
  final Future<bool> Function(String phone) onSave;

  @override
  bool get wide => false;

  @override
  State<EmployeePhoneFact> createState() => _EmployeePhoneFactState();
}

class _EmployeePhoneFactState extends State<EmployeePhoneFact> {
  final _form = FormController();
  late final _code = InputController.select(key: "code", form: _form);
  late final _number = InputController(key: "number", form: _form, type: InputType.numeric);

  bool _editing = false;
  bool _saving = false;

  /// The chosen country, kept here: the select resolves its option only once
  /// it is mounted.
  String _country = "";

  @override
  void initState() {
    super.initState();
    _number.textController.addListener(_typed);
  }

  @override
  void dispose() {
    _number.textController.removeListener(_typed);
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return EmployeeFact(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        empty: widget.empty,
        copy: true
      );
    }

    if (!_editing) {
      return EmployeeEditButton(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        empty: widget.empty,
        copy: true,
        onOpen: _open
      );
    }

    final text = S.of(context);
    final catalog = context.watch<CountryCatalogService>();
    final scheme = ThemeColor.of(context);
    final radius = EmployeeFactFrame.radius;

    return EmployeeEditFrame(
      icon: widget.icon,
      label: widget.label,
      saving: _saving,
      changed: _value != widget.value,
      onConfirm: _commit,
      onCancel: _close,
      onOutside: _outside,
      field: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: AppSize.action * 2.6, child: SelectInput(
            controller: _code,
            options: [
              for (final country in catalog.countries)
                if (country.phone.isNotEmpty) SelectOption(
                  value: country.code,
                  placeholder: country.dial,
                  subtitle: country.name,
                  leading: CountryFlag(country: country)
                )
            ],
            placeholder: text.employee_edit_phone_code,
            emptyText: text.employee_edit_no_match,
            buttonSpace: false,
            fillColor: scheme.surface,
            radius: radius,
            onSelected: (option) => setState(() => _country = option.value)
          )),
          SizedBox(width: AppSize.gap),
          Expanded(child: Input(
            controller: _number,
            placeholder: text.employee_edit_phone_number,
            buttonSpace: false,
            autofocus: true,
            fillColor: scheme.surface,
            radius: radius,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction(_trunk),
              LengthLimitingTextInputFormatter(PhonePlan.of(_dial).max)
            ],
            onSubmit: _commit
          ))
        ]
      )
    );
  }

  /// The chosen code's digits, empty while none is.
  String get _dial => CountryCatalogService().byCode(_country)?.phone ?? "";

  /// Drops the trunk zeros as they are typed or pasted, keeping the caret
  /// where it was among the digits left.
  TextEditingValue _trunk(TextEditingValue before, TextEditingValue after) {
    final text = PhonePlan.national(_dial, after.text);
    final dropped = after.text.length - text.length;
    if (dropped == 0) return after;

    final caret = (after.selection.baseOffset - dropped).clamp(0, text.length);

    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret));
  }

  /// Redraws on each key: the check comes and goes with the change.
  void _typed() {
    if (_editing && mounted) setState(() {});
  }

  void _open() {
    final catalog = CountryCatalogService();
    final saved = catalog.byPhone(widget.value);

    _country = saved?.code ?? (widget.value.isEmpty ? widget.country : "");
    // A value, not a label: the select finds its option when it mounts.
    _code.selectedValue = _country;
    // A phone saved before the check (`+580412…`) opens already mended: the
    // check shows, and saving it is one press.
    _number.textController.text = PhonePlan.national(saved?.phone ?? "", catalog.splitPhone(widget.value).number);

    setState(() => _editing = true);
    const EmployeeWiden(true).dispatch(context);
  }

  /// The press is read before the focus moves, so a code list still open
  /// means the press may be on one of its options, drawn outside the tile.
  void _outside() {
    if (_editing && !_saving && !_code.focus.hasFocus) _close();
  }

  void _close() {
    const EmployeeWiden(false).dispatch(context);
    setState(() => _editing = false);
  }

  /// The phone as it travels. No number is no phone, whatever the code.
  String get _value {
    final dial = _dial;
    final number = PhonePlan.national(dial, _number.text);
    if (number.isEmpty) return "";

    return dial.isEmpty ? number : "+$dial$number";
  }

  Future<void> _commit() async {
    if (!_editing || _saving) return;

    final value = _value;

    if (value == widget.value) return _close();

    if (value.isNotEmpty) {
      final text = S.of(context);
      final dial = _dial;
      final plan = PhonePlan.of(dial);

      final problem = dial.isEmpty
        ? text.employee_edit_phone_no_code
        : plan.fits(PhonePlan.national(dial, _number.text))
          ? null
          : plan.min == plan.max
            ? text.employee_edit_phone_digits("+$dial", plan.min)
            : text.employee_edit_phone_digits_range("+$dial", plan.min, plan.max);

      if (problem != null) {
        FloatFlag.of(context).alert(message: problem);
        _number.focus.requestFocus();
        return;
      }
    }

    setState(() => _saving = true);
    _form.loading.value = true;

    final saved = await widget.onSave(value);

    if (!mounted) return;

    _form.loading.value = false;
    setState(() => _saving = false);

    saved ? _close() : _number.focus.requestFocus();
  }
}
