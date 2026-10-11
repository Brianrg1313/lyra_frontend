import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show hybridService;

// WIDGETS
import 'package:app/screens/home/desktop/_body.dart';
import 'package:app/screens/home/header/_header.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/modals/business/branch_picker/_branch_picker.dart';
import 'package:app/screens/modals/server/link_company/_link_company.dart';
import 'package:app/screens/modals/server/online_sign_in/_online_sign_in.dart';

/// Home shell. Each section loads via its own URL (`/home/...`) but
/// they all share this single page: when switching sections the tree is
/// updated instead of recreated, so the side bar keeps its state
/// (including scroll) and no shell is stacked per visited section.
///
/// That's why the section doesn't come through the constructor: the `Navigator`
/// caches the page widget and doesn't rebuild it on update. The source is
/// [Navis.currentKey].
class Home extends PageBuilder {
  const Home({super.key});

  /// Identifier of the shell shared across the section routes.
  static const String shell = "home";

  /// This shell holds every authenticated section, so reaching it already
  /// implies a valid session: that's the point where it makes sense to ensure
  /// the connection.
  ///
  /// Normally it does nothing, because `ClientService.resolve` already opened
  /// it when the session was started and [ConnectionService.open] is
  /// idempotent. It covers the opposite case: entering home through a path
  /// that didn't go through `resolve` (a sign-in within the same run), and
  /// bringing the connection back up if it had been closed.
  ///
  /// It runs once per shell mount, not on every section change: they all share
  /// this page of the `Navigator`.
  ///
  /// It looks at the client and not the route because what authorizes the
  /// handshake is the credential, not being on `/home`: without a loaded
  /// session the server would reject the connection and the client would keep
  /// retrying.
  @override
  void initialized(BuildContext context) {
    if (!context.read<ClientService>().isAuthenticated) return;
    unawaited(ConnectionService().open());
  }

  /// It listens to the **active business** in addition to the open screen:
  /// everything that lives inside home belongs to a business, so switching it
  /// leaves the section being viewed stale. The content is identified by it
  /// ([homeContent]) and remounted, which is what makes each section request
  /// its data again for the newly chosen business.
  ///
  /// It looks only at the identifier and not the whole service: the rest of its
  /// notifications (a creation, loading the business section detail) don't need
  /// to rebuild the shell.
  ///
  /// The [HomeHeader] goes through the builder's `child` and not inside it: it's
  /// fixed like the side bar, so it's built only once and switching sections
  /// doesn't build it again. That's what lets it keep whatever was typed in the
  /// search box while navigating.
  @override
  Widget build(BuildContext context) {
    final businessId = context.select<BusinessService, String?>(
      (service) => service.activeId
    );
    final branch = context.select<BranchService, (String?, bool)>(
      (service) => (service.activeId, service.settled)
    );
    // A reread `/init` can grant or revoke the open section; the internet going or coming back,
    // or "work offline", locks or opens it in place.
    context.watch<PermissionsService>();
    context.watch<CapabilityService>();

    return ValueListenableBuilder<String>(
      valueListenable: Navis.currentKey,
      child: const HomeHeader(),
      builder: (context, currentKey, header) {
        // A sub-page isn't a section, but it lives inside one: the section that
        // contains it is shown so the shell stays coherent.
        final section = HomeSection.byKey(currentKey)
          ?? HomeSection.containing(currentKey)
          ?? HomeSection.dashboard;

        // The resolved section marks the side bar option; the content can be
        // the section's own or one of its sub-pages (e.g. a business tab inside
        // `business`).
        // Until the branch is known a section would read with no `branch_id`, and the till,
        // stock, sales and money refuse that.
        final content = branch.$2
          ? homeContent(currentKey, section, businessId, branchId: branch.$1)
          : const Center(child: Loading());

        return _OfferOnline(child: _AskBranch(child: DeviceSelector(
          phone: (context) => _HomeBody(header: header!, content: content),
          desktop: (context) => DesktopBody(
            section: section,
            header: header!,
            content: content
          )
        )));
      }
    );
  }
}

/// Asks which branch the person works in when there are several and none was picked on this
/// device, or when the backend refused the one sent (`BranchService.shouldAsk`). Until then the
/// header carries the list's first, so nothing waits on the answer.
class _AskBranch extends StatefulWidget {
  const _AskBranch({required this.child});

  final Widget child;

  @override
  State<_AskBranch> createState() => _AskBranchState();
}

class _AskBranchState extends State<_AskBranch> {
  final _branches = BranchService();

  @override
  void initState() {
    super.initState();
    _branches.addListener(_ask);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _branches.removeListener(_ask);
    super.dispose();
  }

  void _ask() {
    if (!mounted || !_branches.shouldAsk) return;

    _branches.asked();
    unawaited(showBranchPicker(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A session on the master alone stays offline until the same person signs in online: once the
/// backend answers, that sign in opens by itself, once per session (`HybridService.shouldOfferOnline`),
/// when the e-mail has an online account to sign in to ([offerOnlineSignIn]).
/// Pressing a button nobody knows is there is not how anyone expects the internet to come back.
///
/// Online on a master's devices with its company not joined yet, joining it happens here too, once
/// a session (`HybridService.shouldAskLink`, [askLinkCompany]): whenever it becomes true — the
/// home opening, an online sign in joining the session, the internet coming back.
class _OfferOnline extends StatefulWidget {
  const _OfferOnline({required this.child});

  final Widget child;

  @override
  State<_OfferOnline> createState() => _OfferOnlineState();
}

class _OfferOnlineState extends State<_OfferOnline> {
  @override
  void initState() {
    super.initState();
    hybridService.addListener(_offer);
    CapabilityService().addListener(_offer);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
  }

  @override
  void dispose() {
    hybridService.removeListener(_offer);
    CapabilityService().removeListener(_offer);
    super.dispose();
  }

  void _offer() {
    if (!mounted) return;

    if (hybridService.shouldAskLink) unawaited(askLinkCompany(context));

    if (!hybridService.shouldOfferOnline) return;

    hybridService.offeredOnline();
    unawaited(offerOnlineSignIn(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.header, required this.content});

  /// Top bar, the same for every section.
  final Widget header;

  final Widget content;

  /// The bar goes inside the body and not in the skeleton's `header`: that slot
  /// floats above the content, and here it has to take its place so the section
  /// starts below it. The [SafeArea] is for the usual phone reason: without it
  /// the bar ends up hidden behind the status bar.
  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: SafeArea(child: Column(children: [
      Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: header
      ),
      Expanded(child: content)
    ]))
  );
}
