import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'business_field.dart';

/// Changes **one** data point of the business profile.
///
/// It is a single-field form on purpose: the profile is corrected where it is
/// read —the wrong row is touched and something is written—, not by opening the
/// whole form to change the phone. What is saved is only that field (see
/// [BusinessService.editProfile]).
///
/// It does not know which data point it is editing: whoever opens it describes
/// it ([field]) and everything comes from there —what shape it has, how long it
/// may be, whether it can be left empty—. Adding a text field to the profile
/// card is not touching this modal.
///
/// Only the data points that are **written** get here. The ones chosen from a
/// closed list (the sector, the language, the currency) are changed in their
/// own row, without a modal: choosing needs neither a keyboard nor a save
/// button (see `ProfileSelectField`).
///
/// It closes returning `true` when the change went through. The profile is not
/// returned: the service has already re-read it and the card repaints itself.
class EditBusinessFieldModal extends StatefulWidget {
  const EditBusinessFieldModal({
    super.key,
    required this.label,
    required this.field
  });

  /// What the data point is called in the card. It is the field title and what
  /// the errors are built with, so the form talks about the same data point as
  /// the row it was opened from.
  final String label;

  final BusinessField field;

  @override
  State<EditBusinessFieldModal> createState() => _EditBusinessFieldModalState();
}

class _EditBusinessFieldModalState extends State<EditBusinessFieldModal> {
  final _form = FormController();

  /// The controller is built from what the data point says: what is saved
  /// opens the field filled, and the rest —the shape, the length, whether it is
  /// obligatory— is what is validated when saving.
  late final _input = InputController(
    key: widget.field.key,
    form: _form,
    initial: widget.field.value,
    pattern: widget.field.pattern,
    type: widget.field.type,
    min: widget.field.min,
    max: widget.field.max,
    obligatory: widget.field.obligatory,
    customErrors: _errors
  );

  /// The errors name the data point as the card names it, not with a text per
  /// field: they are the same four as always and the only thing that changes
  /// is what they are talking about.
  Map<InputError, String> get _errors => {
    InputError.empty: S.of(context).form_empty_ma(widget.label),
    InputError.invalid: S.of(context).form_invalid_ma(widget.label),
    InputError.long: S.of(context).form_long_ma(widget.label),
    InputError.incomplete: S.of(context).form_incomplete_ma(widget.label)
  };

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Width of the form. It is fixed and not a maximum because the modal
  /// adjusts to what its content measures (see `ModalDesktop`), and a field of
  /// a short data point —a phone, a postal code— left it narrower than its own
  /// title. With a base width all data points are edited in the same box,
  /// whatever they measure. In a small window the dialog clips it on its own.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: widget.label,
          placeholder: widget.field.hint ?? widget.label,
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

    // The value is read from the controller and not from `_form.data`: that one
    // only gathers what was left written, and a field emptied —which is
    // erasing the data point— would never reach the backend.
    final value = _input.value;

    // Nothing to save. It closes without writing: a request and a profile
    // re-read to leave everything as it was is worse than doing nothing.
    if (value.trim() == widget.field.value.trim()) {
      Navigator.pop(context);
      return;
    }

    _form.loading.value = true;

    final saved = await context.read<BusinessService>().editProfile(
      context,
      widget.field.key,
      value
    );

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown in the service: the modal
    // stays open with what was written to correct it or close it by hand.
    if (!saved) return;

    // No save notice: the modal closes and the row behind already shows the
    // new value. Announcing what is being seen is a flag that covers part of
    // the card to tell something the card already told. The profile flags are
    // left for what **is not** seen: the errors.
    Navigator.pop(context, true);
  }
}