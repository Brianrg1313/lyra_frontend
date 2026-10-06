import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// A setting that is part of the account but has no backend yet: named and explained, never
/// drawn as a switch that would do nothing. Quieter than a working row (one muted line, no
/// separator, no tag of its own) so what can be used today is what the panel is read for;
/// [OwnSoonList] says "coming soon" once for the group.
class OwnSoon extends StatelessWidget {
  const OwnSoon({super.key, required this.icon, required this.label, this.hint, this.marks = const []});

  final IconData icon;
  final String label;
  final String? hint;

  /// Icons drawn after the label: the brands one row stands for.
  final List<IconData> marks;

  @override
  Widget build(BuildContext context) {
    final muted = ThemeColor.of(context).text.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: AppSize.gap * 0.3),
          child: Icon(icon, size: AppSize.text * 0.9, color: muted.withValues(alpha: 0.7))
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextSmall(label, ellipsis: true, color: muted)),
              for (final mark in marks) ...[
                SizedBox(width: AppSize.gap * 0.75),
                Icon(mark, size: AppSize.text * 0.85, color: muted.withValues(alpha: 0.7))
              ]
            ]),
            if (hint != null)
              TextSmall(hint!, lines: 2, ellipsis: true, color: muted.withValues(alpha: 0.7))
          ]
        ))
      ]
    );
  }
}

/// The [OwnSoon] rows of a block, close together under one "coming soon". [caption] is false
/// where the panel's lead line already carries the tag (a subsection with nothing working yet).
class OwnSoonList extends StatelessWidget {
  const OwnSoonList({super.key, required this.rows, this.caption = true});

  final List<OwnSoon> rows;
  final bool caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (caption) ...[
        const OwnSoonTag(),
        SizedBox(height: AppSize.spaceXS)
      ],
      for (int i = 0; i < rows.length; i++) ...[
        if (i > 0) SizedBox(height: AppSize.spaceXS),
        rows[i]
      ]
    ]
  );
}

/// "Coming soon", as the tag of a whole block or group.
class OwnSoonTag extends StatelessWidget {
  const OwnSoonTag({super.key});

  @override
  Widget build(BuildContext context) =>
    SettingsTag(label: S.of(context).account_soon, color: ThemeColor.of(context).text.secondary);
}

/// A row of the cloud account where the running mode has no cloud (a master without the
/// internet): said instead of hidden, since it is the person's and comes back with the internet.
class OwnOffline extends StatelessWidget {
  const OwnOffline({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SettingsRow(
    icon: icon,
    label: label,
    child: TextSmall(S.of(context).account_needs_internet, lines: 2, color: ThemeColor.of(context).text.secondary)
  );
}

/// What a person will decide about their notices: where they arrive. No backend yet.
class OwnNotifications extends StatelessWidget {
  const OwnNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OwnSoonList(caption: false, rows: [
      OwnSoon(icon: CI.notification, label: s.account_notifications_app, hint: s.account_notifications_app_hint),
      OwnSoon(icon: CI.mail, label: s.account_notifications_email, hint: s.account_notifications_email_hint),
      OwnSoon(icon: CI.shop_mobile, label: s.account_notifications_push, hint: s.account_notifications_push_hint)
    ]);
  }
}

/// What of the person's own optional data their company sees. No backend yet: today the
/// employees' `view_personal` permission decides it alone.
class OwnPrivacy extends StatelessWidget {
  const OwnPrivacy({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OwnSoonList(caption: false, rows: [
      OwnSoon(icon: CI.eye_hidden, label: s.account_privacy_details, hint: s.account_privacy_details_hint),
      OwnSoon(icon: CI.employee_badge, label: s.account_privacy_presence, hint: s.account_privacy_presence_hint)
    ]);
  }
}

/// A text action under a row's value: the panel reads, and its few actions are words, not a
/// column of buttons.
class OwnLink extends StatelessWidget {
  const OwnLink({super.key, required this.label, required this.action, this.danger = false});

  final String label;
  final void Function() action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = danger ? scheme.chart.critical : scheme.primary;

    return FeedbackButton(
      action: action,
      message: label,
      radius: AppSize.cornerInset(AppSize.gap),
      color: color.withValues(alpha: 0.08),
      feedbackColor: color.withValues(alpha: 0.18),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap * 0.8),
      child: TextMedium(label, multiplier: 0.9, bold: true, color: color)
    );
  }
}
