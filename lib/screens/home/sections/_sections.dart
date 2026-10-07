import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

import './_section/business_listener.dart';
import './_section/no_business.dart';
import './_section/no_permission.dart';
import './_section/unavailable.dart';
import './_section/page_switcher.dart';
import './_section/placeholder.dart';
import 'business/_business_detail.dart';
import './channels/_channels.dart';
import './channels/form/_channel_form.dart';
import './connections/_connections.dart';
import './connections/form/_connection_form.dart';
import './deliveries/_deliveries.dart';
import './deliveries/area/_area.dart';
import './deliveries/settings/_settings.dart';
import './finance/_finance.dart';
import './local_server/_local_server.dart';
import './inventory/table_list/_table_list.dart';
import './inventory/table_view/_table_view.dart';
import './messages/_messages.dart';
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
  messages(key: "messages", path: "/home/messages", icon: CI.chat),
  deliveries(key: "deliveries", path: "/home/deliveries", icon: CI.delivery),
  sales(key: "sales", path: "/home/sales", icon: CI.sale),
  finance(key: "finance", path: "/home/finance", icon: CI.wallet),
  marketing(key: "marketing", path: "/home/marketing", icon: Icons.campaign_outlined),
  report(key: "report", path: "/home/report", icon: CI.chart),
  externalServices(key: "external_services", path: "/home/external_services", icon: CI.link),
  // Wherever a master can be: its devices, and online any computer, which creates one (D16).
  server(key: "local_server", path: "/home/server", icon: CI.network);

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

  /// First group of the side bar, with no title: what the company **is** and
  /// what it has going right now.
  ///
  /// [messages], [deliveries] and [sales] follow the business, in the order a
  /// sale happens: the conversation where it starts, getting the goods to the
  /// customer, and the board of everything still in progress. They used to
  /// sit under a "transactions" title of their own; they are the screens
  /// opened all day, so they went up to the untitled top of the bar.
  static const List<HomeSection> home = [
    dashboard,
    business,
    messages,
    deliveries,
    sales
  ];

  /// Product group of the side bar.
  static const List<HomeSection> products = [
    inventory,
    services,
    channels
  ];

  /// Report group of the side bar.
  ///
  /// [finance] opens it: the company's money is what gets looked back at.
  static const List<HomeSection> reports = [
    finance,
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
    externalServices,
    server
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
    messages => S.of(context).messages,
    deliveries => S.of(context).deliveries,
    sales => S.of(context).sales,
    finance => S.of(context).finance,
    marketing => S.of(context).marketing,
    report => S.of(context).report,
    externalServices => S.of(context).external_services,
    server => S.of(context).local_server
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
  ///
  /// The server's page isn't a company's either: it's the master's devices.
  bool get needsBusiness => this != dashboard && this != business && this != server;

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
    messages => const MessagesSection(),
    deliveries => const DeliveriesSection(),
    finance => const FinanceSection(),
    server => const LocalServerSection(),
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
/// previous business: remounting them would request something the new business
/// does not have. Those listen to the change and move on their own, see
/// [BusinessListener].
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
///
/// With a business, a section the person is not granted (`<key>.view` in
/// [PermissionsService]) is not mounted either, for the same reason and by the
/// same door: its reads would only meet a 403. [NoPermissionSection] goes in
/// its place, with the way to ask for it. The caller watches the permissions.
///
/// Before either, a section the deployment mode doesn't have, or can't reach
/// without the internet ([CapabilityService]), shows [UnavailableSection]: the
/// side bar leaves it out, but a URL still gets here.
///
/// Moving between the pages of one section (the channels and one channel's form) goes through a [PageSwitcher]; moving
/// to another section does not animate. The switcher is keyed by [section], so
/// a new section mounts a new one and shows its page as is. Its page identity
/// is the screen's key, or its type when unkeyed: a tabbed section is one
/// widget for all its tabs and animates its body itself.
Widget homeContent(
  String currentKey,
  HomeSection section,
  String? businessId
) {
  final Widget screen;
  final capability = CapabilityService().of(section.key);

  if (capability != Capability.available) {
    screen = UnavailableSection(
      key: ValueKey("unavailable_${section.key}"),
      capability: capability
    );
  } else if (businessId == null && section.needsBusiness) {
    screen = const NoBusinessSection();
  } else if (businessId != null && !PermissionsService().canOpen(section.key, business: businessId)) {
    screen = Builder(
      key: ValueKey("no_permission_${section.key}"),
      builder: (context) => NoPermissionSection(
        permission: "${section.key}.view",
        title: section.title(context)
      )
    );
  } else {
    screen = _screen(currentKey, section, businessId);
  }

  return KeyedSubtree(
    key: ValueKey(businessId),
    child: PageSwitcher(
      key: ValueKey(section),
      id: screen.key ?? screen.runtimeType,
      child: screen
    )
  );
}

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
    // A table's link opens the section itself, on that table: the same const widget as
    // the bare section, so moving between the two keeps its state.
    TableViewSection.routeKey => const InventorySection(),
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
    DeliverySettingsSection.routeKey => const DeliverySettingsSection(),
    DeliveryAreaSection.routeKey => const DeliveryAreaSection(),
    _ => section.build()
  };
}
