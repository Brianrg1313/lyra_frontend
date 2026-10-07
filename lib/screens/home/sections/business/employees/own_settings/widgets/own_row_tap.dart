import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


class OwnRowTap extends StatelessWidget {
  const OwnRowTap({super.key, required this.label, required this.action, required this.child});

  final String label;
  final void Function() action;
  final Widget child;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    message: label,
    radius: AppSize.cornerInset(AppSize.gap),
    color: Colors.transparent,
    feedbackColor: ThemeColor.of(context).surfaceFeedback,
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: child
  );
}
