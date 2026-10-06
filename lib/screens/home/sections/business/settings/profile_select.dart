import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

import 'profile_field.dart';

/// A profile datum chosen from a closed list —the sector, the language, the
/// currency—, with the dropdown in the place of the value.
///
/// Choosing isn't typing: there's nothing to draft, nothing to validate, or an
/// error to read below. Opening a modal for that is three steps (open, choose,
/// save) where there's only one, and on top it covers the sheet the rest was
/// being looked at from. Here the chosen option **is** the value that's read,
/// and touching it unfolds the others in the same spot.
///
/// That's why it doesn't carry a save button either: choosing an option is the
/// change, so it's sent right there. While it travels, the field stays
/// disabled —[FormController.loading] does that— so nothing else is chosen on
/// top of what hasn't been saved yet.
///
/// If the save fails, the dropdown returns to what there was: the error is
/// already shown by the service, and leaving on screen an option the backend
/// didn't accept is the only way the sheet lies.
class ProfileSelectField extends StatefulWidget {
  const ProfileSelectField({
    super.key,
    required this.icon,
    required this.label,
    required this.field,
    this.description,
    this.badge
  });

  final IconData icon;
  final String label;

  /// The datum: which key it travels with, what's chosen today and between
  /// which options.
  final BusinessField field;

  final String? description;

  /// See [ProfileFieldFrame.badge].
  final BadgePlace? badge;

  @override
  State<ProfileSelectField> createState() => _ProfileSelectFieldState();
}

class _ProfileSelectFieldState extends State<ProfileSelectField> {
  final _form = FormController();

  /// The `initial` is the saved code (`RETAIL`) and not the label that's read:
  /// [SelectInput] translates it to its option on mount.
  late final _input = InputController.select(
    key: widget.field.key,
    form: _form,
    initial: widget.field.value,
    obligatory: true
  );

  /// The last thing the backend accepted. It's what it's compared against to
  /// know if there's something to send, and what's returned to if the send
  /// fails.
  late String _saved = widget.field.value;

  /// Changes every time the dropdown has to be rebuilt with what the controller
  /// says: when returning from a failed send, or when the datum changed from
  /// outside this row. [SelectInput] syncs on mount, so the only way it
  /// re-reads the value is for it to be a different widget.
  int _revision = 0;

  @override
  void didUpdateWidget(ProfileSelectField old) {
    super.didUpdateWidget(old);

    // The profile was re-read and this datum ended up different: it wasn't this
    // dropdown (there [_saved] would already be up to date), so it's aligned.
    // Without `setState`: the rebuild comes immediately after this.
    if (widget.field.value != _saved) _reset(widget.field.value);
  }

  @override
  void dispose() {
    // The form is of this row, so it frees the controller with it. The
    // dropdown doesn't touch it: it isn't its own, we lend it to it.
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: widget.icon,
    label: widget.label,
    description: widget.description,
    badge: widget.badge,
    child: ConstrainedBox(
      // The dropdown doesn't stretch with the column: it's a list of short
      // options (a language, a currency code) and a field the width of the
      // sheet leaves the label alone at one end and the arrow at the other.
      constraints: BoxConstraints(maxWidth: _fieldWidth),
      child: SelectInput(
        key: ValueKey("${widget.field.key}_${_saved}_$_revision"),
        controller: _input,
        options: widget.field.options,
        placeholder: S.of(context).business_profile_select,
        emptyText: S.of(context).business_profile_select_empty,
        radius: AppSize.cornerInset(AppSize.gap),
        // No room for the error below: the only thing that can go wrong here is
        // the send, and that's announced with the floating flag like the rest
        // of the profile's writes.
        buttonSpace: false,
        onSelected: _save
      )
    )
  );

  /// Width of the dropdown. It's a form field's, not the column's: so it
  /// measures the same in the wide sheet and the narrow one, and the three
  /// profile lists stay aligned with each other.
  static double get _fieldWidth => AppSize.action * 6;

  Future<void> _save(SelectOption option) async {
    // Choosing the same thing again isn't a change: the trip and the profile
    // re-read that would leave everything the same are avoided.
    if (option.value == _saved) return;

    final service = context.read<BusinessService>();

    _form.loading.value = true;

    final saved = await service.editProfile(
      context,
      widget.field.key,
      option.value
    );

    if (!mounted) return;

    _form.loading.value = false;

    if (!saved) {
      setState(() => _reset(_saved));
      return;
    }

    // Without a save notice: the chosen option stayed in the dropdown, which
    // is where the eyes were. What is announced is the failure, and the
    // service takes care of that.
    setState(() => _saved = option.value);
  }

  /// Leaves the dropdown showing [value]: it's written to the controller and
  /// it's rebuilt, which is the only thing that makes it read it again.
  void _reset(String value) {
    _saved = value;
    _input.selectedValue = value;
    _revision++;
  }
}
