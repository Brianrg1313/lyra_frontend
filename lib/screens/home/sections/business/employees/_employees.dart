import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Employees tab: the people who enter the company, with which rank and what
/// each one can do.
///
/// For now the only thing there is is how many they are. That number lived in
/// the profile and moved here, which is its section: the company's identity
/// card should not have to carry a count that nobody is looking at.
///
/// Who they are is still not modeled on the other side, so below the number
/// the notice stays. The tab shows anyway, and it does not hide, for the same
/// reason the side bar leaves blocked sections in view: so that it is seen
/// from day one what parts a business is made of.
class BusinessEmployeesTab extends StatefulWidget {
  const BusinessEmployeesTab({super.key});

  @override
  State<BusinessEmployeesTab> createState() => _BusinessEmployeesTabState();
}

class _BusinessEmployeesTabState extends State<BusinessEmployeesTab> {
  @override
  void initState() {
    super.initState();

    // It is deferred to the first frame because the load notifies the service,
    // and notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessService>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();

    return switch (service.employeesStatus) {
      BusinessEmployeesStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).business_employees_error_title,
        subtitle: S.of(context).business_employees_error_subtitle,
        action: () => service.loadEmployees(force: true),
        actionLabel: S.of(context).business_list_retry
      ),
      BusinessEmployeesStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Count(total: service.employees),
          SizedBox(height: AppSize.padding),
          // The notice takes what is left: the tab remains, above all, the list that
          // is still missing.
          Expanded(child: SectionMessage(
            icon: CI.employee,
            title: S.of(context).coming_soon,
            subtitle: S.of(context).business_employees_soon
          ))
        ]
      ),
      _ => const Center(child: Loading())
    };
  }
}

/// How many people enter the company, as a card.
///
/// It is data and not a title: it goes on its own surface —a block on the
/// body's sheet, like the profile's— and not loose over the notice.
class _Count extends StatelessWidget {
  const _Count({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Row(children: [
        Icon(CI.employee, size: AppSize.text, color: scheme.text.secondary),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: TextSmall(
          S.of(context).business_employees_total,
          color: scheme.text.secondary
        )),
        TextLarge("$total")
      ])
    );
  }
}
