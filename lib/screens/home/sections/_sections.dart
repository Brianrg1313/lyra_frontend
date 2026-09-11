import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './business_listener.dart';
import './no_business.dart';
import './placeholder.dart';
import 'business/_business_detail.dart';
import './channels/_channels.dart';
import './channels/form/_channel_form.dart';
import './connections/_connections.dart';
import './connections/form/_connection_form.dart';
import './finance/_finance.dart';
import './inventory/table_list/_table_list.dart';
import './inventory/table_view/_table_view.dart';
import './sales/_sales.dart';

/// Sections that live inside the home shell.
///
/// Each section is its own route (`/home/...`), so it is reflected in the URL
/// and can be opened directly by deep link. The shell (side bar) is the same
/// for all of them, only the content of [build] changes.
enum HomeSection {
  // The key is that of the section, not the home page: the home is the shell
  // that contains them all, while the dashboard is just one more of them.
  dashboard(key: "dashboard", path: "/home", icon: CI.home),
  business(key: "business", path: "/home/business", icon: CI.store),
  inventory(key: "inventory", path: "/home/inventory", icon: CI.shop),
  services(key: "services", path: "/home/services", icon: CI.task_list),
  channels(key: "channels", path: "/home/channels", icon: CI.ia),
  connections(key: "connections", path: "/home/connections", icon: CI.cloud_connected),
  sales(key: "sales", path: "/home/sales", icon: CI.sale),
  finance(key: "finance", path: "/home/finance", icon: CI.wallet),
  marketing(key: "marketing", path: "/home/marketing", icon: Icons.campaign_outlined),
  report(key: "report", path: "/home/report", icon: CI.chart),
  externalServices(key: "external_services", path: "/home/external_services", icon: CI.link);

  const HomeSection({
    required this.key,
    required this.path,
    required this.icon
  });

  /// Short identifier of the section, used as the key of its [ScreenRoute].
  final String key;

  /// URL of the section. It is the only source of the `url` of its
  /// [ScreenRoute]: the path-to-screen resolution is done by `Navis`, not this
  /// class, so that the route table is not duplicated.
  final String path;
  final IconData icon;

  /// First group of the side bar: what the company **is**.
  ///
  /// The money used to be here, right after the business, on the grounds that
  /// it is the same subject seen from the other side. It moved out when there
  /// was somewhere better for it to be: a group of its own with the two screens
  /// it is really used next to (see [transactions]).
  static const List<HomeSection> home = [
    dashboard,
    business
  ];

  /// Transactions group of the side bar: **the sale, end to end**.
  ///
  /// [sales] is what the company has going right now —every sale, whatever
  /// channel it came in through, and what each one is still waiting for— and
  /// [finance] is the money those sales brought in, plus the accounts they can
  /// arrive into. They are grouped because they are two views of one thing and
  /// somebody working a shift moves between them all day: a sale that reads
  /// "verificando el pago" is answered in the money screen, and one settled
  /// there stops waiting in the board a second later.
  ///
  /// The POS closes the same group in the bar and is **not** in this list: it
  /// is not a section but a page of its own, without the home's shell (see
  /// `Pos`), so the side bar builds that option by hand — see
  /// `desktop/side_bar/options.dart`.
  static const List<HomeSection> transactions = [
    sales,
    finance
  ];

  /// Product group of the side bar.
  static const List<HomeSection> products = [
    inventory,
    services,
    channels
  ];

  /// Report group of the side bar.
  ///
  /// The money used to be listed here, back when it was a placeholder: as a
  /// screen it is not a report but the place where the company's accounts are
  /// configured and its movements are recorded, so it moved up to
  /// [transactions].
  static const List<HomeSection> reports = [
    marketing,
    report
  ];

  /// Connections group of the side bar.
  ///
  /// Connections come first because they are the company's own accounts —what
  /// gets connected and looked at often—; external services are what the
  /// platform consumes behind the scenes.
  static const List<HomeSection> connectionGroups = [
    connections,
    externalServices
  ];

  static final Map<String, HomeSection> _byKey = {
    for (final section in values) section.key: section
  };

  /// Section registered with that key, or `null` if the key is not a section
  /// (for example, that of a sub-page).
  static HomeSection? byKey(String key) => _byKey[key];

  /// Section that contains the screen [currentKey], or `null` if none.
  static HomeSection? containing(String currentKey) {
    for (final section in values) {
      if (section.isCurrent(currentKey)) return section;
    }
    return null;
  }

  /// `true` if the screen [currentKey] belongs to this section: either it is the
  /// section itself, or it is a sub-page of it. In this way `business_detail`,
  /// which declares `parents: ["business"]`, keeps [business] marked.
  bool isCurrent(String currentKey) => currentKey == key
    || (Navis.byKey(currentKey)?.isInside(key) ?? false);

  String title(BuildContext context) => switch (this) {
    dashboard => S.of(context).home,
    business => S.of(context).business,
    inventory => S.of(context).inventory,
    services => S.of(context).services,
    channels => S.of(context).channels,
    connections => S.of(context).connections,
    sales => S.of(context).sales,
    finance => S.of(context).finance,
    marketing => S.of(context).marketing,
    report => S.of(context).report,
    externalServices => S.of(context).external_services
  };

  /// `true` if the section cannot be opened without an active business.
  ///
  /// Almost all of them are: what they show —the tables, the channels, the
  /// connections— hangs off a business, and they request it in their
  /// `initState` by reading `BusinessService.active`, which takes its existence
  /// for granted.
  ///
  /// The two that are not are the dashboard, which is the home cover page and
  /// the first thing a customer without businesses has to be able to see, and
  /// the business section itself: blocking it would be blocking exactly the
  /// place where the first one is created. Without any, it shows not a detail
  /// but the sign-up (see [_screen]), which is the same path that the header
  /// selector offers.
  ///
  /// Both sides of the same rule look at it: the side bar, to block the option
  /// (see `options`), and the shell, to not mount the section even if it is
  /// reached by URL (see [homeContent]).
  bool get needsBusiness => this != dashboard && this != business;

