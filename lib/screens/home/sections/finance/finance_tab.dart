import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './methods/_methods.dart';
import './overview/_overview.dart';
import './payments/_payments.dart';
import './receivables/_receivables.dart';

/// The parts of the company's money that can be looked at from the finance
/// page.
///
/// They are four views of the **same** money —how much there is, where it came
/// from, who still owes and how the company gets paid—, not four screens: that
/// is why they are tabs of one page and not side bar sections. You switch from
/// one to another without asking for the company again or losing where you
/// were.
///
/// Each tab **is a URL** (`/home/finance/payments`): the link of what is being
/// looked at is copied, opens right there and comes back with the browser's
/// back button. That is why each one declares its [key] and its [routeKey]:
/// from there come both its route (see `routes`) and the navigation between
/// tabs, without the route table repeating this list.
///
/// Unlike a business's tabs, none of these carries an id: what is being looked
/// at is always the active company, the one the header selector names, and the
/// backend answers every money endpoint for the `business_id` header. So the
/// path is fixed and the shell remounts the whole section when the company
/// changes.
enum FinanceTab {
  overview(key: "overview", icon: CI.wallet),
  payments(key: "payments", icon: CI.receipt),
  receivables(key: "receivables", icon: CI.invoice_list),
  methods(key: "methods", icon: CI.discount_card);

  const FinanceTab({required this.key, required this.icon});

  /// Last segment of the tab's URL, and the one its route key is built with.
  final String key;

  final IconData icon;

  /// Tab the page opens with: the summary is what answers "cuanto entro y
  /// cuanto salio", which is what one comes to see upon entering. The rest are
  /// opened when there is something specific to look up.
  static const FinanceTab initial = overview;

  /// Key of the [ScreenRoute] of this tab.
  ///
  /// Each one has its own —and they do not share a single route with a `:tab`
  /// as argument— because `Navis` notifies the screen change by `currentKey`:
  /// with one key for all, moving from one tab to another would change the URL
  /// without the shell knowing, and the page would keep showing the previous
  /// tab.
  String get routeKey => "finance_$key";

  /// URL of this tab. It is the only source of the `url` of its route and of
  /// the link copied from the browser bar.
  String get path => "/home/finance/$key";

  static final Map<String, FinanceTab> _byRouteKey = {
    for (final tab in values) tab.routeKey: tab
  };

  /// Tab shown on the screen [currentKey], or `null` if that screen is not one
  /// of them (the bare section, which opens on [initial]).
  static FinanceTab? byRouteKey(String currentKey) => _byRouteKey[currentKey];

  String title(BuildContext context) => switch (this) {
    overview => S.of(context).finance_tab_overview,
    payments => S.of(context).finance_tab_payments,
    receivables => S.of(context).finance_tab_receivables,
    methods => S.of(context).finance_tab_methods
  };

  /// Body of the tab. It goes inside the page's surface, so **none brings its
  /// own**: what each one draws is its bare content.
  Widget build() => switch (this) {
    overview => const FinanceOverviewTab(),
    payments => const FinancePaymentsTab(),
    receivables => const FinanceReceivablesTab(),
    methods => const FinanceMethodsTab()
  };
}
