import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, TextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/business/business_places_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/business/branch_form/place_search.dart';

import './employee_card.dart';

/// The detail's tiles that are edited where they are read, without a modal:
/// a click turns a typed datum into its field, and a chosen one unfolds its
/// options under the tile. Each saves on its own through `onSave`, which
/// answers once the backend kept it (the failure is already announced by the
/// service), so the tile shows what was saved, never what was only typed.
///
/// A typed change is sent with the check beside the field ([EmployeeConfirm])
/// or Enter, never by leaving it: a half-written phone or day is a valid text,
/// and clicking elsewhere is not saying it is finished. The check shows only
/// once something differs from what is saved: there is nothing to confirm
/// before that. A click outside the open tile drops the change and closes it,
/// like Escape ([EmployeeEditFrame.onOutside]).
///
/// With `enabled` off they are an [EmployeeFact], the same tile read-only:
/// the job is over, or the datum is the person's own.

/// A typed datum (a name, an email, an address): a click opens the field in
/// the tile itself; the check or Enter saves, Escape or a click outside
/// leaves it as it was.
///
/// With [onPlace] it is an address: what is typed is also searched on the
/// map (`/business/location/search/`), and picking a place fills the address
/// and the city, region, postal code and country in one save.
class EmployeeTextFact extends StatefulWidget implements EmployeeTile {
  const EmployeeTextFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onSave,
    this.initial,
    this.empty,
    this.hint,
    this.enabled = true,
    this.required = false,
    this.copy = false,
    this.wide = false,
    this.lines = 1,
    this.validate,
    this.formatters,
    this.onPlace,
    this.placesCountry = ""
  });

  final IconData icon;
  @override
  final String label;

  /// What the tile reads.
  @override
  final String value;

  /// What the field opens with, when it is not [value] (a salary is read as
  /// "$1,200.00" but typed as `1200`).
  final String? initial;

  final String? empty;

  /// Placeholder of the field; the [label] by default.
  final String? hint;

  final bool enabled;

  /// The backend refuses it erased (a name, the job title): an empty field is
  /// put back instead of sent.
  final bool required;

  final bool copy;

  @override
  final bool wide;

  final int lines;

  /// Checks the typed text before it travels: the message to show, or `null`
  /// when it can be sent.
  final String? Function(String text)? validate;

  /// What the field takes at all (digits only for a postal code).
  final List<TextInputFormatter>? formatters;

  /// Sends the trimmed text; an empty one erases the datum.
  final Future<bool> Function(String text) onSave;

  /// Saves a place picked from the map search; its presence is what turns
  /// the search on.
  final Future<bool> Function(PlaceModel place)? onPlace;

  /// ISO country the search is restricted to; empty for the company's.
  final String placesCountry;

  @override
  State<EmployeeTextFact> createState() => _EmployeeTextFactState();
}

class _EmployeeTextFactState extends State<EmployeeTextFact> {
  final _form = FormController();
  late final _input = InputController(key: "value", form: _form);

  bool _editing = false;
  bool _saving = false;

  /// The map search of an address, alive while its field is open: it holds
  /// the session Google bills the typing and the pick under.
  BusinessPlacesService? _places;

  String get _raw => widget.initial ?? widget.value;

  @override
  void initState() {
    super.initState();
    _input.textController.addListener(_typed);
  }

  @override
  void dispose() {
    _input.textController.removeListener(_typed);
    _places?.dispose();
    // The form is this tile's, so it frees the controller with it.
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
        copy: widget.copy,
        wide: widget.wide,
        lines: widget.lines
      );
    }

    if (!_editing) {
      return EmployeeEditButton(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        empty: widget.empty,
        copy: widget.copy,
        lines: widget.lines,
        onOpen: _open
      );
    }

    final scheme = ThemeColor.of(context);
    final places = _places;

    final field = Input(
      controller: _input,
      placeholder: widget.hint ?? widget.label,
      buttonSpace: false,
      autofocus: true,
      fillColor: scheme.surface,
      radius: EmployeeFactFrame.radius,
      formatters: widget.formatters,
      onSubmit: _commit
    );

    return EmployeeEditFrame(
      icon: widget.icon,
      label: widget.label,
      saving: _saving,
      changed: _changed,
      onConfirm: _commit,
      onCancel: _close,
      onOutside: _outside,
      field: places == null
        ? field
        : PlaceSearch(controller: _input, places: places, onPicked: _picked, child: field)
    );
  }

  bool get _changed => _input.text.trim() != _raw.trim();

  /// Redraws on each key: the check comes and goes with [_changed].
  void _typed() {
    if (_editing && mounted) setState(() {});
  }

  void _open() {
    _input.textController.text = _raw;

    if (widget.onPlace != null) {
      _places = BusinessPlacesService(restrictTo: widget.placesCountry);
    }

    setState(() => _editing = true);
  }

  void _close() {
    // After the frame: the search's dropdown may still be listening to it.
    final places = _places;
    _places = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => places?.dispose());

    setState(() => _editing = false);
  }

  /// Not while the address suggestions hang under the field: they are drawn
  /// outside the tile, and the click may be the pick. That click closes the
  /// list; the next one outside closes the tile.
  void _outside() {
    if (!_editing || _saving) return;

    final listed = switch (_places?.status) {
      BusinessPlacesStatus.searching ||
      BusinessPlacesStatus.ready ||
      BusinessPlacesStatus.empty ||
      BusinessPlacesStatus.error => true,
      _ => false
    };

    if (!listed) _close();
  }

  Future<void> _commit() async {
    if (!_editing || _saving) return;

    final text = _input.text.trim();

    if (text == _raw.trim()) return _close();

    final problem = widget.required && text.isEmpty
      ? S.of(context).employee_edit_required(widget.label)
      : text.isEmpty ? null : widget.validate?.call(text);

    if (problem != null) {
      FloatFlag.of(context).alert(message: problem);
      _input.focus.requestFocus();
      return;
    }

    _places?.clear();
    await _send(() => widget.onSave(text));
  }

  /// A place from the search: read it whole, then save it in one go.
  Future<void> _picked(PlaceSuggestion suggestion) async {
    final places = _places;
    if (places == null || _saving) return;

    setState(() => _saving = true);

    PlaceModel? place;

    try {
      place = await places.select(suggestion);
    } catch (_) {
      place = null;
    }

    places.clear();

    if (!mounted) return;

    if (place == null || place.isEmpty) {
      setState(() => _saving = false);
      FloatFlag.of(context).alert(message: S.of(context).employee_edit_place_failed);
      _input.focus.requestFocus();
      return;
    }

    _input.textController.text = place.address;
    setState(() => _saving = false);

    final picked = place;
    await _send(() => widget.onPlace!(picked));
  }

  Future<void> _send(Future<bool> Function() save) async {
    setState(() => _saving = true);
    _form.loading.value = true;

    final saved = await save();

    if (!mounted) return;

    _form.loading.value = false;
    setState(() => _saving = false);

    // Refused: the field stays open with what was typed, to be fixed.
    saved ? _close() : _input.focus.requestFocus();
  }
}

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

