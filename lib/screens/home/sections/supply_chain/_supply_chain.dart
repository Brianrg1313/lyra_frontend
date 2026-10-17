import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';
import 'package:app/services/kitchen/kitchen_reports_service.dart';
import 'package:app/services/kitchen/modifiers_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/no_permission.dart';
import 'package:app/screens/home/sections/_section/page_switcher.dart';
import 'package:app/screens/home/sections/_section/section_tabs.dart';
import 'package:app/screens/home/sections/_section/unavailable.dart';

import './supply_chain_tab.dart';

/// The supply chain: the content of the `supply_chain` home section.
///
/// Products made of others (`cocina-frontend.md`): a burger of bread, meat and bacon, a combo
/// of a burger and a drink, a candle made by the batch from wax and wick. What each product is
/// made of and how many can be made now ([SupplyChainTab.recipes]), what a customer chooses
/// about it ([SupplyChainTab.modifiers]) and what the kitchen spent, lost and what a dish costs
/// ([SupplyChainTab.reports]).
///
/// A company without recipes works as before: nothing here is asked of it until it writes one.
///
/// The services live here (the company's and the branch's: a switch remounts the section) and
/// the tabs read the open one from [Navis.currentKey], like the money page (const-section trap).
class SupplyChainSection extends StatefulWidget {
  const SupplyChainSection({super.key});

  @override
  State<SupplyChainSection> createState() => _SupplyChainSectionState();
}

class _SupplyChainSectionState extends State<SupplyChainSection> {
  final KitchenProductsService _products = KitchenProductsService();
  final ModifiersService _modifiers = ModifiersService();
  final KitchenReportsService _reports = KitchenReportsService();

  @override
  void dispose() {
    _products.dispose();
    _modifiers.dispose();
    _reports.dispose();

    super.dispose();
  }

  SupplyChainTab _tabOf(String currentKey) {
    final tab = SupplyChainTab.byRouteKey(currentKey);

    return tab != null && tab.isShown ? tab : SupplyChainTab.opening;
  }

  void _openTab(SupplyChainTab tab) {
    if (tab == _tabOf(Navis.currentKey.value)) return;

    Navis.push(context, tab.path);
  }

  Widget _body(BuildContext context, SupplyChainTab tab) {
    if (!tab.isReachable) {
      return UnavailableSection(
        key: ValueKey("unavailable_${tab.area}"),
        capability: CapabilityService().of(tab.area),
        surface: false
      );
    }

    if (PermissionsService().canOpen(tab.area)) return tab.build();

    return NoPermissionSection(
      key: ValueKey(tab.area),
      permission: "${tab.area}.view",
      title: tab.title(context),
      surface: false
    );
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<KitchenProductsService>.value(value: _products),
      ChangeNotifierProvider<ModifiersService>.value(value: _modifiers),
      ChangeNotifierProvider<KitchenReportsService>.value(value: _reports)
    ],
    child: ListenableBuilder(
      listenable: Listenable.merge([Navis.currentKey, PermissionsService(), CapabilityService()]),
      builder: (context, _) {
        final tab = _tabOf(Navis.currentKey.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTabs<SupplyChainTab>(
              tabs: SupplyChainTab.shown,
              active: tab,
              icon: (value) => value.icon,
              title: (context, value) => value.title(context),
              onTab: _openTab,
              isLocked: (value) => !PermissionsService().canOpen(value.area)
            ),
            SizedBox(height: AppSize.gap),
            Expanded(child: Surface(
              padding: EdgeInsets.all(AppSize.padding),
              child: PageSwitcher(id: tab, child: _body(context, tab))
            ))
          ]
        );
      }
    )
  );
}
