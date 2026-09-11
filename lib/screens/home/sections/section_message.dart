import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// Full-screen state: an icon, a message and, if there is something to do
/// about it, a button.
///
/// The home sections use it for the same things —did not load, there is
/// nothing yet, the search found nothing— and that is why it lives up here and
/// not inside one of them: it was the same widget written once per section.
class SectionMessage extends StatelessWidget {
  const SectionMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.actionIcon
  });

  final IconData icon;
  final String title;

  /// Second line, dimmer. Without it the message is just the title.
  final String? subtitle;

  /// What to do. Without [action] or without [actionLabel] the button is not
  /// drawn: there are states that only inform (a search without results has no
  /// action).
  final void Function()? action;
  final String? actionLabel;

  /// Icon of the button. It goes where the action adds something (create a
  /// table), not where it only retries.
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.action, color: scheme.text.secondary),
          SizedBox(height: AppSize.spaceS),
          TextMedium(title, bold: true, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              subtitle!,
              textAlign: TextAlign.center,
              color: scheme.text.secondary
            )
          ],
          if (action != null && actionLabel != null) ...[
            SizedBox(height: AppSize.spaceM),
            SizedBox(
              width: AppSize.action * 4,
              child: Button(
                title: actionLabel!,
                leftIcon: actionIcon == null
                  ? null
                  : Icon(actionIcon, color: scheme.button.text),
                action: action!
              )
            )
          ]
        ]
      )
    );
  }
}
