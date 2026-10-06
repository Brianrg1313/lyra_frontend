import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// A setting that is part of the account but has no backend yet: named, explained, and marked
/// "coming soon" instead of drawn as a switch that would do nothing.
class OwnSoon extends StatelessWidget {
  const OwnSoon({super.key, required this.icon, required this.label, this.hint});

  final IconData icon;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) => SettingsRow(
    icon: icon,
    label: label,
    hint: hint,
    child: Align(
      alignment: Alignment.centerLeft,
      child: SettingsTag(label: S.of(context).account_soon, color: ThemeColor.of(context).text.secondary)
    )
  );
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

    return SettingsBlock(
      title: s.account_notifications_title,
      subtitle: s.account_notifications_subtitle,
      child: SettingsList(rows: [
        OwnSoon(icon: CI.notification, label: s.account_notifications_app, hint: s.account_notifications_app_hint),
        OwnSoon(icon: CI.mail, label: s.account_notifications_email, hint: s.account_notifications_email_hint),
        OwnSoon(icon: CI.shop_mobile, label: s.account_notifications_push, hint: s.account_notifications_push_hint)
      ])
    );
  }
}

/// What of the person's own optional data their company sees. No backend yet: today the
/// employees' `view_personal` permission decides it alone.
class OwnPrivacy extends StatelessWidget {
  const OwnPrivacy({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SettingsBlock(
      title: s.account_privacy_title,
      subtitle: s.account_privacy_subtitle,
      child: SettingsList(rows: [
        OwnSoon(icon: CI.eye_hidden, label: s.account_privacy_details, hint: s.account_privacy_details_hint),
        OwnSoon(icon: CI.employee_badge, label: s.account_privacy_presence, hint: s.account_privacy_presence_hint)
      ])
    );
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
