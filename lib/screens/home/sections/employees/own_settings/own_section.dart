import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_detail/_employee_detail.dart';

import './own_history.dart';
import './own_notifications.dart';
import './own_preferences.dart';
import './own_privacy.dart';
import './own_security.dart';
import './own_sessions.dart';
import './own_sign_in_methods.dart';

/// The subsections of the viewer's own account (app area `account`): what is theirs and no
/// administrator manages. Each is a row of their own card's detail page, after the parts of their
/// job, and opens a page of its own; each is a URL, on the same criteria as `EmployeePart`.
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

  /// Key of the [ScreenRoute] of this subsection.
  String get routeKey => "employee_account_$name";

  /// URL of this subsection: always on the viewer's own card (`/home/employees/me/security`), the
  /// only one it is shown on.
  String get path => "${EmployeeDetailPage.path(BusinessEmployeeModel.meKey)}/$name";

  static final Map<String, OwnSection> _byRouteKey = {
    for (final section in values) section.routeKey: section
  };

  static OwnSection? byRouteKey(String key) => _byRouteKey[key];
}
