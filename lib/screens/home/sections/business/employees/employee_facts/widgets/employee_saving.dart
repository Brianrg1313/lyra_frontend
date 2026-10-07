import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES

// WIDGETS


/// The small spinner of a tile whose change is on its way.
class EmployeeSaving extends StatelessWidget {
  const EmployeeSaving({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSize.text,
    child: const FittedBox(child: Loading())
  );
}
