import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

/// The inventory's tabs (`cocina-frontend.md` §2): its tables — products and supplies, one open
/// at a time — and the company's modifier groups.
///
/// Each tab is a URL, on the money page's criteria (see `FinanceTab`): no id, every endpoint
/// behind them answers for the active company. The tables tab is the section's own route and a
/// table's link (`/home/inventory/:id`) besides; the transfers page is a page of the tables, not
/// a tab.
enum InventoryTab {
  tables(key: "tables", icon: CI.shop),
  modifiers(key: "modifiers", icon: CI.plus);

  const InventoryTab({required this.key, required this.icon});

  final String key;
  final IconData icon;

  /// The routes the tables tab is open on: the section's and a table's link.
  static const List<String> _tableRoutes = ["inventory", "inventory_table_view"];

  String get routeKey => this == tables ? "inventory" : "inventory_$key";

  String get path => this == tables ? "/home/inventory" : "/home/inventory/$key";

  /// Permission and capability area (`docs/app-areas.json`): the section's own for the tables,
  /// `inventory.<key>` for the rest.
  String get area => this == tables ? "inventory" : "inventory.$key";

  bool get isShown => CapabilityService().exists(area);
  bool get isReachable => CapabilityService().shows(area);

  static List<InventoryTab> get shown => values.where((tab) => tab.isShown).toList(growable: false);

  /// The tab [currentKey] opens; the tables for any other route of the section.
  static InventoryTab of(String currentKey) {
    if (_tableRoutes.contains(currentKey)) return tables;

    for (final tab in values) {
      if (tab.routeKey == currentKey && tab.isShown) return tab;
    }

    return tables;
  }

  /// Whether the person may open it: the section's `view` for the tables (the shell already
  /// checked it), the area's for the rest.
  bool get granted => this == tables || PermissionsService().canOpen(area);

  String title(BuildContext context) => switch (this) {
    tables => S.of(context).inventory_tab_tables,
    modifiers => S.of(context).inventory_tab_modifiers
  };
}
