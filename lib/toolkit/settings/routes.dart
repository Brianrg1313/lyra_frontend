import 'package:core/navis/screen_route.dart';

// SCREENS
import 'package:app/screens/_splash/_splash.dart';
import 'package:app/screens/authentication/_authentication.dart';
import 'package:app/screens/authentication/code/_code.dart';
import 'package:app/screens/home/_home.dart';
import 'package:app/screens/pos/_pos.dart';
import 'package:app/screens/pre_start/two_factor/_two_factor.dart';
import 'package:app/screens/pre_start/welcome/_welcome.dart';
import 'package:app/screens/pre_start/deployment/master/_master.dart';
import 'package:app/screens/pre_start/deployment/pair/_pair.dart';
import 'package:app/screens/pre_start/lan/_lan.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/_business_detail.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/channels/form/_channel_form.dart';
import 'package:app/screens/home/sections/connections/form/_connection_form.dart';
import 'package:app/screens/home/sections/deliveries/area/_area.dart';
import 'package:app/screens/home/sections/deliveries/settings/_settings.dart';
import 'package:app/screens/home/sections/employees/employee_detail/_employee_detail.dart';
import 'package:app/screens/home/sections/employees/employee_detail/employee_part.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_section.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';
import 'package:app/screens/home/sections/sales/sales_tab.dart';

/// Every screen swaps with a short fade-through: sign in, the pre-start pages,
/// the home and the POS. It must be the same for all of them: the home's
/// sections and sub-pages share one `Navigator` page (`shell`), which is only
/// updated in place while its page type does not change. Moving among those
/// never animates here; the shell swaps its own sub-pages (`PageSwitcher`).
const _animation = RouteAnimation.fadeThrough;

