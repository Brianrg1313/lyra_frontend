import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/money/money_bot_service.dart';
import 'package:app/services/money/money_catalog_service.dart';
import 'package:app/services/money/money_currencies_service.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/money/money_payments_service.dart';
import 'package:app/services/money/money_receivables_service.dart';
import 'package:app/services/money/money_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/no_permission.dart';
import 'package:app/screens/home/sections/page_switcher.dart';
import 'package:app/screens/home/sections/section_tabs.dart';

import 'finance_tab.dart';

/// The company's money: it is the content of the `finance` section of the home.
///
/// It answers the four questions that hang off the same thing and are asked
/// separately (see [FinanceTab]): how much moved, what each movement was, who
/// still owes, and how the company can be paid. They are tabs of one page
/// because they are one subject —and because three of the four are read against
/// the same window and the same currency—, and **each tab is a URL**: the link
/// of what is being looked at is copied and it opens right there.
///
/// Which company it is is not resolved here, unlike the business page: every
/// money endpoint answers for the `business_id` header, so what is being looked
/// at is always the active company. Changing it remounts this whole section
/// (the shell keys the content by business), which is what makes each tab ask
/// for its data again without listening to the business itself.
///
/// **The services live here and not in the app's scope.** Everything they
/// hold —a summary of a window, what the bot cost over another, a page of
/// history, a page of debts, the company's accounts and currencies— belongs to the company
/// being looked at and to nothing else, so leaving the section is exactly when
/// it should be dropped. The
/// concepts catalog is the one that does not depend on the company, but it is
/// cheap and it is only read the first time a payment is recorded.
///
/// The page is split in two, like the business's: the tab bar resting on the
/// background, and the body, which is **the only surface**. The tabs are not
/// four cards side by side, they are four faces of the same sheet.
class FinanceSection extends StatefulWidget {
  const FinanceSection({super.key});

  @override
  State<FinanceSection> createState() => _FinanceSectionState();
}

class _FinanceSectionState extends State<FinanceSection> {
  final MoneyService _summary = MoneyService();
  final MoneyPaymentsService _payments = MoneyPaymentsService();
  final MoneyReceivablesService _receivables = MoneyReceivablesService();
  final MoneyMethodsService _methods = MoneyMethodsService();
  final MoneyCurrenciesService _currencies = MoneyCurrenciesService();
  final MoneyCatalogService _catalog = MoneyCatalogService();
  final MoneyBotService _bot = MoneyBotService();

  @override
  void dispose() {
    _summary.dispose();
    _payments.dispose();
    _receivables.dispose();
    _methods.dispose();
    _currencies.dispose();
    _catalog.dispose();
    _bot.dispose();

    super.dispose();
  }

  /// Open tab, which is the active screen: every tab is a route.
  FinanceTab get _tab => _tabOf(Navis.currentKey.value);

  /// Tab that the screen [currentKey] shows. The bare section
  /// (`/home/finance`, which is where the side bar goes) opens [FinanceTab.opening].
  FinanceTab _tabOf(String currentKey) =>
    FinanceTab.byRouteKey(currentKey) ?? FinanceTab.opening;

  /// Opens another tab.
  ///
  /// It is a navigation and not a `setState` because the open tab is the URL:
  /// that way the browser bar link is the one of what is being looked at, and
  /// the back button returns to the previous tab. The page is not remounted
  /// —all the tabs are the same shell screen—, only the body changes, which is
  /// what keeps the four services alive across the switch.
  void _openTab(FinanceTab tab) {
    if (tab == _tab) return;

    Navis.push(context, tab.path);
  }

  /// The open tab, or the "no access" message when it is not granted: the URL still
  /// opens it (a link, the back button), so the check is here and not only in the bar.
  Widget _body(BuildContext context, FinanceTab tab) {
    if (PermissionsService().canOpen(tab.area)) return tab.build();

    return NoPermissionSection(
      key: ValueKey(tab.area),
      permission: "${tab.area}.view",
      title: tab.title(context),
      surface: false
    );
  }

  /// The body is rebuilt from [Navis.currentKey] and not from the rebuild of
  /// whoever mounts this section, which is what opening a tab actually changes.
  ///
  /// The shell hands the section back as a `const` widget, and a `const` is
  /// canonicalized: on the rebuild that follows the navigation the element
  /// receives the **same** instance it already had, and `Element.updateChild`
  /// returns on identity without rebuilding it. The URL and the tab bar would
  /// then change and the body would stay on the previous tab. Listening here
  /// makes the section independent of how it is built from outside.
  ///
  /// The providers stay above the builder: the services belong to the section,
  /// not to the open tab, and rebuilding them on each switch is precisely what
  /// must not happen.
  @override
  Widget build(BuildContext context) => MultiProvider(
    // `.value` on all seven: their lifecycle is this `State`'s —it created them
    // and disposes them— and not the provider's, which would destroy them on
    // any remount of the tree above.
    providers: [
      ChangeNotifierProvider<MoneyService>.value(value: _summary),
      ChangeNotifierProvider<MoneyPaymentsService>.value(value: _payments),
      ChangeNotifierProvider<MoneyReceivablesService>.value(value: _receivables),
      ChangeNotifierProvider<MoneyMethodsService>.value(value: _methods),
      ChangeNotifierProvider<MoneyCurrenciesService>.value(value: _currencies),
      ChangeNotifierProvider<MoneyCatalogService>.value(value: _catalog),
      ChangeNotifierProvider<MoneyBotService>.value(value: _bot)
    ],
    // Permissions too: a reread of `/init` may open or close the tab being looked at.
    child: ListenableBuilder(
      listenable: Listenable.merge([Navis.currentKey, PermissionsService()]),
      builder: (context, _) {
        final tab = _tabOf(Navis.currentKey.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTabs<FinanceTab>(
              tabs: FinanceTab.values,
              active: tab,
              icon: (value) => value.icon,
              title: (context, value) => value.title(context),
              onTab: _openTab,
              isLocked: (value) => !PermissionsService().canOpen(value.area)
            ),
            SizedBox(height: AppSize.gap),
            Expanded(child: Surface(
              padding: EdgeInsets.all(AppSize.padding),
              child: PageSwitcher(id: tab, child: _body(context, tab))
            ))
          ]
        );
      }
    )
  );
}
