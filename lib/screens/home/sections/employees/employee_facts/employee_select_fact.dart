import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_fact_frame.dart';
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_fact_value.dart';
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_hint.dart';
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_hover.dart';
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_saving.dart';

import './_employee_facts.dart';
import './employee_fact.dart';

/// A datum chosen from a list (the department, who they report to): a click
/// unfolds the options under the tile and choosing one saves it.
///
/// With [clearable], a "Not set" option erases it. With [creatable] the list
/// also takes a new entry typed at its foot: the job titles and departments
/// are whatever the company calls them, the list only offers the ones in use.
class EmployeeSelectFact extends StatefulWidget implements EmployeeTile {
  const EmployeeSelectFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onSave,
    this.options = const [],
    this.loadOptions,
    this.empty,
    this.enabled = true,
    this.clearable = true,
    this.creatable = false,
    this.wide = false
  });

  final IconData icon;
  @override
  final String label;

  /// What the tile reads.
  @override
  final String value;

  /// The saved option's value, empty when there is none.
  final String selected;

  final List<SelectOption> options;

  /// Reads the options when the list opens, in place of [options]: for the
  /// ones another tab owns (the branches), which the panel alone never reads.
  final Future<List<SelectOption>> Function()? loadOptions;

  final String? empty;
  final bool enabled;
  final bool clearable;
  final bool creatable;

  @override
  final bool wide;

  /// Sends the chosen value; an empty one erases the datum.
  final Future<bool> Function(String value) onSave;

  @override
  State<EmployeeSelectFact> createState() => _EmployeeSelectFactState();
}

class _EmployeeSelectFactState extends State<EmployeeSelectFact> {
  /// A change on its way, or the options being read.
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return EmployeeFact(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        empty: widget.empty,
        wide: widget.wide
      );
    }

    final scheme = ThemeColor.of(context);

    return EmployeeHover(builder: (context, hover) => FeedbackButton(
      action: _saving ? null : _pick,
      message: S.of(context).employee_edit_hint(widget.label),
      color: scheme.surface,
      feedbackColor: scheme.line,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: widget.icon,
        label: widget.label,
        trailing: _saving
          ? const EmployeeSaving()
          : EmployeeHint(
              shown: hover,
              child: Icon(CI.arrow_down, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary)
            ),
        child: EmployeeFactValue(value: widget.value, empty: widget.empty)
      )
    ));
  }

  Future<void> _pick() async {
    var options = widget.options;

    if (widget.loadOptions != null) {
      setState(() => _saving = true);
      options = await widget.loadOptions!();

      if (!mounted) return;

      setState(() => _saving = false);
    }

    final text = S.of(context);

    final picked = await showSelectMenu(
      context: context,
      options: [
        if (widget.clearable) SelectOption(value: "", placeholder: text.employee_value_none),
        ...options
      ],
      selected: widget.selected,
      emptyText: text.employee_edit_no_match,
      createText: widget.creatable ? text.employee_edit_create : null,
      createPlaceholder: widget.creatable ? text.employee_edit_create_hint(widget.label) : null,
      onCreate: widget.creatable ? _create : null
    );

    if (picked == null || picked.value == widget.selected || !mounted) return;

    setState(() => _saving = true);

    await widget.onSave(picked.value);

    if (mounted) setState(() => _saving = false);
  }

  /// A new entry is only a name: nothing is stored until it is chosen, which
  /// creating it already does.
  Future<SelectOption?> _create(String name) async {
    final value = name.trim();

    return value.isEmpty ? null : SelectOption(value: value, placeholder: value);
  }
}
