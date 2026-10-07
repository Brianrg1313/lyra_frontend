import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/modals/business/invite_employee/_invite_employee.dart';

import './employee_list_columns.dart';
import './employee_list_heading.dart';
import './employee_row.dart';

/// The left panel: everyone who works here, with where each one stands, and
/// below them who used to.
///
/// The viewer's own card is always the first row (the service keeps it
/// there), marked as theirs. Touching a row opens it on the right.
class EmployeeList extends StatelessWidget {
  const EmployeeList({super.key});

  /// Below this width the contract and start-date columns are dropped: the
  /// name and the status are what a row cannot lose.
  static const double _wide = 560;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessEmployeesService>();
    final invited = service.current
      .where((employee) => employee.state == EmployeeState.invited)
      .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeListHeading(
          // Without the view the list is only the viewer's card, so no count
          // speaks for the company.
          counts: BusinessEmployeesService.viewsAll,
          active: service.total,
          invited: invited,
          onInvite: PermissionsService().can("business.employees.invite")
            ? () => showInviteEmployee(context, employees: service)
            : null
        ),
        SizedBox(height: AppSize.spaceS),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wide;

          /// One group of rows with a line between each pair — never above
          /// the first or below the last, so a group title sits flush.
          List<Widget> group(List<BusinessEmployeeModel> employees) => [
            for (var i = 0; i < employees.length; i++) ...[
              if (i > 0) Separator.horizontal(
                margin: EdgeInsets.symmetric(vertical: AppSize.gap * 0.5)
              ),
              EmployeeRow(
                employee: employees[i],
                wide: wide,
                selected: employees[i].key == service.selectedKey,
                onTap: () => service.select(employees[i].key)
              )
            ]
          ];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (wide) const EmployeeListColumns(),
              ...group(service.current),
              if (service.former.isNotEmpty) ...[
                _GroupTitle(
                  title: S.of(context).employees_former_title,
                  count: service.former.length
                ),
                ...group(service.former)
              ]
            ]
          );
        }))
      ]
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: AppSize.spaceS,
      bottom: AppSize.gap,
      left: AppSize.spaceXS
    ),
    child: TextSmall(
      "$title · $count",
      ellipsis: true,
      color: ThemeColor.of(context).text.secondary
    )
  );
}
