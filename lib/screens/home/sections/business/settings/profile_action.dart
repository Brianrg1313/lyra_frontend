import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES

// WIDGETS

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
