import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/sales/sale_model.dart';

/// The two halves of the sales page.
///
/// They are not two screens and not two subjects: they are **the same list of
/// sales, split by the one rule that matters** — a sale is finished when the
/// money arrived and the goods left, and everything else is still going. So
/// they are tabs of one page, over one service, and switching between them is a
/// different `SECTION` on the same endpoint.
///
/// The split exists for a case every other screen of this app gets wrong: a
/// customer buys over WhatsApp and the ticket is charged, so the register calls
/// it sold — while the box is still on a shelf waiting for a driver. It is
/// money taken and work outstanding at the same time, and the second half is
/// what somebody opening this page is looking for.
///
/// Each tab **is a URL** (`/home/sales/process`): the link of what is being
/// looked at is copied, opens right there and comes back with the browser's
/// back button. Like the money page's tabs and unlike a business's, none of
/// them carries an id — every sales endpoint answers for the `business_id`
/// header, so what is being looked at is always the active company.
///
/// The wording is this app's and not the backend's, even though
/// `GET /sales/stages` also answers a name for each section: a tab is a route
/// with a title, so it belongs to `S`. What the backend decides is which
/// section a *stage* belongs to, which is what the state filter reads.
enum SalesTab {
  process(key: "process", icon: CI.trolley, section: SaleSection.process),
  done(key: "done", icon: CI.shopping_check, section: SaleSection.done);

  const SalesTab({
    required this.key,
    required this.icon,
    required this.section
  });

  /// Last segment of the tab's URL, and the one its route key is built with. It
  /// is the same word the backend takes as `SECTION`, which is why the two are
  /// not translated into each other anywhere.
  final String key;

  final IconData icon;

  /// The list this tab reads.
  final SaleSection section;

  /// Tab the page opens with.
  ///
  /// It is the sales in flight and not the finished ones: what somebody comes
  /// to this page for is what is still owed to somebody, and a list of
  /// everything that already went well is the one that can wait.
  static const SalesTab initial = process;

  /// Key of the [ScreenRoute] of this tab.
  ///
  /// Each one has its own —rather than one route with a `:tab` argument—
  /// because `Navis` announces a screen change through `currentKey`: with one
  /// key for both, moving from one tab to the other would change the URL
  /// without the shell knowing, and the page would keep showing the previous
  /// list.
  String get routeKey => "sales_$key";

  /// Where its pending things are read: the sales still going. The finished ones are not work.
  BadgePlace? get badge => this == process ? BadgePlace.salesProcess : null;

  /// Permission area of this tab (`docs/app-areas.json`): `sales.<key>`. Its `view` opens it.
  String get area => "sales.$key";

  /// Tab the bare section opens: [initial], unless it is not granted in the active company,
  /// then the first one that is. With none granted it is [initial], which shows it is locked.
  static SalesTab get opening {
    final permissions = PermissionsService();
    if (permissions.canOpen(initial.area)) return initial;

    return values.firstWhere((tab) => permissions.canOpen(tab.area), orElse: () => initial);
  }

  /// URL of this tab, and the only source of its route's `url`.
  String get path => "/home/sales/$key";

  static final Map<String, SalesTab> _byRouteKey = {
    for (final tab in values) tab.routeKey: tab
  };

  /// Tab shown on the screen [currentKey], or `null` when that screen is not
  /// one of them (the bare section, which opens on [initial]).
  static SalesTab? byRouteKey(String currentKey) => _byRouteKey[currentKey];

  String title(BuildContext context) => switch (this) {
    process => S.of(context).sales_tab_process,
    done => S.of(context).sales_tab_done
  };
}
