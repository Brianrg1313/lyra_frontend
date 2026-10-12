import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Opens the editor of the company's sentence about delivery.
///
/// Returns what was written, trimmed —empty erases it—, or `null` when it was
/// closed without saving.
Future<String?> showDeliveryNotes(
  BuildContext context, {
  required String notes
}) {
  final label = S.of(context).business_delivery_notes;

  return showModal(
    context: context,
    title: notes.isEmpty
      ? S.of(context).business_profile_add(label)
      : S.of(context).business_profile_edit(label),
    builder: (context) => EditDeliveryNotesModal(notes: notes)
  ).then((value) => value is String ? value : null);
}

/// One field, like the profile's: a sentence is corrected where it is read.
///
/// It **returns the text and writes nothing**: the delivery service is
/// provided by the delivery settings panel, which this opens over and is not under.
class EditDeliveryNotesModal extends StatefulWidget {
  const EditDeliveryNotesModal({super.key, required this.notes});

  final String notes;

  @override
  State<EditDeliveryNotesModal> createState() => _EditDeliveryNotesModalState();
}

class _EditDeliveryNotesModalState extends State<EditDeliveryNotesModal> {
  final _form = FormController();

  /// The ceiling is the column's (`companies`.`delivery_notes`).
  late final _input = InputController(
    key: "NOTES",
    form: _form,
    initial: widget.notes,
    max: 255,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(
        S.of(context).business_delivery_notes
      )
    }
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// The profile's single-field width, for the same reason: the box does not
  /// narrow to a short value.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: S.of(context).business_delivery_notes,
          placeholder: S.of(context).business_delivery_notes_hint,
          controller: _input,
          autofocus: true,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(title: S.of(context).save, action: _submit)
      ]
    )
  );

  void _submit() {
    if (!_form.validate()) return;

    Navigator.pop(context, _input.value.trim());
  }
}
