import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/no_permission.dart';
import 'package:app/screens/home/sections/_section/page_switcher.dart';
import 'package:app/screens/home/sections/_section/section_tabs.dart';

import './sales_board.dart';
import './sales_tab.dart';

/// **What the company is selling right now**: the content of the `sales`
/// section of the home.
///
/// It is the screen this app did not have. A shop does not have "facturas
/// abiertas" and "conversaciones" and "ventas" — it has sales, at different
/// points of one path, and until now each third of that lived on a screen of
/// its own: the ticket on the register, the purchase the assistant is
/// negotiating in the channels, the charged sale in the money. A person looking
/// at any one of them saw a shop with three sales going when it had eleven.
///
/// So this is the list that holds all of them, and every row says **what is
/// missing**: a ticket a till still has open, stock the assistant is holding, a
/// customer who was handed an account and has not paid, one who says they paid
/// and nobody has checked, a charged sale that has not reached the customer
/// yet. It is split in two by the one rule that decides it — a sale is finished
/// when the money arrived **and** the goods left — and each half is a tab (see
/// [SalesTab]).
///
/// **It is live.** Every screen of the company is told when a sale moves
/// (`sale/progress`), which is the difference between a board and a report: a
/// ticket charged at the counter, a driver going out, a customer settling their
/// tab all move a row while somebody is looking at it. Without that, two people
/// work the same delivery from two copies of the same list.
///
/// **The services live here and not in the app's scope**, on the same criteria
/// as the money section's: what they hold belongs to the company being looked
/// at, so leaving the section is exactly when it should be dropped. Which
/// company it is never reaches them — every sales endpoint answers for the
/// `business_id` header, so what is being looked at is always the active one,
/// and changing it remounts this whole section (the shell keys its content by
/// business).
///
/// The page is split like the money's: the tab bar resting on the background,
/// and the body, which is the only surface. The tabs are not two cards side by
/// side, they are two faces of the same sheet.
class SalesSection extends StatefulWidget {
  const SalesSection({super.key});

  @override
  State<SalesSection> createState() => _SalesSectionState();
}

class _SalesSectionState extends State<SalesSection> {
  /// One service for both tabs: they are the same endpoint with a different
  /// `SECTION`, and each board tells it which list to open when it mounts.
  final SalesService _sales = SalesService();

  /// The vocabulary both tabs and the handover panel are drawn from. It is read
  /// once and outlives the switch between tabs, which is the reason it is here
  /// and not inside a board.
  final SalesCatalogService _catalog = SalesCatalogService();

  @override
  void dispose() {
    _sales.dispose();
    _catalog.dispose();

    super.dispose();
  }

  /// Open tab, which is the active screen: every tab is a route.
  SalesTab get _tab => _tabOf(Navis.currentKey.value);

  /// Tab that the screen [currentKey] shows. The bare section (`/home/sales`,
  /// which is where the side bar goes) opens [SalesTab.opening].
  SalesTab _tabOf(String currentKey) =>
    SalesTab.byRouteKey(currentKey) ?? SalesTab.opening;

  /// Opens the other tab.
  ///
  /// It is a navigation and not a `setState` because the open tab is the URL:
  /// the link in the browser bar is the one of what is being looked at, and the
  /// back button returns to the previous list. The page is not remounted —both
  /// tabs are the same shell screen— only the body changes, which is what keeps
  /// the two services alive across the switch.
  void _openTab(SalesTab tab) {
    if (tab == _tab) return;

    Navis.push(context, tab.path);
  }

  /// The board of the open tab, or the "no access" message when it is not granted: the
  /// URL still opens it (a link, the back button), so the check is here and not only in
  /// the bar. The board draws edge to edge, the message keeps the sheet's padding.
  Widget _body(BuildContext context, SalesTab tab) {
    if (!PermissionsService().canOpen(tab.area)) {
      return Padding(
        key: ValueKey(tab.area),
        padding: EdgeInsets.all(AppSize.padding),
        child: NoPermissionSection(
          permission: "${tab.area}.view",
          title: tab.title(context),
          surface: false
        )
      );
    }

    return SalesBoard(key: ValueKey(tab.routeKey), section: tab.section);
  }

  /// The body is rebuilt from [Navis.currentKey] and not from the rebuild of
  /// whoever mounts this section, which is what opening a tab actually changes.
  ///
  /// The shell hands the section back as a `const` widget, and a `const` is
  /// canonicalized: on the rebuild that follows the navigation the element
  /// receives the **same** instance it already had, and `Element.updateChild`
  /// returns on identity without rebuilding it. The URL and the tab bar would
  /// change and the body would stay on the previous list. It is the same trap
  /// the money page was written around.
  ///
  /// The board is keyed by tab so that switching lists gives it a fresh
  /// `State`: it asks the service to open its own section in `initState`, and
  /// a reused element would never ask.
  @override
  Widget build(BuildContext context) => MultiProvider(
    // `.value` on both: their lifecycle is this `State`'s —it created them and
    // disposes them— and not the provider's, which would destroy them on any
    // remount of the tree above.
    providers: [
      ChangeNotifierProvider<SalesService>.value(value: _sales),
      ChangeNotifierProvider<SalesCatalogService>.value(value: _catalog)
    ],
    // Permissions too: a reread of `/init` may open or close the tab being looked at.
    child: ListenableBuilder(
      listenable: Listenable.merge([Navis.currentKey, PermissionsService()]),
      builder: (context, _) {
        final tab = _tabOf(Navis.currentKey.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTabs<SalesTab>(
              tabs: SalesTab.values,
              active: tab,
              icon: (value) => value.icon,
              title: (context, value) => value.title(context),
              onTab: _openTab,
              isLocked: (value) => !PermissionsService().canOpen(value.area)
            ),
            SizedBox(height: AppSize.gap),
            Expanded(child: Surface(child: PageSwitcher(
              id: tab,
              child: _body(context, tab)
            )))
          ]
        );
      }
    )
  );
}
