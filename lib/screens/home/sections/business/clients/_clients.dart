import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

/// Clients tab: who the company sells to and what they bought.
///
/// There is still no source for them, so the tab exists but notifies that it
/// is missing (see `BusinessEmployeesTab`).
class BusinessClientsTab extends StatelessWidget {
  const BusinessClientsTab({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.user,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).business_clients_soon
  );
}
