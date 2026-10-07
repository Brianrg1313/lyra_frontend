import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/badges/badges_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/business_listener.dart';
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/badges/badge_route.dart';
import 'package:app/screens/modals/home/pending/_pending.dart';

import './business_selector.dart';

/// Top bar of the home: the app search, the active business and the accesses
/// that belong to no particular section (what is pending, and the inbox).
///
/// Like the side bar it is fixed: it is built once in the shell and is not
/// remounted when the section changes, so it keeps its state (what was typed,
/// the field focus) while navigating. That is why there is a single search for
/// the whole home instead of one per section.
///
/// What is typed is not stored here but in [HomeService.searchQuery]: the
/// header is outside the open section, and that is the point where the two
/// sides meet. Each section decides what to do with the text and the ones that
/// do not search anything yet simply do not read it. The listings (tables,
/// connections) filter the rows they already have by name or description; an
/// open spreadsheet sends it to the backend and reads its already-filtered rows
/// again, because with a table of hundreds of thousands of records what it has
/// is a handful of stretches and searching within them would not be searching
/// the table.
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  /// Max width of the search. It is cut before the edge because a text field as
  /// wide as the screen is uncomfortable to read, and because the rest of the
  /// bar stays free for whatever is added later.
  static const double _searchWidth = 320;

  /// Cap for the business selector. It does not measure its width —the selector
  /// is sized by the name of the active business—, it only keeps a long one from
  /// pushing the search against the edge.
  static double get _businessMaxWidth => AppSize.action * 4.5;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

/// Listens to the business change with the same mixin as the sub-pages: the
/// subscription to the service is set up in `didChangeDependencies` and released
/// in `dispose` against the stored reference, not against the `context`. A
/// header that gets unmounted —changing layout when resizing the window— no
/// longer has a tree above it from which to look the service up again.
class _HomeHeaderState extends State<HomeHeader>
    with BusinessListener<HomeHeader> {
  /// The search lives as long as the header, so the controller belongs to this
  /// screen and not to the input that draws it.
  ///
  /// That is why it is created with its own form: without it,
  /// `InputController.search()` creates one marked as `controlledByInput` and
  /// then [SearchInput] becomes its owner and releases it when unmounted. Since
  /// the header stays alive and keeps the same controller, any remount of the
  /// input —a layout change, a hot reload that moves the tree— would leave it
  /// drawing a field with a already-disposed `FocusNode`:
  /// "A FocusNode was used after being disposed".
  final _form = FormController();
  late final _search = InputController.search(form: _form);

  @override
  void initState() {
    super.initState();

    // The search is emptied when changing screen, not when changing section: a
    // sub-page (a business profile, a spreadsheet) does not search the same
    // thing as the listing it was entered from either.
    Navis.currentKey.addListener(_screenChanged);
  }

  /// And also when changing business, for the same reason the shell remounts
  /// the whole section: what was typed was about the previous business.
  @override
  void onBusinessChanged(String businessId) => _clear();

  @override
  void dispose() {
    Navis.currentKey.removeListener(_screenChanged);

    // The form releases its inputs, the search among them. It goes after the
    // listeners and before `super.dispose()`: the input has already been
    // unmounted (children unmount first) and therefore has already released
    // itself from everything in the form.
    _form.dispose();
    super.dispose();
  }

  void _screenChanged() => _clear();

  /// Empties the search: the field and the text the sections read.
  ///
  /// The `textController` is cleared instead of rebuilding the input to not lose
  /// the controller: the field is the same as always, the only thing that goes
  /// away is what it said.
  void _clear() {
    if (!mounted) return;
    if (_search.text.isNotEmpty) _search.textController.clear();
    context.read<HomeService>().clearSearch();
  }

  /// Everything on the right measures what it measures and the search keeps the
  /// rest: it is the only thing that does not break by being narrower.
  ///
  /// It only checks whether an active business **exists** for the POS access:
  /// which one it is changes nothing here (the counter reads it when opening),
  /// and listening to the whole service would rebuild the bar on each of its
  /// notifications.
  @override
  Widget build(BuildContext context) {
    final hasBusiness = context.select<BusinessService, bool>(
      (service) => service.activeId != null
    );

    return Surface(
      padding: EdgeInsets.all(AppSize.gap),
      child: Row(children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: HomeHeader._businessMaxWidth),
          child: const BusinessSelector()
        ),
        Expanded(child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: HomeHeader._searchWidth),
            child: SearchInput(
              controller: _search,
              placeholder: S.of(context).search_in_app,
              // [SearchInput] already waits for the user to stop typing, so this
              // runs per search and not per key.
              onSearch: (value) => context.read<HomeService>().search(value)
            )
          )
        )),
        // The POS is here in addition to the side bar because it is the only
        // place that stays visible with the bar compressed, and because going to
        // charge is not going to a section: it is leaving the home.
        _HeaderAction(
          icon: CI.cashbox,
          isLocked: !hasBusiness,
          badge: BadgePlace.pos,
          message: S.of(context).pos_mode,
          action: () => context.read<HomeService>().goToPos(context)
        ),
        // The bell's number is the unseen notifications; what it opens is everything pending,
        // the side bar's dots included, each leading to the page that clears it.
        _HeaderAction(
          icon: CI.notification,
          badge: BadgePlace.bell,
          message: S.of(context).badges_title,
          action: _pending
        ),
        _HeaderAction(
          icon: CI.mail,
          message: S.of(context).inbox,
          action: _soon
        )
      ])
    );
  }

  /// Opens the pending list and goes where the chosen badge is cleared. A section marked new is
  /// found by opening it.
  Future<void> _pending() async {
    final business = context.read<BusinessService>().activeId;
    final badge = await showPendingPanel(
      context,
      opens: (badge) => badgeRoute(badge, business: business) != null
    );

    if (badge == null || !mounted) return;

    final route = badgeRoute(badge, business: business);
    if (route == null) return;

    if (badge.kind == BadgeKind.news) unawaited(BadgesService().seen([badge.key]));
    Navis.push(context, route);
  }

  // The inbox does not exist yet. A message is shown instead of leaving the button
  // silent: a button that does nothing when tapped reads as the app failing.
  void _soon() => FloatFlag.of(context).message(S.of(context).coming_soon);
}

