import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/page_switcher.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/employees/employee_detail/_employee_detail.dart';
import 'package:app/screens/home/sections/employees/employee_detail/employee_detail_header.dart';
import 'package:app/screens/home/sections/employees/employee_detail/employee_part.dart';
import 'package:app/screens/home/sections/employees/employee_detail/employee_part_page.dart';
import 'package:app/screens/home/sections/employees/employee_list/_employee_list.dart';
import 'package:app/screens/home/sections/employees/employee_page.dart';
import 'package:app/screens/home/sections/employees/employee_panel_bar.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_section.dart';
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_section_page.dart';

/// Who works in the active company: the content of the `employees` home
/// section. Two panels, like the messages desk: the list on the left, always in
/// sight, and the detail on the right, which is what navigates. Its pages are
/// each a URL: one person ([EmployeeDetailPage], `/home/employees/:id`; the
/// bare `/home/employees` shows the viewer's own card) and one part of their
/// card ([EmployeePart], `/home/employees/:id/job`) or of the viewer's account
/// ([OwnSection], `/home/employees/me/security`).
///
/// They are one widget for the shell, like the money page's tabs: the section
/// resolves the detail's page from [Navis.currentKey] and swaps it itself, so
/// the list, the details read and the account's services outlive moving
/// between them.
/// A business switch remounts the home content, which drops them (every
/// endpoint answers for the active business).
///
/// It was a tab of the business page; it keeps that tab's permission area
/// (`HomeSection.area`).
class EmployeesSection extends StatefulWidget {
  const EmployeesSection({super.key});

  @override
  State<EmployeesSection> createState() => _EmployeesSectionState();
}

class _EmployeesSectionState extends State<EmployeesSection> {
  final _employees = BusinessEmployeesService();
  final _security = AccountSecurityService();
  final _history = AccountHistoryService();

  /// The account is read the first time one of the viewer's own pages opens,
  /// not with the list: most visits never look at it.
  bool _accountRead = false;

  @override
  void initState() {
    super.initState();

    // Deferred to the first frame: the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _employees.load();
    });
  }

  @override
  void dispose() {
    _employees.dispose();
    _security.dispose();
    _history.dispose();
    super.dispose();
  }

  void _readAccount() {
    if (_accountRead) return;
    _accountRead = true;

    final capabilities = CapabilityService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (capabilities.shows("account.security")) _security.load();
      if (capabilities.shows("account.history")) _history.load();
    });
  }

  void _go(String path) => Navis.push(context, path);

  /// The body is rebuilt from [Navis.currentKey] and not from the rebuild of
  /// whoever mounts this section: the shell hands it back as the same `const`
  /// widget, which an element does not rebuild (see `FinanceSection`).
  @override
  Widget build(BuildContext context) => MultiProvider(
    // `.value`: their lifecycle is this `State`'s, not the provider's.
    providers: [
      ChangeNotifierProvider<BusinessEmployeesService>.value(value: _employees),
      ChangeNotifierProvider<AccountSecurityService>.value(value: _security),
      ChangeNotifierProvider<AccountHistoryService>.value(value: _history)
    ],
    child: ListenableBuilder(
      listenable: Listenable.merge([Navis.currentKey, _employees]),
      builder: (context, _) => switch (_employees.status) {
        BusinessEmployeesStatus.ready => _panels(context),
        BusinessEmployeesStatus.error => Surface(child: SectionMessage(
          icon: CI.info,
          title: S.of(context).business_employees_error_title,
          subtitle: S.of(context).business_employees_error_subtitle,
          action: () => _employees.load(force: true),
          actionLabel: S.of(context).business_list_retry
        )),
        _ => const Surface(child: Center(child: Loading()))
      }
    )
  );

  Widget _panels(BuildContext context) {
    final employee = _shown();
    final detail = employee?.id == null ? null : _employees.detailOf(employee!.id!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: Surface(child: EmployeeList(
          selected: employee?.key,
          onOpen: (employee) => _go(EmployeeDetailPage.path(EmployeeDetailPage.idOf(employee)))
        ))),
        SizedBox(width: AppSize.gap),
        // The surface and the person's bar stay put; only the page under the
        // bar swaps.
        Expanded(flex: 3, child: Surface(child: employee == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmployeePanelBar(child: EmployeeDetailHeader(employee: employee, detail: detail)),
                Expanded(child: _detail(context, employee))
              ]
            )
        ))
      ]
    );
  }

  /// Whoever the URL names. The bare section, or a person nobody listed (an old
  /// link, someone another business has), shows the viewer's own card, always
  /// listed.
  BusinessEmployeeModel? _shown() {
    final key = Navis.currentKey.value;
    final id = OwnSection.byRouteKey(key) != null ? BusinessEmployeeModel.meKey : Navis.currentArgs?["id"];

    return (id == null ? null : _employees.find(id)) ?? _employees.find(BusinessEmployeeModel.meKey);
  }

  /// The detail panel's page: [employee]'s, or one part of it the URL names. A
  /// part they have no page for falls back to theirs.
  Widget _detail(BuildContext context, BusinessEmployeeModel employee) {
    final key = Navis.currentKey.value;
    final part = EmployeePart.byRouteKey(key);
    final account = employee.me ? OwnSection.byRouteKey(key) : null;
    final urlId = EmployeeDetailPage.idOf(employee);
    void back() => _go(EmployeeDetailPage.path(urlId));

    if (employee.me) _readAccount();

    if (account != null) {
      return PageSwitcher(id: account, child: EmployeePage(
        title: account.title(S.of(context)),
        backLabel: employee.fullName,
        onBack: back,
        scroll: false,
        child: OwnSectionPage(section: account)
      ));
    }

    // The viewer's unfiled card has no job to read parts of.
    if (part != null && employee.id != null) {
      return PageSwitcher(id: "$urlId/${part.name}", child: EmployeePartPage(
        key: ValueKey("employee_${urlId}_${part.name}"),
        employee: employee,
        part: part,
        onBack: back
      ));
    }

    return PageSwitcher(id: urlId, child: EmployeeDetailPage(
      key: ValueKey("employee_$urlId"),
      employee: employee,
      onOpen: _go
    ));
  }
}
