import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart' show DateFormat;

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_edit_button.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_edit_frame.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';

import './_employee_facts.dart';
import './employee_fact.dart';

/// A day edited in its three parts: the day and the year typed as digits and
/// the month chosen by name. Typed whole, the order of a date is a guess
/// (`03/04` is March or April depending on who writes it); apart, it is not.
///
/// It travels as `yyyy-MM-dd`, the backend's shape. All three empty erases
/// it; a day that does not exist (Feb 30) is refused before it travels.
///
/// It asks for the whole row while open ([EmployeeWiden]): three fields and
/// the check do not fit in half of it.
class EmployeeDateFact extends StatefulWidget implements EmployeeTile {
  const EmployeeDateFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.day,
    required this.onSave,
    this.empty,
    this.enabled = true,
    this.validate
  });

  final IconData icon;
  @override
  final String label;

  /// What the tile reads ("Mar 4, 2024").
  @override
  final String value;

  /// The saved day, or `null`.
  final DateTime? day;

  final String? empty;
  final bool enabled;

  /// Checks a real day against the others it depends on (a contract does
  /// not end before it starts): the message to show, or `null` when it can
  /// be sent. Never called for an erased day.
  final String? Function(DateTime day)? validate;

  /// Sends the day as `yyyy-MM-dd`; an empty one erases it.
  final Future<bool> Function(String day) onSave;

  @override
  bool get wide => false;

  @override
  State<EmployeeDateFact> createState() => _EmployeeDateFactState();
}

class _EmployeeDateFactState extends State<EmployeeDateFact> {
  final _form = FormController();
  late final _day = InputController(key: "day", form: _form, type: InputType.numeric);
  late final _month = InputController.select(key: "month", form: _form);
  late final _year = InputController(key: "year", form: _form, type: InputType.numeric);

  bool _editing = false;
  bool _saving = false;

  /// Whether the last build drew the tile as changed. A key rebuilds the tile
  /// only when that flips — the check comes or goes — not on every letter.
  bool _drawnChanged = false;

  /// The chosen month, 1 to 12, or `0` for none. Kept here: the select
  /// resolves its option only once it is mounted.
  int _chosen = 0;

  @override
  void initState() {
    super.initState();
    _day.textController.addListener(_typed);
    _year.textController.addListener(_typed);
  }

  @override
  void dispose() {
    _day.textController.removeListener(_typed);
    _year.textController.removeListener(_typed);
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return EmployeeFact(icon: widget.icon, label: widget.label, value: widget.value, empty: widget.empty);
    }

    if (!_editing) {
      return EmployeeEditButton(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        empty: widget.empty,
        onOpen: _open
      );
    }

    final text = S.of(context);
    final scheme = ThemeColor.of(context);
    final radius = EmployeeFactFrame.radius;
    final names = DateFormat.MMMM(Localizations.localeOf(context).toString());

    return EmployeeEditFrame(
      icon: widget.icon,
      label: widget.label,
      saving: _saving,
      // A day that does not exist is a change too: the check says why.
      changed: _drawnChanged = _changed,
      onConfirm: _commit,
      onCancel: _close,
      onOutside: _outside,
      field: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: AppSize.action * 1.5, child: Input(
            controller: _day,
            placeholder: text.employee_edit_day,
            buttonSpace: false,
            autofocus: true,
            fillColor: scheme.surface,
            radius: radius,
            formatters: [LengthLimitingTextInputFormatter(2)],
            next: _month.focus
          )),
          SizedBox(width: AppSize.gap),
          Expanded(child: SelectInput(
            controller: _month,
            options: [
              for (var month = 1; month <= 12; month++)
                SelectOption(value: "$month", placeholder: names.format(DateTime(2000, month)))
            ],
            placeholder: text.employee_edit_month,
            emptyText: text.employee_edit_no_match,
            buttonSpace: false,
            fillColor: scheme.surface,
            radius: radius,
            onSelected: (option) {
              setState(() => _chosen = int.tryParse(option.value) ?? 0);
              _year.focus.requestFocus();
            }
          )),
          SizedBox(width: AppSize.gap),
          SizedBox(width: AppSize.action * 2, child: Input(
            controller: _year,
            placeholder: text.employee_edit_year,
            buttonSpace: false,
            fillColor: scheme.surface,
            radius: radius,
            formatters: [LengthLimitingTextInputFormatter(4)],
            onSubmit: _commit
          ))
        ]
      )
    );
  }

  void _typed() {
    if (_editing && mounted && _changed != _drawnChanged) setState(() {});
  }

  bool get _changed => _value != _saved;

  void _open() {
    final day = widget.day;

    _day.textController.text = day == null ? "" : "${day.day}";
    _year.textController.text = day == null ? "" : "${day.year}";
    _chosen = day?.month ?? 0;
    // A value, not a label: the select finds its option when it mounts.
    _month.selectedValue = _chosen == 0 ? "" : "$_chosen";

    setState(() => _editing = true);
    const EmployeeWiden(true).dispatch(context);
  }

  /// The press is read before the focus moves, so a month list still open
  /// means the press may be on one of its options, drawn outside the tile.
  void _outside() {
    if (_editing && !_saving && !_month.focus.hasFocus) _close();
  }

  void _close() {
    const EmployeeWiden(false).dispatch(context);
    setState(() => _editing = false);
  }

  String get _saved => widget.day == null ? "" : DateFormat("yyyy-MM-dd").format(widget.day!);

  /// The day as it travels, `""` for none, or `null` when it is not a day.
  String? get _value {
    final day = int.tryParse(_day.text.trim());
    final year = int.tryParse(_year.text.trim());

    if (day == null && year == null && _chosen == 0) return "";
    if (day == null || year == null || _chosen == 0 || year < 1900 || year > 2100) return null;

    final date = DateTime(year, _chosen, day);

    // `DateTime` rolls Feb 30 over into March; a real day keeps its parts.
    if (date.day != day || date.month != _chosen) return null;

    return DateFormat("yyyy-MM-dd").format(date);
  }

  Future<void> _commit() async {
    if (!_editing || _saving) return;

    final value = _value;

    if (value == null) {
      FloatFlag.of(context).alert(message: S.of(context).employee_edit_invalid_day);
      return;
    }

    if (value == _saved) return _close();

    final problem = value.isEmpty ? null : widget.validate?.call(DateTime.parse(value));

    if (problem != null) {
      FloatFlag.of(context).alert(message: problem);
      return;
    }

    setState(() => _saving = true);
    _form.loading.value = true;

    final saved = await widget.onSave(value);

    if (!mounted) return;

    _form.loading.value = false;
    setState(() => _saving = false);

    if (saved) _close();
  }
}
