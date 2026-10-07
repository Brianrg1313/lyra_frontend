import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

/// Left panel: the deliveries still on their way.
///
/// Placeholder: the backend has no endpoint for the list yet.
class PendingDeliveriesPanel extends StatelessWidget {
  const PendingDeliveriesPanel({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.delivery,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).deliveries_pending_soon
  );
}
