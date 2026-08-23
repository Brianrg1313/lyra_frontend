import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Pestana de clientes: a quien le vende la empresa y que le compro.
///
/// Todavia no hay de donde sacarlos, asi que la pestana existe pero avisa que
/// falta (ver `BusinessEmployeesTab`).
class BusinessClientsTab extends StatelessWidget {
  const BusinessClientsTab({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.user,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).business_clients_soon
  );
}