  /// Section content.
  ///
  /// There is no case for [business]: its content is assembled by [homeContent],
  /// which is the one that knows the business of the URL and gives it its
  /// identity. It is the only section that is also the page of its sub-pages
  /// —its tabs—, so building it here would leave it without a key and changing
  /// business would not remount it.
  Widget build() => switch (this) {
    inventory => const InventorySection(),
    channels => const ChannelsSection(),
    connections => const ConnectionsSection(),
    // The money page is built here and not by [homeContent], unlike the
    // business's: its tabs carry no id —every money endpoint answers for the
    // active company— so the bare section and each of its tabs are the same
    // widget, and the section resolves which tab from `Navis.currentKey`.
    // The sales board is built here on the same criteria as the money page:
    // its tabs carry no id —every sales endpoint answers for the active
    // company— so the bare section and each of its tabs are the same widget,
    // and the section resolves which tab from `Navis.currentKey`.
    sales => const SalesSection(),
    finance => const FinanceSection(),
    _ => SectionPlaceholder(section: this)
  };
}

/// Content that the shell must show for the screen [currentKey], tied to the
/// business [businessId].
///
/// Normally it is the [section] itself (already resolved in `Home`), but when
/// the active screen is a sub-page, the sub-page is shown instead, while the
/// [section] that contains it keeps marking its option in the side bar. It is
/// the point where the home's sub-pages are routed.
///
/// What is seen inside the home always belongs to a business, so the content
/// is identified with it: changing business changes the identity of this part
/// of the tree and the `Navigator` mounts it again instead of updating it.
/// That is what makes **every section request its data again** —the data it
/// loads in its `initState`— without having to listen to the business on its
/// own, including sections that do not exist yet.
///
/// It is remounted and not refreshed on purpose: of the previous business it
/// is not only what was loaded, but also what was written in the search box,
/// where the spreadsheet was stopped or the cell that was being edited.
/// Keeping it would be mixing two businesses on the same screen.
///
/// The only thing this does not fix are the sub-pages tied to an id of the
/// previous business (`/home/inventory/:id`): remounting them would request a
/// table that the new business does not have. Those listen to the change and
/// move on their own, see [BusinessListener].
///
/// Without [businessId] there is no active business (a newly registered
/// customer, or one that has not created theirs yet) and the sections that
/// depend on one are not mounted: they request their data in their `initState`
/// —`BusinessService.active` takes its existence for granted—, so entering one
/// without a business would crash before painting. In its place goes
/// [NoBusinessSection], which offers the sign-up. The ones that still show are
/// those with [HomeSection.needsBusiness] at `false`, the same ones that the
/// side bar leaves enabled: the dashboard and the business section, which
/// without any is also the sign-up (see [_screen]).
///
/// It is checked here in addition to the side bar because a section is a URL:
/// with the options blocked it can still be reached by deep link, reloading
/// the page or with the browser's back button.
Widget homeContent(
  String currentKey,
  HomeSection section,
  String? businessId
) => KeyedSubtree(
  key: ValueKey(businessId),
  child: businessId == null && section.needsBusiness
    ? const NoBusinessSection()
    : _screen(currentKey, section, businessId)
);

/// The screen that goes inside the shell: the open [section], or its sub-page
/// indicated by [currentKey].
Widget _screen(String currentKey, HomeSection section, String? businessId) {
  // The business section and its tabs are the same screen, and it is the tabs
  // that carry the id in the URL: it is resolved by the section and not by the
  // open screen, which is a different key per tab.
  if (section == HomeSection.business) {
    // Without an active business there is no detail to show, but the section opens
    // anyway: it is the natural place to create the first one. The sign-up is
    // requested instead of mounting the detail, which without a business would
    // look for a profile that does not exist.
    //
    // The URL is also checked so as not to override the link of a specific
    // business: that id does not belong to the customer (if it did it would be
    // the active one) and the detail already knows how to tell.
    if (businessId == null && Navis.currentArgs?["id"] == null) {
      return const NoBusinessSection();
    }

    // One key per business: the page reads the id from the URL when it mounts and
    // from there aligns the active business with it. Without this, moving from
    // one business to another through the browser history would reuse the
    // previous `State` and the screen would stay waiting for a business that
    // nobody is going to activate.
    //
    // Without an id in the URL the business is the active one, so that is the
    // key: the bare section and the link of the business already being looked
    // at are the same page, and moving from one to the other should not have to
    // remount it.
    return BusinessDetailSection(
      key: ValueKey("business_${Navis.currentArgs?["id"] ?? businessId}")
    );
  }

  return switch (currentKey) {
    TableViewSection.routeKey => const TableViewSection(),
    // Keyed by id: without it, going from one channel's edit page straight to
    // another's would reuse the previous `State`, which already read the id
    // from the URL in its `initState` and would keep editing the first one.
    ChannelFormSection.editRouteKey => ChannelFormSection(
      key: ValueKey("channel_${Navis.currentArgs?["id"]}")
    ),
    // The same for the connection form, and for the same reason: the two routes are
    // the same screen, which reads the id in its `initState`.
    ConnectionFormSection.createRouteKey =>
      const ConnectionFormSection(key: ValueKey("connection_new")),
    ConnectionFormSection.editRouteKey => ConnectionFormSection(
      key: ValueKey("connection_${Navis.currentArgs?["id"]}")
    ),
    _ => section.build()
  };
}
