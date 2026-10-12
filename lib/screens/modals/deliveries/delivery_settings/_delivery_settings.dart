import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_service.dart';

import './settings_body.dart';

/// Opens the delivery settings over the deliveries desk.
///
/// A side panel and not a page: these answers change once in a while, and the
/// map they shape stays in sight to the left while they are set.
///
/// "Select delivery area" only closes it: the areas are drawn and edited on
/// the desk under it.
Future<void> showDeliverySettings(BuildContext context) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  await showSideModal(
    context: context,
    title: S.of(context).deliveries_settings_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => const DeliverySettingsModal()
  );
}

/// Room for a flag's answer and the area link on one line.
const double _width = 480;

/// Everything the company decides about delivering, apart from following the
/// deliveries themselves.
///
/// It owns its [BusinessDeliveryService]: the panel opens above the section's
/// providers, and every `/business/delivery/` endpoint answers for the active
/// company, so a fresh read on each opening is the right one.
class DeliverySettingsModal extends StatefulWidget {
  const DeliverySettingsModal({super.key});

  @override
  State<DeliverySettingsModal> createState() => _DeliverySettingsModalState();
}

class _DeliverySettingsModalState extends State<DeliverySettingsModal> {
  final BusinessDeliveryService _delivery = BusinessDeliveryService();

  @override
  void dispose() {
    _delivery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider<BusinessDeliveryService>.value(
      value: _delivery,
      child: DeliverySettingsBody(onArea: () => Navigator.pop(context))
    );
}
