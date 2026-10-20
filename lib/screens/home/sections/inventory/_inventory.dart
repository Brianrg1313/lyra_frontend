import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/kitchen/modifiers_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/no_permission.dart';
import 'package:app/screens/home/sections/_section/page_switcher.dart';
import 'package:app/screens/home/sections/_section/section_tabs.dart';
import 'package:app/screens/home/sections/_section/unavailable.dart';
import 'package:app/screens/home/sections/inventory/modifiers/_modifiers.dart';
import 'package:app/screens/home/sections/inventory/table_list/_table_list.dart';

import './inventory_tab.dart';

/// Inventory: the content of the `inventory` home section — its tables ([InventoryTables]:
/// products and supplies, one open at a time) and the company's modifier groups
/// ([ModifiersTab]).
///
/// Products and supplies share the section (`cocina-frontend.md` §2): they are worked the same
/// way (a sheet, stock counted by hand, transfers) and never mix, since each table is of one
/// kind, chosen when it is created. What is made from the supplies is the menu's.
///
/// Where the modifiers tab does not exist (a master: cloud only) there is a single page and no
/// tab bar. The tab is read from [Navis.currentKey] (the bare section, a table's link and the
/// modifiers' route all build this same const widget), like the money page.
class InventorySection extends StatefulWidget {
  const InventorySection({super.key});

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  /// The company's: a business or branch switch remounts the section.
  final ModifiersService _modifiers = ModifiersService();

  @override
  void dispose() {
    _modifiers.dispose();
    super.dispose();
  }

  void _openTab(InventoryTab tab) {
    if (tab == InventoryTab.of(Navis.currentKey.value)) return;

    Navis.push(context, tab.path);
  }

  Widget _body(BuildContext context, InventoryTab tab) {
    if (tab == InventoryTab.tables) return const InventoryTables();

    if (!tab.isReachable) {
      return Surface(child: UnavailableSection(
        key: ValueKey("unavailable_${tab.area}"),
        capability: CapabilityService().of(tab.area),
        surface: false
      ));
    }

    if (!tab.granted) {
      return Surface(child: NoPermissionSection(
        key: ValueKey(tab.area),
        permission: "${tab.area}.view",
        title: tab.title(context),
        surface: false
      ));
    }

    return Surface(
      padding: EdgeInsets.all(AppSize.padding),
      child: const ModifiersTab()
    );
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<ModifiersService>.value(
    value: _modifiers,
    child: ListenableBuilder(
      listenable: Listenable.merge([Navis.currentKey, PermissionsService(), CapabilityService()]),
      builder: (context, _) {
        final tabs = InventoryTab.shown;
        final tab = InventoryTab.of(Navis.currentKey.value);

        if (tabs.length < 2) return const InventoryTables();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTabs<InventoryTab>(
              tabs: tabs,
              active: tab,
              icon: (value) => value.icon,
              title: (context, value) => value.title(context),
              onTab: _openTab,
              isLocked: (value) => !value.granted
            ),
            SizedBox(height: AppSize.gap),
            Expanded(child: PageSwitcher(id: tab, child: _body(context, tab)))
          ]
        );
      }
    )
  );
}
