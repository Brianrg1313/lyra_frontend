import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'table_detail_field.dart';

/// Changes **one** data point of a table header from its settings.
///
/// It is a single-field form, like the business profile one: the card is
/// corrected where it is read —the wrong row is touched and something is
/// written—, not by opening the whole form to change a word. What is saved is
/// only that field, with a partial write against
/// `PUT /inventory/products/builder/details/` (see [TableDetailService.edit]).
///
/// It is the difference with `RenameTableModal`, which is the form of the list
/// menu: there only the title is changed, which is the only part of the header
/// that is read without having entered the table.
///
/// It does not know which data point it is editing: whoever opens it describes
/// it ([field]) and everything comes from there —where it is read from, how
/// long it may be, whether it can be left empty, with what key it is saved—.
///
/// The service arrives by constructor and not from the tree: it is owned by
/// the settings screen, which provides it **inside** its page, and a dialog
/// mounts above the `Navigator`, where that provider is no longer there.
class EditTableDetailsModal extends StatefulWidget {
  const EditTableDetailsModal({
    super.key,
    required this.field,
    required this.service
  });

  final TableDetailField field;

  /// Where what is saved comes from and where what is written goes.
  final TableDetailService service;

  @override
  State<EditTableDetailsModal> createState() => _EditTableDetailsModalState();
}

class _EditTableDetailsModalState extends State<EditTableDetailsModal> {
  final _form = FormController();

  /// What the table had when the modal opened. It is kept apart from the
  /// service because it is compared against it at the end: if nothing changed,
  /// there is nothing to write.
  late final String _initial = widget.field.value(widget.service.detail);

  /// The controller is built from what the data point says: what is saved
  /// opens the field filled and the rest —the shape, the length, whether it is
  /// obligatory— is what is validated when saving.
  late final _input = InputController(
    key: "VALUE",
    form: _form,
    initial: _initial,
    pattern: widget.field.pattern,
    min: widget.field.min,
    max: widget.field.max,
    obligatory: widget.field.obligatory,
    customErrors: _errors
  );

  /// The errors name the data point as the card names it: they are the same
  /// four as always and the only thing that changes is what they are talking
  /// about.
  Map<InputError, String> get _errors {
    final label = widget.field.label(context);

    return {
      InputError.empty: S.of(context).form_empty_ma(label),
      InputError.invalid: S.of(context).form_invalid_ma(label),
      InputError.long: S.of(context).form_long_ma(label),
      InputError.incomplete: S.of(context).form_incomplete_ma(label)
    };
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Width of the form. Fixed and not a maximum, like the profile one: the
  /// modal adjusts to what its content measures, and a short title field would
  /// leave it narrower than its own button. In a small window the dialog clips
  /// it on its own.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: widget.field.label(context),
          placeholder: widget.field.placeholder(context),
          controller: _input,
          autofocus: true,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    // The value is read from the controller and not from `_form.data`: that
    // one only gathers what was left written, and a description emptied —which
    // is erasing it— would never reach the backend.
    final value = _input.value;

    // Nothing to save. It closes without writing: a write and a detail re-read
    // to leave everything as it was is worse than doing nothing.
    if (value.trim() == _initial.trim()) {
      Navigator.pop(context);
      return;
    }

    _form.loading.value = true;

    final saved = await widget.field.save(context, widget.service, value);

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown in the service: the modal
    // stays open with what was written to correct it or close it by hand.
    if (!saved) return;

    // The table list has its own copy of these two texts and does not find
    // out about anything: what was just written went through the settings
    // endpoint. Without this, going back to the list would show the old name
    // until the next full read.
    _syncList(value);

    // No save notice: the modal closes and the card behind already shows the
    // new value. Announcing what is being seen is a flag that covers part of
    // the screen to tell something the screen already told.
    Navigator.pop(context, true);
  }

  void _syncList(String value) {
    final tables = context.read<TablesService>();
    final id = widget.service.tableId;

    switch (widget.field) {
      case TableDetailField.title:
        tables.applyText(id, title: value);
      case TableDetailField.description:
        tables.applyText(id, description: value);
    }
  }
}