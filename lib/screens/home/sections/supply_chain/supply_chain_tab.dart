import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/modifiers/_modifiers.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/_recipes.dart';
import 'package:app/screens/home/sections/supply_chain/reports/_reports.dart';

/// The parts of the supply chain (`cocina-frontend.md`): what each product is made of, what a
/// customer chooses about it, and what the kitchen spent.
///
/// Each tab is a URL (`/home/supply_chain/recipes`), on the money page's criteria (see
/// `FinanceTab`): its own route key, no id — every kitchen endpoint answers for the active
/// company and branch.
enum SupplyChainTab {
  /// The supplies tables (its key is the permission area's, `kitchen.*` in the backend).
  recipes(key: "recipes", icon: CI.warehouse),
  modifiers(key: "modifiers", icon: CI.plus),
  reports(key: "reports", icon: CI.chart);

  const SupplyChainTab({required this.key, required this.icon});

  final String key;
  final IconData icon;

  /// The recipes: what a kitchen comes to the section for.
  static const SupplyChainTab initial = recipes;

  String get routeKey => "supply_chain_$key";

  /// Permission area (`docs/app-areas.json`): `supply_chain.<key>`.
  String get area => "supply_chain.$key";

  bool get isShown => CapabilityService().exists(area);
  bool get isReachable => CapabilityService().shows(area);

  static List<SupplyChainTab> get shown => values.where((tab) => tab.isShown).toList(growable: false);

  /// Tab the bare section opens: [initial], or the first one granted.
  static SupplyChainTab get opening {
    final permissions = PermissionsService();
    if (initial.isReachable && permissions.canOpen(initial.area)) return initial;

    return shown.firstWhere((tab) => tab.isReachable && permissions.canOpen(tab.area), orElse: () => initial);
  }

  String get path => "/home/supply_chain/$key";

  static final Map<String, SupplyChainTab> _byRouteKey = {
    for (final tab in values) tab.routeKey: tab
  };

  static SupplyChainTab? byRouteKey(String currentKey) => _byRouteKey[currentKey];

  String title(BuildContext context) => switch (this) {
    recipes => S.of(context).supply_chain_tab_recipes,
    modifiers => S.of(context).supply_chain_tab_modifiers,
    reports => S.of(context).supply_chain_tab_reports
  };

  /// Body of the tab, inside the page's surface: none brings its own.
  Widget build() => switch (this) {
    recipes => const RecipesTab(),
    modifiers => const ModifiersTab(),
    reports => const ReportsTab()
  };
}
