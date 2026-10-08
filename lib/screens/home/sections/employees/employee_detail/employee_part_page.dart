import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_detail/blocks/_blocks.dart';
import 'package:app/screens/home/sections/employees/employee_page.dart';
import 'package:app/screens/home/sections/employees/employee_permissions/_employee_permissions.dart';

import './employee_part.dart';
import './widgets/employee_detail_failed.dart';
import './widgets/employee_detail_loading.dart';

/// One part of a person's card, a page of the detail panel: its blocks, read and edited in
/// place, or their permissions.
///
/// It reads the detail itself as well as the person's page does (the read is
/// shared and made once): a part's link may be the first thing opened.
class EmployeePartPage extends StatefulWidget {
  const EmployeePartPage({
    super.key,
    required this.employee,
    required this.part,
    required this.onBack
  });

  final BusinessEmployeeModel employee;
  final EmployeePart part;
  final void Function() onBack;

  @override
  State<EmployeePartPage> createState() => _EmployeePartPageState();
}

class _EmployeePartPageState extends State<EmployeePartPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.employee.id;

      if (mounted && id != null && widget.part != EmployeePart.permissions) {
        context.read<BusinessEmployeesService>().loadDetail(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final part = widget.part;
    final permissions = part == EmployeePart.permissions;

    return EmployeePage(
      title: part.title(context),
      backLabel: employee.fullName,
      onBack: widget.onBack,
      scroll: !permissions,
      child: permissions
        // One's own are shown, never changed (the backend refuses a
        // self-assignment too).
        ? employee.me
          ? const EmployeePermissions()
          : EmployeePermissions(username: employee.username, person: employee.fullName)
        : _blocks(context)
    );
  }

  Widget _blocks(BuildContext context) {
    final service = context.watch<BusinessEmployeesService>();
    final id = widget.employee.id;
    final detail = id == null ? null : service.detailOf(id);

    if (detail != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: employeePartBlocks(context, widget.part, detail, own: widget.employee.me)
      );
    }

    if (id != null && service.detailStatusOf(id) == EmployeeDetailStatus.error) {
      return EmployeeDetailFailed(retry: () => service.loadDetail(id, force: true));
    }

    return const EmployeeDetailLoading();
  }
}
