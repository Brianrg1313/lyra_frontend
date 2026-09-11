import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Statistics tab: how the company is doing —sales, movement, growth— without
/// leaving it.
///
/// It is the same thing the side bar's report sections look at, but of this
/// company and summarized; there is still no source for it, so the tab exists
/// but notifies that it is missing (see `BusinessEmployeesTab`).
class BusinessStatisticsTab extends StatelessWidget {
  const BusinessStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.chart,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).business_statistics_soon
  );
}
