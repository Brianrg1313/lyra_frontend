import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// That the row opens a panel of its own.
class OwnArrow extends StatelessWidget {
  const OwnArrow({super.key});

  @override
  Widget build(BuildContext context) =>
    Icon(CI.arrow_right, size: AppSize.text * 0.9, color: ThemeColor.of(context).text.secondary);
}
