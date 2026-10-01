import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_model.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/screens/home/sections/no_permission.dart';
import 'package:app/screens/home/sections/unavailable.dart';
import 'package:app/screens/home/sections/page_switcher.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'business_tab.dart';
import 'detail_header.dart';

/// The business: it is the content of the `business` section of the home.
///
/// There is no listing beforehand. Everything seen inside the home belongs to
/// one business —the one the header selector says—, so the business section
/// shows **that one**: entering it is opening the business being worked with,
/// not choosing which one to look at. To change it there is the selector,
/// which is visible from all sections.
///
/// The business stuff is spread across tabs (see [BusinessTab]) and **each tab
/// is a URL** (`/home/business/:id/statistics`): the link of what is being
/// looked at is copied and it opens right there. Which one is open is not
/// state of this screen but the active route; that is why changing tabs is
/// navigating and not a `setState`, and the browser's back button returns to
/// the previous tab.
///
/// The page is split in two: the tab bar resting on the background, and the
/// body, which is **the only surface**. The tabs are not cards side by side:
/// they are faces of the same sheet, and that sheet is the body.
/// That is why none brings its own surface and the active tab is drawn with
/// the body's color, like a tongue.
///
/// Which business is resolved from the id in the URL, not by constructor: the
/// screen shares the home shell, which reuses a single page of the `Navigator`
/// and does not rebuild the tree when navigating. Without an id —the bare
/// section, `/home/business`, which is where the side bar takes you— it is the
/// active one.
///
/// The detail is answered by `GET /business/profile/`, which **does not
/// receive an id**: it answers for the business of the `business_id` header,
/// that is the active one. That is not a limitation of the endpoint but how
/// access is designed: reading a business is not asking for it by id, it is
/// having it and choosing it. So entering through the link of a business that
/// is not the active one **activates it** (see [_sync]); the shell mounts the
/// content again with the new business and this screen, already aligned,
/// requests the profile.
class BusinessDetailSection extends StatefulWidget {
  const BusinessDetailSection({super.key});

  /// Key of the route of the business without a tab (`/home/business/:id`). It
  /// is the only source: both the route table and the shell use it.
  ///
  /// It is the link of a business "plain and simple", the one that was already
  /// circulating before the tabs had their own URL: it opens whichever
  /// [BusinessTab.initial] says. Each tab has its own (see
  /// [BusinessTab.routeKey]).
  static const String routeKey = "business_detail";

  @override
  State<BusinessDetailSection> createState() => _BusinessDetailSectionState();
}

