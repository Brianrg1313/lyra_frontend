import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/sub_page.dart';

import './settings_body.dart';

/// **Delivery settings**: sub-page of the `deliveries` section
/// (`/home/deliveries/settings`), opened from the desk's header.
///
/// It is where everything the company decides about delivering is set, apart
/// from following the deliveries themselves: the desk is for working a shift,
/// this page is for what changes once in a while. It used to be a tab of the
/// business page and moved here to sit next to the deliveries it shapes.
///
/// The URL carries no id: every `/business/delivery/` endpoint answers for the
/// active company (the `business_id` header), and a business switch remounts
/// the home content (see `homeContent`), which drops what was read here.
class DeliverySettingsSection extends StatefulWidget {
  const DeliverySettingsSection({super.key});

  /// Key of its route. The only source: the route table and the shell use it.
  static const String routeKey = "deliveries_settings";

  static const String path = "/home/deliveries/settings";

  @override
  State<DeliverySettingsSection> createState() => _DeliverySettingsSectionState();
}

class _DeliverySettingsSectionState extends State<DeliverySettingsSection> {
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
      child: DeliveriesSubPage(
        title: S.of(context).deliveries_settings_title,
        backPath: "/home/deliveries",
        backLabel: S.of(context).deliveries,
        child: const DeliverySettingsBody()
      )
    );
}
