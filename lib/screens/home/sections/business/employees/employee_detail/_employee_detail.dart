import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/business/employees/employee_detail/blocks/_blocks.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_note.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_search.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';

import './employee_actions.dart';
import './employee_detail_header.dart';

/// The right panel: everything the company may know about the person selected
/// on the left.
///
/// The header is drawn from the list row at once, so switching people never
/// blanks the panel; the blocks below wait for the detail read. Keyed by the
/// person in the tab, so each one asks for their own detail on mount.
class EmployeeDetailPanel extends StatefulWidget {
  const EmployeeDetailPanel({super.key, required this.employee});

  final BusinessEmployeeModel employee;

  @override
  State<EmployeeDetailPanel> createState() => _EmployeeDetailPanelState();
}

class _EmployeeDetailPanelState extends State<EmployeeDetailPanel> {
  /// The search over the blocks. Filtered on each key, not after a pause: it
  /// only hides tiles already drawn, nothing is asked. Only the [EmployeeSearch]
  /// listens to it, so a key never rebuilds the header or the actions.
  final _search = InputController(key: "search");

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
  void dispose() {
    _search.form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessEmployeesService>();
    final employee = widget.employee;
    final id = employee.id;
    final detail = id == null ? null : service.detailOf(id);

    return ScrollableWidget(
      padding: EdgeInsets.zero,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeDetailHeader(employee: employee, detail: detail),
        // The header bleeds to the edges for its wash; only what sits below
        // it is inset.
        Padding(
          padding: EdgeInsets.all(AppSize.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (id == null)
                const _Unfiled()
              else if (detail != null) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: AppSize.spaceS),
                  // Drawn like the sheets below it: it searches them, so it
                  // reads as one of them rather than a form field on top.
                  child: Input(
                    controller: _search,
                    placeholder: S.of(context).employee_search_hint,
                    leftIcon: Icon(CI.search, size: EmployeeFactFrame.hintSize, color: ThemeColor.of(context).text.secondary),
                    buttonSpace: false,
                    fillColor: ThemeColor.of(context).surface,
                    radius: EmployeeFactFrame.sheetRadius
                  )
                ),
                // Everyone sees their own; someone else's only with the view.
                if (BusinessEmployeesService.viewsAll || employee.me) Padding(
                  padding: EdgeInsets.only(bottom: AppSize.spaceS),
                  child: EmployeeActions(employee: employee)
                ),
                ListenableBuilder(
                  listenable: _search.textController,
                  builder: (context, blocks) => EmployeeSearch(query: _search.text, child: blocks!),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: employeeBlocks(context, detail, own: employee.me)
                  )
                )
              ]
              else if (service.detailStatusOf(id) == EmployeeDetailStatus.error)
                _Failed(retry: () => service.loadDetail(id, force: true))
              else
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
                  child: const Center(child: Loading())
                )
            ]
          )
        )
      ]
    );
  }
}

/// The viewer's own card when they have no job filed here: there is no
/// employment to read, only their profile.
class _Unfiled extends StatelessWidget {
  const _Unfiled();

  @override
  Widget build(BuildContext context) => EmployeeNote(
    title: S.of(context).employee_unfiled_title,
    text: S.of(context).employee_unfiled_subtitle,
    lines: 4
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.retry});

  final void Function() retry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSize.action * 6,
    child: SectionMessage(
      icon: CI.info,
      title: S.of(context).employee_detail_error_title,
      subtitle: S.of(context).employee_detail_error_subtitle,
      action: retry,
      actionLabel: S.of(context).business_list_retry
    )
  );
}
