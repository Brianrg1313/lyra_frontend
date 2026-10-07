import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/business/business_places_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_confirm.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_edit_button.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_edit_frame.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';
import 'package:app/screens/modals/business/branch_form/place_search.dart';

import './_employee_facts.dart';
import './employee_fact.dart';

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
