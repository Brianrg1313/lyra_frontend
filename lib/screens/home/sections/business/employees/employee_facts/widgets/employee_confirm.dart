import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './employee_fact_frame.dart';
import './employee_saving.dart';

/// The square check beside an open field, as tall as the field: it is what
/// sends the change, so leaving the field never has to.
class EmployeeConfirm extends StatelessWidget {
  const EmployeeConfirm({super.key, required this.saving, required this.action});

  final bool saving;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: saving ? null : action,
      message: S.of(context).employee_edit_confirm,
      width: AppSize.action,
      height: AppSize.action,
      radius: EmployeeFactFrame.radius,
      color: scheme.button.fill,
      feedbackColor: scheme.button.overFill,
      child: Center(child: saving
        ? const EmployeeSaving()
        : Icon(CI.check, size: EmployeeFactFrame.iconSize, color: scheme.button.text))
    );
  }
}