/// A closed typed tile: its value and, under the pointer, a copy button when
/// [copy] and the pencil that says a click edits it.
class EmployeeEditButton extends StatelessWidget {
  const EmployeeEditButton({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onOpen,
    this.empty,
    this.copy = false,
    this.lines = 1
  });

  final IconData icon;
  final String label;
  final String value;
  final String? empty;
  final bool copy;
  final int lines;
  final void Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final copyable = copy && value.trim().isNotEmpty;

    return EmployeeHover(builder: (context, hover) => FeedbackButton(
      action: onOpen,
      message: S.of(context).employee_edit_hint(label),
      color: scheme.surface,
      feedbackColor: scheme.line,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: icon,
        label: label,
        trailing: EmployeeHint(
          shown: hover,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (copyable) ...[
                _Copy(value: value, label: label),
                SizedBox(width: AppSize.gap * 0.5)
              ],
              Icon(CI.edit, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary)
            ]
          )
        ),
        child: EmployeeFactValue(value: value, empty: empty, lines: lines)
      )
    ));
  }
}

/// An open typed tile: its [field] (one input, or several in a row) and, once
/// it is [changed], the check that sends it. It is the one cell of the panel
/// in the brand color, lifted over its sheet: while a datum is open, it is
/// the only thing on the panel that is not settled. Escape anywhere inside it calls
/// [onCancel]; a press anywhere outside it calls [onOutside].
///
/// Outside is told apart by where the press lands ([TapRegion]), not by the
/// focus: a select inside the tile (a phone's code, a day's month) drops the
/// focus on purpose once an option is picked, and the tile must stay open.
class EmployeeEditFrame extends StatelessWidget {
  const EmployeeEditFrame({
    super.key,
    required this.icon,
    required this.label,
    required this.field,
    required this.saving,
    required this.changed,
    required this.onConfirm,
    required this.onCancel,
    required this.onOutside
  });

  final IconData icon;
  final String label;
  final Widget field;
  final bool saving;

  /// Something differs from what is saved; also kept while [saving].
  final bool changed;
  final void Function() onConfirm;
  final void Function() onCancel;

  /// A press outside the tile. The tile decides: a dropdown of its own is
  /// drawn outside it too, and a press there is not leaving.
  final void Function() onOutside;

  @override
  Widget build(BuildContext context) => TapRegion(
    onTapOutside: (_) => onOutside(),
    child: _tile(context)
  );

  Widget _tile(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.line(
      color: scheme.surfaceOver,
      borderColor: scheme.primary,
      thickness: 1,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: icon,
        label: label,
        accent: scheme.primary,
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field),
              if (changed || saving) ...[
                SizedBox(width: AppSize.gap),
                EmployeeConfirm(saving: saving, action: onConfirm)
              ]
            ]
          )
        )
      )
    );
  }
}

/// The square check beside an open field, as tall as the field: it is what
/// sends the change, so leaving the field never has to.
class EmployeeConfirm extends StatelessWidget {
  const EmployeeConfirm({super.key, required this.saving, required this.action});

  final bool saving;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: saving ? null : action,
      message: S.of(context).employee_edit_confirm,
      width: AppSize.action,
      height: AppSize.action,
      radius: EmployeeFactFrame.radius,
      color: scheme.button.fill,
      feedbackColor: scheme.button.overFill,
      child: Center(child: saving
        ? const EmployeeSaving()
        : Icon(CI.check, size: EmployeeFactFrame.iconSize, color: scheme.button.text))
    );
  }
}

/// Copies a tile's value without opening its field.
class _Copy extends StatelessWidget {
  const _Copy({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 1.9;

    return FeedbackButton(
      action: () => employeeCopy(context, value, label),
      message: S.of(context).employee_copy,
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap, AppSize.gap * 1.5),
      color: scheme.surface,
      feedbackColor: scheme.line,
      child: Center(child: Icon(CI.copy, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary))
    );
  }
}

/// The small spinner of a tile whose change is on its way.
class EmployeeSaving extends StatelessWidget {
  const EmployeeSaving({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSize.text,
    child: const FittedBox(child: Loading())
  );
}
