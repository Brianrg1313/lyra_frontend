import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/permissions_service.dart';

import './branches/_branches.dart';
import './clients/_clients.dart';
import './employees/_employees.dart';
import './settings/_settings.dart';
import './statistics/_statistics.dart';

/// The parts of a business that can be looked at from its page.
///
/// They are views of the **same** business —how it is doing, who works in it,
/// where it operates and from which branches, who it sells to and how it
/// is configured—, not different screens: that is why they are tabs of one page
/// and not side bar
/// sections. You switch from one to another without requesting the business
/// again or losing where you were.
///
/// Each tab **is a URL** (`/home/business/:id/statistics`): you can copy the
/// link of what is being looked at, open it directly and come back with the
/// browser's back button. That is why each one declares its [key] and its
/// [routeKey]: from there come both its route (see `routes`) and the
/// navigation between tabs, without the route table repeating this list.
///
/// It is written as an enum and not as a list of widgets for the same reason
/// as `HomeSection`: the tab bar, the title, the route and the body all come
/// from here, so adding a tab is adding a case and not touching four places.
enum BusinessTab {
  statistics(key: "statistics", icon: CI.chart),
  employees(key: "employees", icon: CI.employee),
  branches(key: "branches", icon: CI.shop),
  clients(key: "clients", icon: CI.user),
  settings(key: "settings", icon: CI.setting);

  const BusinessTab({required this.key, required this.icon});

  /// Last segment of the tab's URL, and the one with which the key of its route
  /// is built.
  final String key;

  final IconData icon;

  /// Tab with which the page opens: the statistics are what answer "how is this
  /// business doing", which is what one comes to see upon entering. The
  /// settings open when there is something to fix, not every time.
  static const BusinessTab initial = statistics;

  /// Key of the [ScreenRoute] of this tab.
  ///
  /// Each tab has its own —and they do not share a single route with a `:tab`
  /// as argument— because `Navis` notifies the screen change by `currentKey`:
  /// with one key for all, moving from one tab to another would change the URL
  /// without the shell knowing, and the page would keep showing the previous
  /// tab.
  String get routeKey => "business_$key";

  /// Permission area of this tab (`docs/app-areas.json`): `business.<key>`. Its `view` opens it.
  String get area => "business.$key";

  /// Tab the bare section opens: [initial], unless it is not granted in the active company,
  /// then the first one that is. With none granted it is [initial], which shows it is locked.
  static BusinessTab get opening {
    final permissions = PermissionsService();
    if (permissions.canOpen(initial.area)) return initial;

    return values.firstWhere((tab) => permissions.canOpen(tab.area), orElse: () => initial);
  }

  /// URL of this tab for the business [businessId]. It is the only source of
  /// the `url` of its route and of the link copied from the browser bar.
  String path(String businessId) => "/home/business/$businessId/$key";

  static final Map<String, BusinessTab> _byRouteKey = {
    for (final tab in values) tab.routeKey: tab
  };

  /// Tab shown on the screen [currentKey], or `null` if that screen is not a
  /// tab of a business.
  static BusinessTab? byRouteKey(String currentKey) => _byRouteKey[currentKey];

  String title(BuildContext context) => switch (this) {
    statistics => S.of(context).business_tab_statistics,
    employees => S.of(context).business_tab_employees,
    branches => S.of(context).business_tab_branches,
    clients => S.of(context).business_tab_clients,
    settings => S.of(context).business_tab_settings
  };

  /// Whether the tab draws its own surface. Split-panel tabs do, so they can
  /// inset a panel inside it; the page skips its single surface for them.
  bool get ownsSurface => this == employees;

  /// Body of the tab. It goes inside the page's surface, unless it
  /// [ownsSurface]: then what it draws is already its sheet.
  Widget build() => switch (this) {
    statistics => const BusinessStatisticsTab(),
    employees => const BusinessEmployeesTab(),
    branches => const BusinessBranchesTab(),
    clients => const BusinessClientsTab(),
    settings => const BusinessSettingsTab()
  };
}
