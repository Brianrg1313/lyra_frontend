import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Pestana de sucursales: los locales de la empresa, cada uno con su direccion
/// y lo que se maneja ahi.
///
/// Todavia no hay de donde sacarlas, asi que la pestana existe pero avisa que
/// falta (ver `BusinessEmployeesTab`).
class BusinessBranchesTab extends StatelessWidget {
  const BusinessBranchesTab({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.shop,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).business_branches_soon
  );
}
