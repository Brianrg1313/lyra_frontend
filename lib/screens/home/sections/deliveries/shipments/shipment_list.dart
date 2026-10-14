import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:app/screens/modals/deliveries/shipping_settings/_shipping_settings.dart';

import '../widgets/panel_halves.dart';
import './shipment_tile.dart';

/// **The branch's deliveries**, in the desk's panel: what is still going or
/// what was delivered, each one a tile that opens its panel. The branch's
/// schedule (its franjas, week and closed days) opens from beside the switch.
///
/// A shipment opens on its own when a customer's payment for a delivery is
/// approved: there is nothing to create here, so an empty board says where
/// they come from.
class ShipmentList extends StatelessWidget {
  const ShipmentList({super.key, required this.onOpen, this.lit});

  final void Function(Shipment shipment) onOpen;

  /// The shipment picked on the map.
  final String? lit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final service = context.watch<ShipmentsService>();
    final branch = BranchService().active?.name ?? "";

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: TextMedium(
          branch.isEmpty ? s.shipments_title : s.shipments_title_branch(branch),
          bold: true,
          ellipsis: true
        )),
        SizedBox(width: AppSize.gap),
        FeedbackButton(
          action: () => showShippingSettings(context, service: service),
          height: AppSize.action,
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
          radius: AppSize.corner,
          color: scheme.surfaceOver,
          feedbackColor: scheme.line,
          message: s.shipping_settings_title,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(CI.calendar, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            TextSmall(s.shipments_schedule, bold: true)
          ])
        )
      ]),
      SizedBox(height: AppSize.gap),
      PanelHalves<ShipmentsView>(
        values: ShipmentsView.values,
        selected: service.view,
        label: (view) => switch (view) {
          ShipmentsView.going => service.view == view && service.status == ShipmentsStatus.ready
            ? s.shipments_going_count(service.shipments.length)
            : s.shipments_going,
          ShipmentsView.delivered => s.shipments_delivered
        },
        onChanged: service.show
      ),
      SizedBox(height: AppSize.spaceS),
      Expanded(child: _body(context, service))
    ]);
  }

  Widget _body(BuildContext context, ShipmentsService service) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    Widget note(String title, String subtitle, {void Function()? retry}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextSmall(title, bold: true, lines: 2),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(subtitle, lines: 4, color: scheme.text.secondary),
        if (retry != null) ...[
          SizedBox(height: AppSize.gap),
          FeedbackButton(
            action: retry,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
            radius: AppSize.corner,
            feedbackColor: scheme.surfaceFeedback,
            child: TextSmall(s.deliveries_map_retry, bold: true, color: scheme.primary)
          )
        ]
      ]
    );

    return switch (service.status) {
      ShipmentsStatus.error => note(s.shipments_error, s.shipments_error_subtitle, retry: service.retry),
      ShipmentsStatus.empty => service.view == ShipmentsView.going
        ? note(s.shipments_empty, s.shipments_empty_subtitle)
        : note(s.shipments_delivered_empty, s.shipments_delivered_empty_subtitle),
      ShipmentsStatus.ready => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: service.shipments.length,
        itemBuilder: (context, index) {
          final shipment = service.shipments[index];

          return ShipmentTile(
            key: ValueKey(shipment.id),
            shipment: shipment,
            service: service,
            lit: shipment.id == lit,
            onTap: () => onOpen(shipment)
          );
        }
      ),
      _ => const Center(child: Loading())
    };
  }
}
