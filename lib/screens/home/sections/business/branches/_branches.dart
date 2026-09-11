import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Branches tab: the company's locations, each with its address and what is
/// handled there.
///
/// There is still no source for them, so the tab exists but notifies that it
/// is missing (see `BusinessEmployeesTab`).
class BusinessBranchesTab extends StatelessWidget {
  const BusinessBranchesTab({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.shop,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).business_branches_soon
  );
}
