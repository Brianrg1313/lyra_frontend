import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_format.dart';

/// A dated entry (an absence, the last day): a calendar leaf with the month
/// and the day, what it is, and how long.
class EmployeeEvent extends StatelessWidget {
  const EmployeeEvent({
    super.key,
    required this.date,
    required this.title,
    this.subtitle = "",
    this.color
  });

  final DateTime? date;
  final String title;
  final String subtitle;

  /// Tint of the leaf, for an entry that matters today.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final leaf = employeeCalendarLeaf(context, date);
    final tint = color ?? scheme.text.primary;

    return Surface(
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.all(AppSize.gap),
      child: Row(children: [
        Container(
          width: AppSize.text * 3,
          padding: EdgeInsets.symmetric(vertical: AppSize.gap * 0.5),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap, AppSize.gap * 1.5))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextSmall(leaf.month, multiplier: 0.8, color: color ?? scheme.text.secondary),
              TextMedium(leaf.day, bold: true, multiplier: 1.2, color: color)
            ]
          )
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextMedium(title, bold: true, ellipsis: true),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: AppSize.gap * 0.25),
              TextSmall(subtitle, lines: 2, ellipsis: true, color: scheme.text.secondary)
            ]
          ]
        ))
      ])
    );
  }
}
