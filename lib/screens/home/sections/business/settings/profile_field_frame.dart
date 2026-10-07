import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_mark.dart';

import './profile_action.dart';
import './profile_field.dart';

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
    this.action,
    this.badge
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

  /// The badges this one datum answers (no country yet), drawn next to its name: the settings
  /// tab is long, and the dot on its tab only says that *something* in it is missing.
  final BadgePlace? badge;

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
          if (badge != null) Padding(
            padding: EdgeInsets.only(left: AppSize.gap),
            child: BadgeMark(place: badge!, dot: true)
          ),
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
