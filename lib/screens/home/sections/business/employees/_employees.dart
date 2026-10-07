import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employees_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/business/employees/employee_detail/_employee_detail.dart';
import 'package:app/screens/home/sections/business/employees/employee_list/_employee_list.dart';

/// Employees tab: one sheet split in two panels (the tab draws that sheet
/// itself, see `BusinessTab.ownsSurface`). On the left, the main one,
/// everyone who works here — the viewer's own card first — with where
/// each one stands; on the right, everything about the person selected there.
///
/// Who is open is state of the tab and not a URL, like the open chat of the
/// messages desk: people are switched constantly while working, and a route
/// per person would stack history nobody walks back through. The first read
/// opens the viewer's own card.
///
/// The lists are `BusinessEmployeesService`, provided by the business page:
/// switching tabs keeps what was read.
class BusinessEmployeesTab extends StatefulWidget {
  const BusinessEmployeesTab({super.key});

  @override
  State<BusinessEmployeesTab> createState() => _BusinessEmployeesTabState();
}

class _BusinessEmployeesTabState extends State<BusinessEmployeesTab> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame: the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessEmployeesService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessEmployeesService>();

    return switch (service.status) {
      BusinessEmployeesStatus.ready => Surface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: Padding(
              padding: EdgeInsets.all(AppSize.padding),
              child: const EmployeeList()
            )),
            // Inset by the gap and lined like the side bar, so the detail
            // reads as a panel over the sheet instead of a second sheet.
            Expanded(flex: 2, child: Padding(
              padding: EdgeInsets.all(AppSize.padding),
              child: Surface.line(
                color: ThemeColor.of(context).surfaceOver,
                radius: AppSize.cornerInset(AppSize.gap),
                child: _Selected(service: service)
              )
            ))
          ]
        )),
      // Same sheet while there are no panels to split it into.
      BusinessEmployeesStatus.error => Surface(child: SectionMessage(
        icon: CI.info,
        title: S.of(context).business_employees_error_title,
        subtitle: S.of(context).business_employees_error_subtitle,
        action: () => service.load(force: true),
        actionLabel: S.of(context).business_list_retry
      )),
      _ => const Surface(child: Center(child: Loading()))
    };
  }
}

/// The right panel, keyed by the person so each one mounts its own and asks
/// for their own detail.
class _Selected extends StatelessWidget {
  const _Selected({required this.service});

  final BusinessEmployeesService service;

  @override
  Widget build(BuildContext context) {
    final employee = service.selected;

    if (employee == null) {
      return SectionMessage(
        icon: CI.employee,
        title: S.of(context).employees_select_title,
        subtitle: S.of(context).employees_select_subtitle
      );
    }

    return EmployeeDetailPanel(
      key: ValueKey("employee_${employee.key}"),
      employee: employee
    );
  }
}