class _BusinessDetailSectionState extends State<BusinessDetailSection>
    with BusinessListener<BusinessDetailSection> {
  @override
  void initState() {
    super.initState();

    // It is deferred to the first frame because the two branches of [_sync]
    // notify the service, and notifying while the tree is mounting is a rebuild
    // in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });

    PermissionsService().addListener(_onPermissions);
  }

  @override
  void dispose() {
    PermissionsService().removeListener(_onPermissions);
    super.dispose();
  }

  /// A reread of `/init` may open or close the tab being looked at. The shell hands this
  /// section back as a `const`, so its own rebuild does not reach here.
  void _onPermissions() {
    if (mounted) setState(() {});
  }

  /// Leaves the business of the URL as the active one and requests its profile.
  ///
  /// They are the two paths that lead here: through the link of a business that
  /// is not the active one, and through one that already is (among them, the
  /// bare section, which is the active one by definition). In the first case it
  /// is only chosen and nothing is requested: choosing it remounts the home
  /// content —the shell identifies it by the business— and this screen mounts
  /// again, already through the second path.
  ///
  /// The profile is requested here and not in the settings tab because it is
  /// the other half of the same thing: aligning the active business with the
  /// one of the URL and bringing what there is of it. Splitting it would leave
  /// the tab requesting the detail of a business that this screen is still
  /// finishing choosing.
  ///
  /// An id that the customer does not have is ignored by
  /// [BusinessService.selectBusiness], and then there is nothing to request:
  /// the body shows that that business is not in their list.
  void _sync() {
    final service = context.read<BusinessService>();
    final id = _businessId(service);

    if (service.activeId != id) {
      service.selectBusiness(id);
      return;
    }

    service.loadProfile();
  }

  /// This screen shows the business the URL says. Choosing another in the
  /// selector is asking to see **that one**, so its link is opened, which also
  /// leaves the URL consistent with the business being looked at. It opens in
  /// the same tab: changing business is not changing topic.
  ///
  /// When [_sync] triggered the business change, the URL already names the new
  /// one and there is nowhere to go: navigating again would stack the same
  /// page.
  @override
  void onBusinessChanged(String businessId) {
    if (_urlId == businessId) return;

    Navis.push(context, _tab.path(businessId));
  }

  /// Business that the URL names, or `null` if it is the bare section.
  String? get _urlId => Navis.currentArgs?["id"];

  /// Business being looked at: the one of the URL, and without it the active
  /// one.
  String _businessId(BusinessService service) =>
    _urlId ?? service.activeId ?? "";

  /// Open tab, which is the active screen: every tab is a route. The link of a
  /// business without a tab opens [BusinessTab.opening].
  BusinessTab get _tab =>
    BusinessTab.byRouteKey(Navis.currentKey.value) ?? BusinessTab.opening;

  bool _granted(BusinessTab tab) => tab.granted;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();
    final id = _businessId(service);

    // The `/init` collection already has all of the customer's businesses, so it
    // is enough to know if the id is one of theirs without waiting for the
    // profile.
    final business = service.byId(id);
    final ownsSurface = business != null
      && service.activeId == id
      && _tab.ownsSurface
      && _granted(_tab);

    // The branches and the people are read by their tabs but belong to the
    // page: switching tabs does not ask for them again, and a business switch
    // remounts the page, which is what drops them (every one of their
    // endpoints answers for the active business). Lazy, so a visit that never
    // opens a tab never builds its service.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusinessBranchesService()),
        ChangeNotifierProvider(create: (_) => BusinessEmployeesService())
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BusinessDetailHeader(tab: _tab, onTab: _openTab),
          SizedBox(height: AppSize.gap),
          // Two switchers so the shared sheet does not blink between the tabs
          // drawn on it: those animate inside it, and the sheet itself only
          // swaps against a tab that brings its own.
          Expanded(child: PageSwitcher(
            id: ownsSurface ? _tab : #sheet,
            child: ownsSurface
              ? _tab.build()
              : Surface(
                  padding: EdgeInsets.all(AppSize.padding),
                  child: PageSwitcher(
                    id: _tab,
                    child: _body(context, service, id, business)
                  )
                )
          ))
        ])
    );
  }

  /// Opens another tab of the same business.
  ///
  /// It is a navigation and not a `setState` because the open tab is the URL:
  /// that way the browser bar link is the one of what is being looked at, and
  /// the back button returns to the previous tab. The page is not remounted
  /// —all the tabs are the same shell screen—, only the body changes.
  void _openTab(BusinessTab tab) {
    if (tab == _tab) return;

    Navis.push(context, tab.path(_businessId(context.read<BusinessService>())));
  }

  /// The body is the open tab's, but before that there are two states that
  /// belong to the whole page —the business is not the customer's, or it is
  /// still being activated— and in which no tab has anything to show.
  Widget _body(
    BuildContext context,
    BusinessService service,
    String id,
    BusinessModel? business
  ) {
    // The id does not belong to any of the customer's businesses: it does not
    // exist, nor was they given access, nor was access revoked. You only get
    // here through a foreign or old link, so the way out is the business that
    // was being worked with.
    if (business == null) {
      return SectionMessage(
        icon: CI.info,
        title: S.of(context).business_profile_not_found_title,
        subtitle: S.of(context).business_profile_not_found_subtitle,
        action: service.activeId != null ? _openActive : null,
        actionLabel: S.of(context).business_profile_active
      );
    }

    // It is being activated: what is loaded (if anything) belongs to the
    // previous business, so nothing is shown until the shell remounts this
    // screen with the new business.
    if (service.activeId != id) return const Center(child: Loading());

    // Locked by the network: drawn, saying why (plan §9.6).
    if (!_tab.isReachable) {
      return UnavailableSection(
        key: ValueKey("unavailable_${_tab.area}"),
        capability: CapabilityService().of(_tab.area),
        surface: false
      );
    }

    // Not granted: the URL still opens it (a link, the back button), so the check is here
    // and not only in the tab bar.
    if (!_granted(_tab)) {
      return NoPermissionSection(
        key: ValueKey(_tab.area),
        permission: "${_tab.area}.view",
        title: _tab.title(context),
        surface: false
      );
    }

    return _tab.build();
  }

  /// Returns to the active business. It goes to the bare section and not to its
  /// link with an id because they are the same —the section is the active
  /// business— and there the id cannot go stale.
  void _openActive() => Navis.push(context, "/home/business");
}