/// Icon button of the bar: same height as the search so the row stays even.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.message,
    required this.action,
    this.isLocked = false,
    this.badge
  });

  final IconData icon;

  /// What the button is. It is its tooltip, and the only thing that names it:
  /// the button is just the icon.
  final String message;

  final void Function() action;

  /// The button is shown but leads nowhere: what it opens needs an active
  /// business and there is still none.
  ///
  /// Same treatment as the locked side bar option —dimmed and not opening— and
  /// for the same reason: the bar keeps its shape when the first business is
  /// created, instead of a button appearing where there was nothing. The tooltip
  /// then says why it cannot be entered.
  final bool isLocked;

  /// What it has pending, on its corner.
  final BadgePlace? badge;

  @override
  Widget build(BuildContext context) {
    if (isLocked) return Opacity(opacity: 0.4, child: _action(context));
    if (badge == null) return _action(context);

    return BadgeCorner(place: badge!, child: _action(context));
  }

  Widget _action(BuildContext context) => FeedbackButton(
    // Without an action there is no reason to respond to the mouse either: the
    // cursor warns before the click that it does not open.
    action: isLocked ? null : action,
    mouseCursor: isLocked ? SystemMouseCursors.basic : null,
    message: isLocked
      ? S.of(context).section_no_business_subtitle
      : message,
    radius: AppSize.cornerInset(AppSize.gap),
    color: ThemeColor.of(context).surface,
    feedbackColor: isLocked
      ? Colors.transparent
      : ThemeColor.of(context).surfaceFeedback,
    child: SizedBox(
      width: AppSize.action,
      height: AppSize.action,
      child: Center(child: Icon(
        icon,
        size: AppSize.text * 1.4,
        color: ThemeColor.of(context).icon
      ))
    )
  );
}
