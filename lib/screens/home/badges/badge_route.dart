// SERVICES
import 'package:app/services/badges/badge_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';
import 'package:app/screens/pos/_pos.dart';

/// Where opening [badge] goes, in this app's routing, or `null` when it has no page here yet
/// (appointments, the notification feed, the terms).
///
/// It is read off the badge's anchors and not its `action`: the backend's `action` is its guess at
/// a route (`/business/payments`), the anchors are the convention both sides keep, and the most
/// specific one wins — the tab that fixes it before the section that holds it. [business] is the
/// active company, which a business tab's URL carries.
String? badgeRoute(BadgeModel badge, {String? business}) {
  for (final (anchor, route) in _routes) {
    if (!badge.anchors.contains(anchor)) continue;

    final path = route(business);
    if (path != null) return path;
  }

  return null;
}

final List<(String, String? Function(String? business))> _routes = [
  ("business.profile", (business) => business == null ? null : BusinessTab.settings.path(business)),
  ("business.payments", (_) => FinanceTab.methods.path),
  ("money.receivables", (_) => FinanceTab.receivables.path),
  ("sidebar.chats", (_) => HomeSection.messages.path),
  ("sidebar.inventory", (_) => HomeSection.inventory.path),
  ("sidebar.channels", (_) => HomeSection.channels.path),
  ("sidebar.money", (_) => HomeSection.finance.path),
  ("sidebar.pos", (_) => Pos.path)
];
