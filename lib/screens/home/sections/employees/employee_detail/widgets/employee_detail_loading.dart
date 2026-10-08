import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// While the person's detail is read.
class EmployeeDetailLoading extends StatelessWidget {
  const EmployeeDetailLoading({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
    child: const Center(child: Loading())
  );
}
