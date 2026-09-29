import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './employee_avatar.dart';
import './employee_blocks.dart';
import './employee_card.dart';
import './employee_format.dart';

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
  /// only hides tiles already drawn, nothing is asked.
  final _search = InputController(key: "search");

  @override
  void initState() {
    super.initState();
    _search.textController.addListener(_searched);

    // Deferred: the read notifies, and notifying while mounting rebuilds
    // mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.employee.id;

      if (mounted && id != null) context.read<BusinessEmployeesService>().loadDetail(id);
    });
  }

  @override
  void dispose() {
    _search.textController.removeListener(_searched);
    _search.form.dispose();
    super.dispose();
  }

  void _searched() {
    if (mounted) setState(() {});
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
        _Header(employee: employee, detail: detail),
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
                  child: Input(
                    controller: _search,
                    placeholder: S.of(context).employee_search_hint,
                    leftIcon: Icon(CI.search, size: AppSize.text * 1.2, color: ThemeColor.of(context).text.secondary),
                    buttonSpace: false
                  )
                ),
                EmployeeSearch(
                  query: _search.text,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: employeeBlocks(context, detail)
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

/// Who: picture, name, username, the headline they wrote, and the tags that
/// say where they stand.
class _Header extends StatelessWidget {
  const _Header({required this.employee, this.detail});

  final BusinessEmployeeModel employee;
  final BusinessEmployeeDetail? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final person = detail?.person;
    // An invited email with no account yet has no names and a placeholder
    // username: the row's email names it, and the username is not shown.
    final unclaimed = employee.email.isNotEmpty;
    final name = unclaimed ? employee.fullName : person?.fullName ?? employee.fullName;
    final username = unclaimed ? "" : person?.username ?? employee.username;
    final headline = person?.headline ?? "";
    final state = detail?.state ?? employee.state;
    final presence = employeePresence(
      context,
      state: state,
      work: detail?.workStatus ?? employee.workStatus
    );
    final warning = employeeContractWarning(context, detail?.contractStatus);
    final job = [detail?.job.title ?? employee.jobTitle, detail?.job.department ?? employee.department]
      .where((part) => part.isNotEmpty)
      .join(" · ");
    // Work first: it is the channel the company is meant to use.
    final phone = [detail?.job.workPhone ?? "", person?.phone ?? ""].firstWhere((v) => v.isNotEmpty, orElse: () => "");
    final email = [detail?.job.workEmail ?? "", person?.email ?? "", employee.email]
      .firstWhere((v) => v.isNotEmpty, orElse: () => "");
    final radius = AppSize.cornerInset(AppSize.gap);

    // A wash of the presence color from the top: where the person stands is
    // read before their name, as the status dot does in the list.
    return Container(
      padding: EdgeInsets.all(AppSize.padding * 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius)
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.background.withValues(alpha: 0.16), scheme.background]
        )
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              EmployeeAvatar(
                name: name,
                picture: person?.picture ?? employee.picture,
                size: AppSize.action * 2.6,
                status: presence.color,
                ring: scheme.surfaceOver
              ),
              SizedBox(width: AppSize.spaceS),
              Flexible(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextInter(
                    name,
                    bold: true,
                    multiplier: 1.8,
                    ellipsis: true,
                    selectable: true
                  ),
                  if (username.isNotEmpty) ...[
                    TextSmall("@$username", ellipsis: true, color: scheme.text.secondary)
                  ],
                  if (phone.isNotEmpty || email.isNotEmpty) ...[
                    SizedBox(height: AppSize.gap),
                    Row(children: [
                      if (phone.isNotEmpty) EmployeeQuickAction(
                        icon: CI.phone,
                        label: S.of(context).employee_field_phone,
                        value: phone
                      ),
                      if (phone.isNotEmpty && email.isNotEmpty) SizedBox(width: AppSize.gap * 0.75),
                      if (email.isNotEmpty) EmployeeQuickAction(
                        icon: CI.mail,
                        label: S.of(context).employee_field_email,
                        value: email
                      )
                    ])
                  ],
                  SizedBox(height: AppSize.gap),
                  Wrap(
                    spacing: AppSize.gap * 0.5,
                    runSpacing: AppSize.gap * 0.5,
                    children: [
                      SettingsTag(icon: presence.icon, label: presence.label, color: presence.color),
                      if (employee.me) SettingsTag(
                        icon: CI.user,
                        label: S.of(context).employees_you,
                        color: scheme.primary
                      ),
                      if (warning != null) SettingsTag(
                        icon: CI.info,
                        label: warning.label,
                        color: warning.color
                      )
                    ]
                  ),
                  if (job.isNotEmpty) ...[
                    SizedBox(height: AppSize.gap * 0.75),
                    TextSmall(job, ellipsis: true, color: scheme.text.secondary)
                  ]
                ]
              ))
            ]),
          if (headline.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceS),
            TextSmall(headline, lines: 3, ellipsis: true)
          ]
        ]
      )
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
