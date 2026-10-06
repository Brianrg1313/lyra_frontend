import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/account/account_security_service.dart';

// WIDGETS
import 'package:app/screens/modals/business/employee_tool/_employee_tool.dart';

import './own_history.dart';
import './own_preferences.dart';
import './own_security.dart';
import './own_sessions.dart';
import './own_soon.dart';

/// The subsections of one's own settings. Each is a row of the panel's index and opens its own
/// side panel over it; [settings] are what the index's search finds it by.
enum OwnSection {
  security,
  methods,
  sessions,
  preferences,
  history,
  notifications,
  privacy;

  IconData get icon => switch (this) {
    security => CI.safe_password,
    methods => CI.link,
    sessions => CI.shop_mobile,
    preferences => CI.brightness,
    history => CI.shop,
    notifications => CI.notification,
    privacy => CI.eye_hidden
  };

  /// Nothing in it works yet: listed apart, after the rest, with its tag.
  bool get soon => this == notifications || this == privacy;

  String title(S s) => switch (this) {
    security => s.account_security_title,
    methods => s.account_methods_title,
    sessions => s.account_sessions_title,
    preferences => s.account_preferences_title,
    history => s.account_history_title,
    notifications => s.account_notifications_title,
    privacy => s.account_privacy_title
  };

  String subtitle(S s) => switch (this) {
    security => s.account_security_subtitle,
    methods => s.account_methods_subtitle,
    sessions => s.account_sessions_subtitle,
    preferences => s.account_preferences_subtitle,
    history => s.account_history_subtitle,
    notifications => s.account_notifications_subtitle,
    privacy => s.account_privacy_subtitle
  };

  Widget get body => switch (this) {
    security => const OwnSecurity(),
    methods => const OwnSignInMethods(),
    sessions => const OwnSessions(),
    preferences => const OwnPreferences(),
    history => const OwnHistory(),
    notifications => const OwnNotifications(),
    privacy => const OwnPrivacy()
  };

  /// The rows the subsection draws, by the words they are drawn with: a search for "language"
  /// leads to Preferences without knowing that is where it lives.
  List<OwnSetting> settings(S s) => switch (this) {
    security => [
      OwnSetting(this, CI.key, s.account_password),
      OwnSetting(this, CI.safe_password, s.account_two_factor, s.account_two_factor_hint),
      OwnSetting(this, CI.documents, s.account_recovery_codes, s.account_recovery_hint),
      OwnSetting(this, CI.sms, s.account_sms, s.account_sms_hint),
      OwnSetting(this, CI.mail, s.account_recovery_emails, s.account_recovery_emails_hint)
    ],
    methods => [
      OwnSetting(this, CI.mail, s.account_methods_email, s.account_methods_email_hint),
      OwnSetting(this, CI.link, s.account_methods_linked, s.account_methods_linked_hint)
    ],
    sessions => [
      OwnSetting(this, CI.shop_mobile, s.account_sessions_this, s.sign_out),
      OwnSetting(this, CI.network, s.account_sessions_others, s.account_sessions_others_hint)
    ],
    preferences => [
      OwnSetting(this, CI.globe_shopping, s.account_language),
      OwnSetting(this, CI.brightness, s.account_theme)
    ],
    history => [],
    notifications => [
      OwnSetting(this, CI.notification, s.account_notifications_app, s.account_notifications_app_hint),
      OwnSetting(this, CI.mail, s.account_notifications_email, s.account_notifications_email_hint),
      OwnSetting(this, CI.shop_mobile, s.account_notifications_push, s.account_notifications_push_hint)
    ],
    privacy => [
      OwnSetting(this, CI.eye_hidden, s.account_privacy_details, s.account_privacy_details_hint),
      OwnSetting(this, CI.employee_badge, s.account_privacy_presence, s.account_privacy_presence_hint)
    ]
  };

  /// Opens the subsection over the index. The account's services are the index's (it reads them
  /// once, when it opens), handed on to the stacked panel, which is another route.
  Future<void> open(BuildContext context) {
    final security = context.read<AccountSecurityService>();
    final history = context.read<AccountHistoryService>();
    final width = employeeToolWidth(context);

    return showSideModal(
      context: context,
      title: title(S.of(context)),
      minWidth: width,
      maxWidth: width,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: security),
          ChangeNotifierProvider.value(value: history)
        ],
        child: OwnSectionPage(section: this)
      )
    );
  }
}

/// One row of a subsection, as the search finds it.
class OwnSetting {
  const OwnSetting(this.section, this.icon, this.label, [this.hint]);

  final OwnSection section;
  final IconData icon;
  final String label;
  final String? hint;

  /// Whether each of [words] (already [fold]ed) is in its label, its hint or its subsection's
  /// title, in any order: "step two" finds "Two-step verification".
  bool matches(List<String> words, String sectionTitle) {
    final text = fold("$label ${hint ?? ""} $sectionTitle");
    return words.every(text.contains);
  }

  /// Lower case without accents or hyphens, so a typed "codigo" or "two step" finds its row
  /// whichever language the copy is in.
  static String fold(String text) {
    const from = "áàäâéèëêíìïîóòöôúùüûñç-";
    const to = "aaaaeeeeiiiioooouuuunc ";

    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split("")) {
      final at = from.indexOf(char);
      buffer.write(at < 0 ? char : to[at]);
    }
    return buffer.toString();
  }
}

/// A subsection in its own panel: what it is for in one line, then its rows over one surface.
class OwnSectionPage extends StatelessWidget {
  const OwnSectionPage({super.key, required this.section});

  final OwnSection section;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: TextSmall(section.subtitle(s), lines: 3, color: ThemeColor.of(context).text.secondary)),
          if (section.soon) ...[
            SizedBox(width: AppSize.spaceXS),
            const OwnSoonTag()
          ]
        ]),
        SizedBox(height: AppSize.spaceS),
        Surface.over(
          padding: EdgeInsets.all(AppSize.spaceS),
          child: section.body
        )
      ]
    );
  }
}
