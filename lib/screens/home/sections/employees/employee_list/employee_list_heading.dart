import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// What the panel is, how many it holds, and the button that invites one more:
/// the list's bar, titled like the inbox's.
class EmployeeListHeading extends StatelessWidget {
  const EmployeeListHeading({
    super.key,
    required this.counts,
    required this.active,
    required this.invited,
    required this.onInvite
  });

  final bool counts;
  final int active;
  final int invited;

  /// `null` hides the button: inviting needs `business.employees.invite`.
  final void Function()? onInvite;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final text = S.of(context);

    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextLarge(text.employees_title, ellipsis: true),
          if (counts) ...[
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              [
                text.employees_active_count(active),
                if (invited > 0) text.employees_invited_count(invited)
              ].join(" · "),
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        ]
      )),
      if (onInvite != null) ...[
        SizedBox(width: AppSize.spaceS),
        Button(
          width: null,
          title: text.employees_invite,
          leftIcon: Icon(CI.plus, color: scheme.button.text),
          action: onInvite!
        )
      ]
    ]);
  }
}
