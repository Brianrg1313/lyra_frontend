import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_detail/blocks/_blocks.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_note.dart';
import 'package:app/screens/home/sections/employees/employee_page.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_section.dart';
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_sign_in_posture.dart';

import './employee_part.dart';
import './widgets/employee_detail_failed.dart';
import './widgets/employee_detail_loading.dart';
import './widgets/employee_index_group.dart';
import './widgets/employee_index_row.dart';

/// One person's page, under their bar in the detail panel: the headline they
/// wrote, then an index of the parts of their card ([EmployeePart]), each
/// opening its own page where it is read and edited. On the viewer's own card
/// the subsections of their account ([OwnSection]) follow.
///
/// The parts wait for the detail read, since which ones have something to say
/// depends on it. Keyed by
/// the person, so each one asks for their own detail on mount.
class EmployeeDetailPage extends StatefulWidget {
  const EmployeeDetailPage({
    super.key,
    required this.employee,
    required this.onOpen
  });

  static const String routeKey = "employee";

  /// URL of the person [id] ([idOf]).
  static String path(String id) => "/home/employees/$id";

  /// The id of [employee] in its URL: the viewer's card is always
  /// [BusinessEmployeeModel.meKey], so it is linked to without knowing its id.
  static String idOf(BusinessEmployeeModel employee) =>
    employee.me ? BusinessEmployeeModel.meKey : employee.key;

  final BusinessEmployeeModel employee;

  /// Opens one of the pages listed here, by its path.
  final void Function(String path) onOpen;

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  @override
  void initState() {
    super.initState();

    // Deferred: the read notifies, and notifying while mounting rebuilds
    // mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.employee.id;

      if (mounted && id != null) context.read<BusinessEmployeesService>().loadDetail(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final service = context.watch<BusinessEmployeesService>();
    final employee = widget.employee;
    final id = employee.id;
    final detail = id == null ? null : service.detailOf(id);
    final urlId = EmployeeDetailPage.idOf(employee);
    final headline = detail?.person.headline ?? "";

    // Someone else's permissions open only for whoever may read and assign
    // them; one's own, always.
    final permitted = employee.me || context.watch<PermissionsService>().can("business.employees.permissions");

    EmployeeIndexRow partRow(EmployeePart part) => EmployeeIndexRow(
      icon: part.icon,
      title: part.title(context),
      subtitle: part.subtitle(context),
      action: () => widget.onOpen(part.path(urlId))
    );

    EmployeeIndexRow accountRow(OwnSection section) => EmployeeIndexRow(
      icon: section.icon,
      title: section.title(s),
      subtitle: section.subtitle(s),
      soon: section.soon,
      action: () => widget.onOpen(section.path)
    );

    // No arrow: the list beside it is the way to someone else.
    return EmployeePage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headline.isNotEmpty) Padding(
            padding: EdgeInsets.only(left: AppSize.spaceXS, bottom: AppSize.spaceM),
            child: TextSmall(headline, lines: 3, ellipsis: true, color: ThemeColor.of(context).text.secondary)
          ),
          if (id == null)
            const _Unfiled()
          else if (detail != null)
            EmployeeIndexGroup(title: s.employee_index_work, rows: [
              for (final part in EmployeePart.values)
                if (part == EmployeePart.permissions
                  ? permitted
                  : employeePartBlocks(context, part, detail, own: employee.me).isNotEmpty) partRow(part)
            ])
          else if (service.detailStatusOf(id) == EmployeeDetailStatus.error)
            EmployeeDetailFailed(retry: () => service.loadDetail(id, force: true))
          else
            const EmployeeDetailLoading(),
          if (employee.me) ...[
            // The security service is provided and read only where the cloud is.
            if (CapabilityService().shows("account.security")) const OwnSignInPosture(),
            SizedBox(height: AppSize.spaceM),
            EmployeeIndexGroup(title: s.employee_index_account, rows: [
              for (final section in OwnSection.values.where((section) => !section.soon)) accountRow(section)
            ]),
            SizedBox(height: AppSize.spaceS),
            EmployeeIndexGroup(rows: [
              for (final section in OwnSection.values.where((section) => section.soon)) accountRow(section)
            ])
          ]
        ]
      )
    );
  }
}

/// The viewer's own card when they have no job filed here: there is no
/// employment to read, only their account.
class _Unfiled extends StatelessWidget {
  const _Unfiled();

  @override
  Widget build(BuildContext context) => EmployeeNote(
    title: S.of(context).employee_unfiled_title,
    text: S.of(context).employee_unfiled_subtitle,
    lines: 4
  );
}
