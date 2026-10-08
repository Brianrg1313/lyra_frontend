import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

/// The person's detail could not be read: the pages that need it say so, with a retry.
class EmployeeDetailFailed extends StatelessWidget {
  const EmployeeDetailFailed({super.key, required this.retry});

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
