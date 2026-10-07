import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS

class InventoryStartCard extends StatelessWidget {
  const InventoryStartCard({super.key, required this.action, required this.child});

  final void Function()? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    color: ThemeColor.of(context).surfaceOver,
    radius: AppSize.corner,
    padding: EdgeInsets.all(AppSize.spaceS),
    child: SizedBox(
      height: AppSize.action * 2.4,
      child: Align(alignment: Alignment.topLeft, child: child)
    )
  );
}
