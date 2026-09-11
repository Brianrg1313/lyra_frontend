import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/business/edit_business_field/_edit_business_field.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

/// The skeleton of a profile datum, top to bottom: which datum it is, what
/// it's for and how much it's worth.
///
/// It isn't a label-and-value row with the datum stuck to the right edge:
/// that forces crossing the screen to read each row and leaves no room to
/// explain anything. Here the datum is read in a single column —icon and name,
/// the explanation below, the value at the end— and the only thing left on the
/// right is what can be done with it.
///
/// The value is a [child] and not text because it isn't always something read:
/// the data chosen from a list bring their own dropdown there (see
/// `ProfileSelectField`). What's read is [ProfileField], which is this same
/// box with text inside.
///
/// The [description] is optional on purpose: it's written where the datum's
/// name isn't enough to know what's being loaded (which is the legal name,
/// where a customer who needs help writes) and left out where the name already
/// says it all. Explaining the obvious is as much noise as not explaining what
///'s needed.
class ProfileFieldFrame extends StatelessWidget {
  const ProfileFieldFrame({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.description,
    this.note,
    this.action
  });

  /// What the datum is recognized by at a glance, without reading its name. It's
  /// what lets the eye run down the column: emails are envelopes, dates
  /// calendars.
  final IconData icon;

  final String label;

  /// How much the datum is worth: the text saying what's saved, or what changes
  /// it when changing it means choosing from a list.
  final Widget child;

  /// What the datum is for, in one line. See the class's note.
  final String? description;

  /// Clarification next to the name, for what the datum has to say about
  /// itself and not about its value (that an email is the primary one). It
  /// goes up top and not next to the value because it qualifies the datum, not
  /// what it's worth today.
  final String? note;

  /// What can be done with the datum. On `null` the slot stays the same, so
  /// that the names measure the same in every row and the button column
  /// doesn't wander on its own.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Lowers the icon to the name's row: aligned to the top it would
          // hang above the first letter.
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Icon(icon, size: AppSize.text, color: scheme.text.secondary)
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context, scheme),
            if (description != null) ...[
              SizedBox(height: AppSize.gap / 2),
              TextSmall(
                description!,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ],
            SizedBox(height: AppSize.gap),
            child
          ]
        ))
      ]
    );
  }

  /// The name's row: what the datum is called on the left and what can be
  /// done with it on the right.
  Widget _title(BuildContext context, SchemeColor scheme) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Padding(
        // The same offset as the icon, for the same reason: the name coexists
        // with a button taller than its row.
        padding: EdgeInsets.only(top: AppSize.gap / 2),
        child: Row(children: [
          Flexible(child: TextMedium(label, bold: true, ellipsis: true)),
          if (note != null) ...[
            SizedBox(width: AppSize.gap),
            TextSmall(note!, color: scheme.primary)
          ]
        ])
      )),
      SizedBox(width: AppSize.gap),
      action ?? SizedBox(width: ProfileAction.size)
    ]
  );
}

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

/// A datum action written out in full letters.
///
/// It's for what has no icon that understands itself: adding an email is a
/// plus, but "make it the primary one" isn't any shape. An icon you have to
/// guess —or point at with the mouse to read its tooltip— is worse than the
/// text it was going to save.
///
/// The same height as [ProfileAction] and with the same idle rest: they coexist
/// in the same row, and either one taller or more painted would read as the
/// important one.
class ProfileTextAction extends StatelessWidget {
  const ProfileTextAction({
    super.key,
    required this.label,
    required this.action
  });

  /// What the button does. It's read twice: it's its text and also what it
  /// announces to the screen reader.
  final String label;

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: label,
      height: ProfileAction.size,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      // `min` so the button measures what its text measures: in the actions
      // row the width that arrives is what's left over, and a row that
      // stretches would take it all.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [TextSmall(label, color: scheme.primary)]
      )
    );
  }
}

/// Button for an action on a profile datum.
///
/// It's the size of the row and without fill until you point at it: they're one
/// per row and painted all the time would turn the sheet —which is for
/// reading— into a button board. The idle color is the card's, not
/// transparent, so that both ends of the [FeedbackButton] animation are
/// opaque.
class ProfileAction extends StatelessWidget {
  const ProfileAction({
    super.key,
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;

  /// What the button does. It's the only thing that names it: it carries no
  /// text.
  final String message;

  final void Function() action;

  /// Side of the button. It comes from the text's size and not from
  /// [AppSize.button] because it coexists with a row, not an actions bar.
  static double get size => AppSize.text * 2;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: message,
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Center(child: Icon(
        icon,
        size: AppSize.text,
        color: scheme.text.secondary
      ))
    );
  }
}
