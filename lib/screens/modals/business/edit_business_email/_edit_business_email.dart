import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Creating and editing a business email address.
///
/// It is the same form for both things because they are the same three data
/// points: the address, what it is for and what it is called. The only thing
/// that changes is whether it opens empty ([email] in `null`) or with what is
/// saved.
///
/// Which one is the main one is not decided here: it is promoted from the
/// profile card, on the address that is to be ascended, which is where it can
/// be seen which one it is today.
///
/// It closes returning `true` when the change went through. The list is not
/// returned: the service has already re-read the profile and the card repaints
/// itself.
class EditBusinessEmailModal extends StatefulWidget {
  const EditBusinessEmailModal({super.key, this.email});

  /// The address being edited, or `null` to add one.
  final BusinessEmailModel? email;

  @override
  State<EditBusinessEmailModal> createState() => _EditBusinessEmailModalState();
}

class _EditBusinessEmailModalState extends State<EditBusinessEmailModal> {
  final _form = FormController();

  /// What `LABEL` accepts in the backend. The hyphen goes last and unescaped:
  /// anywhere else it would be a range between the two characters around it.
  static const _labelPattern = "[A-Za-z0-9 .,&'()/+üÜñáéíóúÑÁÉÍÓÚ-]";

  late final _address = InputController(
    key: "EMAIL",
    form: _form,
    initial: widget.email?.email ?? "",
    type: InputType.email,
    pattern: "[A-Za-z0-9_@.-]",
    min: 6,
    max: 255,
    obligatory: true,
    customErrors: _errors(S.of(context).business_email_address)
  );

  late final _purpose = InputController.select(
    key: "PURPOSE",
    form: _form,
    initial: (widget.email?.purpose ?? BusinessEmailPurpose.general).value,
    obligatory: true,
    customErrors: _errors(S.of(context).business_email_purpose)
  );

  late final _label = InputController(
    key: "LABEL",
    form: _form,
    initial: widget.email?.label ?? "",
    pattern: _labelPattern,
    max: 64,
    customErrors: _errors(S.of(context).business_email_label)
  );

  Map<InputError, String> _errors(String field) => {
    InputError.empty: S.of(context).form_empty_ma(field),
    InputError.invalid: S.of(context).form_invalid_ma(field),
    InputError.long: S.of(context).form_long_ma(field),
    InputError.incomplete: S.of(context).form_incomplete_ma(field)
  };

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// The same base width as the rest of the profile forms: they are opened
  /// from the same rows and one narrower than the previous one would be read
  /// as another type of window. See the note in `EditBusinessFieldModal`.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: S.of(context).business_email_address,
          placeholder: S.of(context).business_email_address_hint,
          controller: _address,
          autofocus: true
        ),
        SizedBox(height: AppSize.spaceS),
        SelectInput(
          title: S.of(context).business_email_purpose,
          placeholder: S.of(context).business_profile_select,
          emptyText: S.of(context).business_profile_select_empty,
          controller: _purpose,
          options: [
            for (final purpose in BusinessEmailPurpose.values) SelectOption(
              value: purpose.value,
              placeholder: purpose.label(context)
            )
          ]
        ),
        SizedBox(height: AppSize.spaceS),
        Input(
          title: S.of(context).business_email_label,
          placeholder: S.of(context).business_email_label_hint,
          controller: _label,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _form.loading,
          action: _submit
        )
      ]
    )
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    // The values are read from the controllers and not from `_form.data`: that
    // one only gathers what was left written, and a name removed —which is
    // taking the name away from the address— would never reach the backend.
    final data = {
      "EMAIL": _address.value.trim(),
      "PURPOSE": _purpose.value,
      "LABEL": _label.value.trim()
    };

    _form.loading.value = true;

    final service = context.read<BusinessService>();
    final current = widget.email;

    final saved = current == null
      ? await service.addEmail(context, data)
      : await service.editEmail(context, current.id, data);

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown in the service: the modal
    // stays open with what was written to correct it or close it by hand.
    if (!saved) return;

    // No save notice, like the rest of the profile writes: when the modal
    // closes the list already brings the new or corrected address. Only what
    // is not seen is announced, which are the errors.
    Navigator.pop(context, true);
  }
}