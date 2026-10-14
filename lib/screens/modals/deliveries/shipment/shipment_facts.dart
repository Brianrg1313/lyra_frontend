import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:url_launcher/url_launcher.dart';

// SERVICES
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import 'package:app/screens/home/sections/deliveries/shipments/shipment_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The shipment's name, its state, and whose it is: the customer, with their
/// conversation a tap away. A shipment nobody has touched says so: it is the
/// backend's reading of a paid delivery, not something a person left.
class ShipmentHeading extends StatelessWidget {
  const ShipmentHeading({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final chat = shipment.chat;
    final who = [
      if (shipment.customer.isNotEmpty) shipment.customer,
      if (shipment.contact.isNotEmpty && shipment.contact != shipment.customer) shipment.contact
    ].join(" · ");

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextLarge(shipmentTitle(context, shipment), ellipsis: true)),
        SizedBox(width: AppSize.gap),
        SettingsTag(
          label: shipmentStateName(service, shipment),
          color: shipmentStateColor(context, shipment.state)
        )
      ]),
      if (shipment.number.isNotEmpty && shipment.ticket.isNotEmpty) ...[
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(s.shipment_ticket(shipment.ticket), color: scheme.text.secondary, selectable: true)
      ],
      if (!shipment.stored) ...[
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(s.shipment_untouched, lines: 3, color: scheme.text.secondary)
      ],
      if (who.isNotEmpty || chat != null) ...[
        SizedBox(height: AppSize.spaceS),
        Row(children: [
          Icon(CI.user, size: AppSize.text, color: scheme.text.secondary),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextMedium(who.isEmpty ? s.shipment_customer_unknown : who, ellipsis: true)),
          if (chat != null) SettingsAction(
            icon: CI.chat,
            message: s.shipment_open_chat,
            action: () => _openChat(context, chat)
          )
        ])
      ]
    ]);
  }

  /// The messages desk opens on the conversation it remembers, so it is told
  /// this one before going there.
  void _openChat(BuildContext context, String chat) {
    PreferencesService().remember(RememberedSelection.chat, chat);
    Navigator.of(context).maybePop();
    Navis.navigate(HomeSection.messages.path);
  }
}

/// Who carries it and when, read only (no `shipments.dispatch`).
class ShipmentCarrying extends StatelessWidget {
  const ShipmentCarrying({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final window = shipment.window;

    return SettingsBlock(
      title: s.shipment_carrying,
      child: SettingsList(rows: [
        SettingsValue(
          icon: CI.delivery,
          label: s.shipment_carrier,
          value: shipmentCarrierLabel(context, shipment.carrier)
        ),
        SettingsValue(
          icon: CI.calendar,
          label: s.shipment_window,
          value: window == null ? "" : shipmentWindowLabel(context, window),
          empty: s.shipments_window_none
        ),
        if (shipment.note.isNotEmpty) SettingsValue(icon: CI.pen, label: s.shipment_note, value: shipment.note),
        if (shipment.receiver.isNotEmpty) SettingsValue(icon: CI.user_circle, label: s.shipment_receiver, value: shipment.receiver)
      ])
    );
  }
}

/// Where it goes: the address, the place and area the conversation settled,
/// and the point, opened in any map.
class ShipmentDestinationBlock extends StatelessWidget {
  const ShipmentDestinationBlock({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final destination = shipment.destination;
    final maps = Uri.tryParse(destination.maps);

    return SettingsBlock(
      title: s.shipment_destination,
      action: maps == null || destination.maps.isEmpty ? null : SettingsAction(
        icon: CI.link,
        message: s.shipment_open_map,
        action: () => unawaited(launchUrl(maps, mode: LaunchMode.externalApplication))
      ),
      child: SettingsList(rows: [
        SettingsValue(
          icon: CI.home,
          label: s.shipment_address,
          value: destination.address,
          empty: destination.hasPoint ? s.shipments_destination_pin : s.shipments_destination_none,
          selectable: true
        ),
        if (destination.place.isNotEmpty || destination.area.isNotEmpty) SettingsValue(
          icon: CI.globe_shopping,
          label: s.shipment_area,
          value: [destination.place, destination.area].where((part) => part.isNotEmpty).join(" · ")
        ),
        if (destination.hasPoint) SettingsValue(
          icon: CI.globe_shopping,
          label: s.shipment_point,
          value: "${destination.latitude!.toStringAsFixed(6)}, ${destination.longitude!.toStringAsFixed(6)}",
          selectable: true
        )
      ])
    );
  }
}

/// What the sale is worth, what the customer paid for the delivery, what
/// carrying it cost, and whether the rider collects on delivery.
class ShipmentMoney extends StatelessWidget {
  const ShipmentMoney({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    String amount(double? value) => value == null ? "" : deliveryAmount(value, shipment.currency);

    return SettingsBlock(
      title: s.shipment_money,
      child: SettingsList(rows: [
        SettingsRow(
          icon: CI.wallet,
          label: s.shipment_total,
          hint: shipment.charged ? null : s.shipment_collect_hint,
          child: TextMedium(
            shipment.total == null ? s.shipment_none : amount(shipment.total),
            bold: !shipment.charged,
            color: shipment.charged ? null : scheme.chart.warning
          )
        ),
        SettingsValue(icon: CI.delivery_square, label: s.shipment_fee, value: amount(shipment.fee), empty: s.shipment_none),
        SettingsValue(icon: CI.receipt, label: s.shipment_cost, value: amount(shipment.cost), empty: s.shipment_none)
      ])
    );
  }
}

/// Every state it went through, newest first.
class ShipmentHistory extends StatelessWidget {
  const ShipmentHistory({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final steps = shipment.history.reversed.toList();

    return SettingsBlock(
      title: s.shipment_history,
      child: steps.isEmpty
        ? TextSmall(s.shipment_history_empty, lines: 2, color: scheme.text.secondary)
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final step in steps) Padding(
              padding: EdgeInsets.only(bottom: AppSize.gap),
              child: Row(children: [
                Container(
                  width: AppSize.gap,
                  height: AppSize.gap,
                  decoration: BoxDecoration(color: shipmentStateColor(context, step.state), shape: BoxShape.circle)
                ),
                SizedBox(width: AppSize.gap),
                Expanded(child: TextSmall(
                  service.nameOf(step.state, fallback: step.label.isNotEmpty ? step.label : step.state.code),
                  ellipsis: true
                )),
                if (step.at != null) TextSmall(shipmentMomentLabel(context, step.at!), color: scheme.text.secondary)
              ])
            )
          ])
    );
  }
}
