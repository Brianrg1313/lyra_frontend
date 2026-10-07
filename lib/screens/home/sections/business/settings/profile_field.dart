import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/business/edit_business_field/_edit_business_field.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

import './profile_action.dart';
import './profile_field_frame.dart';

/// A profile datum that's read: the written value and, when it can be changed,
/// the button to edit it.
///
/// The form that changes it is a single-field modal because writing asks for
/// room —a keyboard, an error below, a save button— and that doesn't fit in a
/// sheet's row. The data chosen don't go through there: they're changed where
/// they're read (`ProfileSelectField`).
///
/// An editable datum is drawn **even when empty**: nearly the whole profile is
/// optional and this row is the only place from which it's loaded, so hiding
/// it wouldn't be not showing a datum, it would be not letting it be loaded. In
/// that case it says there's nothing and the button becomes the add one. What's
/// not edited —what the platform writes— does disappear when missing: there the
/// row would offer nothing.
class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.description,
    this.note,
    this.field,
    this.selectable = false,
    this.trailing
  });

  final IconData icon;
  final String label;
  final String value;
  final String? description;
  final String? note;

  /// How the datum is edited, or `null` if it isn't edited from here: the
  /// legal status is granted by verification and the registration dates are
  /// set by the system.
  final BusinessField? field;

  /// Whether the value can be selected to copy it. It goes where the datum is
  /// used outside the app (the email, the site), not where it's only read.
  final bool selectable;

  /// Actions specific to the datum, when it has one besides being edited
  /// (copying the identifier, tapping it). They replace the edit button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: icon,
    label: label,
    description: description,
    note: note,
    action: _action(context),
    child: _value(context)
  );

  /// What the datum is worth, or that it's worth nothing. The notice goes in
  /// gray and in words: a dash or a blank row reads as the sheet having
  /// broken, not as that datum not having loaded yet.
  Widget _value(BuildContext context) {
    if (value.isEmpty) {
      return TextMedium(
        S.of(context).business_profile_empty,
        color: ThemeColor.of(context).text.secondary
      );
    }

    return TextMedium(value, lines: 3, ellipsis: true, selectable: selectable);
  }

  Widget? _action(BuildContext context) {
    if (trailing != null) return trailing;
    if (field == null) return null;

    // Over an empty row the pencil lies: there's nothing to correct. The same
    // action, with the name and icon of what will actually happen.
    return ProfileAction(
      icon: value.isEmpty ? CI.plus : CI.edit,
      message: _title(context),
      action: () => _edit(context)
    );
  }

  /// What the action on the datum is called: loading it if it isn't there,
  /// changing it if it is. It's the button's message and the form's title,
  /// which are the same sentence read twice.
  String _title(BuildContext context) => value.isEmpty
    ? S.of(context).business_profile_add(label)
    : S.of(context).business_profile_edit(label);

  /// Opens the datum's form. Whatever it changes is saved by the modal itself
  /// against the service, which re-reads the profile: nothing is left to do
  /// when it closes.
  Future<void> _edit(BuildContext context) => showModal(
    context: context,
    title: _title(context),
    builder: (BuildContext context) => EditBusinessFieldModal(
      label: label,
      field: field!
    )
  );
}
