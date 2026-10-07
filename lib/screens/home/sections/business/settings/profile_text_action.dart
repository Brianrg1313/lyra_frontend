import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './profile_action.dart';

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
