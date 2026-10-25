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

/// The shipment's name, its state, whose it is and where it goes: the
/// customer with their conversation a tap away, the address with the map a
/// tap away. The number is set in the stub's printed face. A shipment nobody
/// has touched says so: it is the backend's reading of a paid delivery, not
/// something a person left.
class ShipmentHeading extends StatelessWidget {
  const ShipmentHeading({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final chat = shipment.chat;
    final destination = shipment.destination;
    final maps = destination.maps.isEmpty ? null : Uri.tryParse(destination.maps);
    final contact = shipment.contact != shipment.customer ? shipment.contact : "";
    final area = [destination.place, destination.area].where((part) => part.isNotEmpty).join(", ");

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: TextMedium(shipmentTitle(context, shipment), font: TextFont.bebas, multiplier: 2.4, ellipsis: true)),
        SizedBox(width: AppSize.gap),
        SettingsTag(
          label: shipmentStateName(service, shipment),
          color: shipmentStateColor(context, shipment.state)
        )
      ]),
      if (shipment.number.isNotEmpty && shipment.ticket.isNotEmpty)
        TextSmall(s.shipment_ticket(shipment.ticket), color: scheme.text.secondary, selectable: true),
      if (!shipment.stored) ...[
        SizedBox(height: AppSize.gap),
        TextSmall(s.shipment_untouched, lines: 3, color: scheme.text.secondary)
      ],
      SizedBox(height: AppSize.spaceS),
      _Fact(
        icon: CI.user,
        title: shipment.customer.isNotEmpty ? shipment.customer : (contact.isNotEmpty ? contact : s.shipment_customer_unknown),
        detail: shipment.customer.isNotEmpty ? contact : "",
        muted: shipment.customer.isEmpty && contact.isEmpty,
        action: chat == null ? null : SettingsAction(
          icon: CI.chat,
          message: s.shipment_open_chat,
          action: () => _openChat(context, chat)
        )
      ),
      SizedBox(height: AppSize.spaceXS),
      _Fact(
        icon: CI.home,
        title: destination.address.isNotEmpty
          ? destination.address
          : destination.hasPoint ? s.shipments_destination_pin : s.shipments_destination_none,
        detail: area,
        muted: destination.address.isEmpty,
        selectable: destination.address.isNotEmpty,
        action: maps == null ? null : SettingsAction(
          icon: CI.link,
          message: s.shipment_open_map,
          action: () => unawaited(launchUrl(maps, mode: LaunchMode.externalApplication))
        )
      )
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

/// One fact of the heading: what it is, in the text colour, with what
/// narrows it under it and the one thing done with it at the right.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.title,
    this.detail = "",
    this.muted = false,
    this.selectable = false,
    this.action
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool muted;
  final bool selectable;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.only(top: AppSize.gap * 0.4),
        child: Icon(icon, size: AppSize.text, color: scheme.text.secondary)
      ),
      SizedBox(width: AppSize.gap),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextMedium(title, lines: 2, ellipsis: true, selectable: selectable, color: muted ? scheme.text.secondary : null),
        if (detail.isNotEmpty) TextSmall(detail, ellipsis: true, color: scheme.text.secondary)
      ])),
      if (action != null) ...[
        SizedBox(width: AppSize.gap),
        action!
      ]
    ]);
  }
}

/// Who carries it, when, and what it cost, read only (no `shipments.dispatch`).
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
        if (shipment.cost != null) SettingsValue(
          icon: CI.receipt,
          label: s.shipment_cost,
          value: deliveryAmount(shipment.cost!, shipment.currency)
        ),
        if (shipment.note.isNotEmpty) SettingsValue(icon: CI.pen, label: s.shipment_note, value: shipment.note),
        if (shipment.receiver.isNotEmpty) SettingsValue(icon: CI.user_circle, label: s.shipment_receiver, value: shipment.receiver)
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