final List<ScreenRoute> routes = [
  ScreenRoute(
    animation: _animation,
    key: "splash",
    url: "/",
    clearHistoryOnExit: true,
    page: (_) => const Splash()
  ),
  ScreenRoute(
    animation: _animation,
    key: "login",
    url: "/login",
    page: (_) => const Authentication()
  ),
  // Authentication's code step, for sign in and sign up: it's only reached once
  // `email/verify` has sent the code, never on its own.
  ScreenRoute(
    animation: _animation,
    key: "auth_code",
    url: "/login/code",
    parents: ["login"],
    page: (_) => const AuthCode()
  ),
  // Pre-start tasks (`/init`'s `tasks`, see `ClientTask`): standalone pages
  // shown instead of the home until the task is done.
  ScreenRoute(
    animation: _animation,
    key: TwoFactorCheck.routeKey,
    url: TwoFactorCheck.path,
    page: (_) => const TwoFactorCheck()
  ),
  ScreenRoute(
    animation: _animation,
    key: Welcome.routeKey,
    url: Welcome.path,
    page: (_) => const Welcome()
  ),
  // LAN mode (`docs/plan-offline-lan.md` §7.4): making this computer the server
  // or pairing with one (both offered by the sign in), and the LAN landing.
  // Reached only where `Deployment.lanEnabled` (`initialValidator`).
  ScreenRoute(
    animation: _animation,
    key: MasterSetup.routeKey,
    url: MasterSetup.path,
    parents: ["login"],
    page: (_) => const MasterSetup()
  ),
  ScreenRoute(
    animation: _animation,
    key: PairDevice.routeKey,
    url: PairDevice.path,
    parents: ["login"],
    page: (_) => const PairDevice()
  ),
  ScreenRoute(
    animation: _animation,
    key: LanHome.routeKey,
    url: LanHome.path,
    clearHistoryOnExit: true,
    page: (_) => const LanHome()
  ),
  // Each home section is its own route: it's reflected in the URL and can be
  // opened by deep link, always reusing the same shell (side bar).
  //
  // The sections are siblings among themselves, not nested: even though their
  // URLs hang off `/home`, none lives inside another. That's why they don't
  // declare parents; the home is the shell that contains all of them and not
  // one more screen. Sub-pages do declare their section as a parent
  // (`business_detail` -> `parents: ["business"]`), which is what keeps the
  // side bar option marked while navigating inside it.
  //
  // All of them share `shell`, so they occupy a single Navigator page:
  // switching sections updates the tree instead of stacking a new shell.
  // That's why `Home` doesn't receive the section, it reads it from
  // `Navis.currentKey`.
  ...HomeSection.values.map((section) => ScreenRoute(
    animation: _animation,
    key: section.key,
    url: section.path,
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // A business: sub-page of the `business` section. It shares the home's
  // shell (same Navigator page) and declares `business` as a parent so its
  // option stays marked in the side bar. The business is resolved from the
  // `:id` segment; the shell doesn't receive args through its constructor.
  //
  // Without a tab: it's the link to a business "on its own" and opens the
  // initial tab.
  ScreenRoute(
    animation: _animation,
    key: BusinessDetailSection.routeKey,
    url: "/home/business/:id",
    parents: ["business"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Each business tab is its own route, so it's reflected in the URL and the
  // link to what's currently being looked at can be copied
  // (`/home/business/:id/statistics`).
  //
  // They're separate routes and not a single one with a `:tab` argument
  // because the shell finds out the open screen from `Navis.currentKey`: with
  // one key for all five, switching tabs would change the URL without
  // repainting anything.
  //
  // The list comes from [BusinessTab] and isn't written here: the tab already
  // knows its segment and its key (see `BusinessTab.path`).
  ...BusinessTab.values.map((tab) => ScreenRoute(
    animation: _animation,
    key: tab.routeKey,
    url: tab.path(":id"),
    parents: ["business"],
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // Each tab of the money page is its own route, on the same criteria as a
  // business's: the shell learns of a screen change from `Navis.currentKey`,
  // so one route with a `:tab` argument would switch tabs without repainting.
  //
  // None of them carries an id, which is the difference from the business
  // tabs: every money endpoint answers for the active company (the
  // `business_id` header), so what is being looked at is never in the URL.
  ...FinanceTab.values.map((tab) => ScreenRoute(
    animation: _animation,
    key: tab.routeKey,
    url: tab.path,
    parents: ["finance"],
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // Each tab of the sales board is its own route, on the same criteria as the
  // money page's: the shell learns of a screen change from `Navis.currentKey`,
  // so one route with a `:tab` argument would switch lists without repainting.
  //
  // Neither carries an id, for the same reason: every sales endpoint answers
  // for the active company (the `business_id` header), so what is being looked
  // at is never in the URL.
  ...SalesTab.values.map((tab) => ScreenRoute(
    animation: _animation,
    key: tab.routeKey,
    url: tab.path,
    parents: ["sales"],
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // View of a table and its data: sub-page of `inventory`, on the same
  // criteria as the business page. The table is resolved from the `:id`
  // segment.
  //
  // It's the only route that hangs off a table: its settings are a side
  // panel (`showTableSettings`) that opens on top of the list or the sheet,
  // so the URL stays that of whatever was left underneath.
  ScreenRoute(
    animation: _animation,
    key: TableViewSection.routeKey,
    url: "/home/inventory/:id",
    parents: ["inventory"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Settings of an already-connected channel. Creating one is not a route any
  // more — it opens as a side panel (`showCreateChannel`) over the section —
  // so this is the only channel form route left, with the channel resolved
  // from the `:id` segment.
  ScreenRoute(
    animation: _animation,
    key: ChannelFormSection.editRouteKey,
    url: "/home/channels/:id",
    parents: ["channels"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Creating a connection. Same as with a channel, it goes **before** the
  // by-id route and is a fixed segment, so `/home/connections/new` resolves
  // to this one and isn't read as the id of a connection called "new".
  ScreenRoute(
    animation: _animation,
    key: ConnectionFormSection.createRouteKey,
    url: "/home/connections/new",
    parents: ["connections"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Credentials of an already-connected account: the same screen as
  // creation, with the connection resolved from the `:id` segment.
  ScreenRoute(
    animation: _animation,
    key: ConnectionFormSection.editRouteKey,
    url: "/home/connections/:id",
    parents: ["connections"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // One person of the employees section, and each part of their card: one
  // route per part on the same criteria as the business tabs. The account's
  // subsections hang off the viewer's own card (`/home/employees/me/...`).
  // The section resolves the page itself, so the lists outlive the moves.
  ScreenRoute(
    animation: _animation,
    key: EmployeeDetailPage.routeKey,
    url: EmployeeDetailPage.path(":id"),
    parents: ["employees"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  ...EmployeePart.values.map((part) => ScreenRoute(
    animation: _animation,
    key: part.routeKey,
    url: part.path(":id"),
    parents: ["employees"],
    shell: Home.shell,
    page: (_) => const Home()
  )),
  ...OwnSection.values.map((section) => ScreenRoute(
    animation: _animation,
    key: section.routeKey,
    url: section.path,
    parents: ["employees"],
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // Delivery settings: sub-page of `deliveries`, opened from the desk's
  // header. No id in the URL: every delivery endpoint answers for the active
  // company.
  ScreenRoute(
    animation: _animation,
    key: DeliverySettingsSection.routeKey,
    url: DeliverySettingsSection.path,
    parents: ["deliveries"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Delivery area: opened from the delivery settings, on the same criteria.
  ScreenRoute(
    animation: _animation,
    key: DeliveryAreaSection.routeKey,
    url: DeliveryAreaSection.path,
    parents: ["deliveries"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // POS mode: a standalone screen, without `shell` or `parents`.
  //
  // It doesn't hang off `/home` nor share its frame, on purpose: it isn't
  // another home section but another mode of the app. The counter has no
  // side bar, no global search, no business selector, so reusing the shell
  // would mean mounting all of that just to cover it up.
  //
  // Being standalone, it does stack a page on top of home: coming back from
  // the POS finds the section that was being looked at exactly as it was
  // left.
  ScreenRoute(
    animation: _animation,
    key: Pos.routeKey,
    url: Pos.path,
    page: (_) => const Pos()
  )
];