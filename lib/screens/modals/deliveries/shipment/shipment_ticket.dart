import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_detail_service.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import 'package:app/screens/home/sections/deliveries/shipments/shipment_format.dart';
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/sales/sale_items/_sale_items.dart';

import './shipment_facts.dart';

/// **The delivery and the ticket it carries**, as one stub: whose order it is,
/// where it goes and where it stands above the tear, what goes in the bag
/// below it with "View ticket" opening every line (`showSaleItems`, stacked on
/// the panel), and what the door is owed at its foot. Each fact is said here
/// once, so the blocks below only hold what the dispatcher does.
///
/// A shipment is named by its sale (`GET /sales/detail/:ID` takes the same
/// id), so the stub reads the sale once when the panel opens; a channel order
/// whose sale does not answer by its id is asked for by its conversation.
/// The read is the panel's own, like the sale's panel: nothing is cached.
class ShipmentTicket extends StatefulWidget {
  const ShipmentTicket({super.key, required this.shipment, required this.service, this.sales});

  final Shipment shipment;
  final ShipmentsService service;

  /// Where the sale is read; the deployment's when null (tests pass one).
  final SalesSource? sales;

  @override
  State<ShipmentTicket> createState() => _ShipmentTicketState();
}

class _ShipmentTicketState extends State<ShipmentTicket> {
  late final _detail = SaleDetailService(source: widget.sales);

  /// Lines drawn on the stub; the rest are counted and live behind the link.
  static const int _preview = 4;

  bool _triedChat = false;

  @override
  void initState() {
    super.initState();

    _detail.addListener(_fallback);

    // The read notifies its service, which must not happen while mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detail.load(widget.shipment.id);
    });
  }

  @override
  void dispose() {
    _detail.removeListener(_fallback);
    _detail.dispose();
    super.dispose();
  }

  void _fallback() {
    final chat = widget.shipment.chat;
    if (!_detail.missing || _triedChat || chat == null || chat.isEmpty) return;

    _triedChat = true;
    _detail.load(chat);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSize.spaceXS),
    child: Surface.over(
      padding: EdgeInsets.all(AppSize.spaceS),
      child: ListenableBuilder(
        listenable: _detail,
        builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ShipmentHeading(shipment: widget.shipment, service: widget.service),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
            child: const _Tear()
          ),
          _order(context),
          SizedBox(height: AppSize.spaceS),
          _Due(
            shipment: widget.shipment,
            total: _detail.status == SaleDetailStatus.ready ? _detail.sale.total : null
          )
        ])
      )
    )
  );

  Widget _order(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return switch (_detail.status) {
      SaleDetailStatus.ready => _lines(context, _detail.sale),
      SaleDetailStatus.missing => TextSmall(s.shipment_ticket_missing, lines: 3, color: scheme.text.secondary),
      SaleDetailStatus.error => Row(children: [
        Expanded(child: TextSmall(s.shipment_ticket_error, lines: 2, color: scheme.text.secondary)),
        SizedBox(width: AppSize.gap),
        _Link(label: s.shipment_ticket_retry, action: _detail.retry)
      ]),
      _ => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
        child: const Center(child: Loading())
      )
    };
  }

  Widget _lines(BuildContext context, SaleDetailModel sale) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final shown = sale.items.take(_preview).toList();
    final rest = sale.items.length - shown.length;

    if (shown.isEmpty) return TextSmall(s.shipment_ticket_empty, lines: 2, color: scheme.text.secondary);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final item in shown) _TicketLine(item: item),
      // What is not drawn is counted where the lines end, and the whole ticket
      // is a quiet link beside it: the stub is read, not operated.
      Row(children: [
        SizedBox(width: _TicketLine.qtyWidth),
        Expanded(child: rest > 0
          ? TextSmall(s.shipment_ticket_more(rest), color: scheme.text.secondary)
          : const SizedBox.shrink()),
        _Link(icon: CI.receipt, label: s.shipment_ticket_open, action: () => showSaleItems(context, sale: sale))
      ])
    ]);
  }
}

/// **What the door is owed**: the stub's foot, a band tinted by whether money
/// changes hands on arrival. It is said once for the whole panel (the state
/// tag says where the order stands, this says what to collect), with the
/// delivery fee and the cash to change under it, and the total set in the
/// stub's printed face beside its label.
class _Due extends StatelessWidget {
  const _Due({required this.shipment, this.total});

  final Shipment shipment;

  /// The sale's own total once read; the row's until then.
  final double? total;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final collect = !shipment.charged;
    final warning = scheme.chart.warning;
    final amount = total ?? shipment.total;
    final fee = shipment.fee;
    final method = shipment.collect?.method ?? "";
    final notes = [
      if (fee != null && fee > 0) s.shipment_ticket_fee(deliveryAmount(fee, shipment.currency)),
      if (collect && shipment.tender != null) shipmentTenderLabel(context, shipment.tender!)
      else if (collect && method.isNotEmpty) method
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
      decoration: BoxDecoration(
        color: collect ? warning.withValues(alpha: 0.1) : scheme.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.spaceS))
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(collect ? CI.wallet : CI.check, size: AppSize.text, color: collect ? warning : scheme.text.secondary),
            SizedBox(width: AppSize.gap),
            Flexible(child: TextSmall(
              collect ? s.shipment_ticket_collect : s.shipment_ticket_paid,
              bold: true,
              ellipsis: true,
              color: collect ? warning : null
            ))
          ]),
          for (final note in notes) Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.5, left: AppSize.text + AppSize.gap),
            child: TextSmall(note, ellipsis: true, color: scheme.text.secondary)
          )
        ])),
        SizedBox(width: AppSize.spaceS),
        TextMedium(
          amount == null ? s.shipment_none : saleAmountLabel(amount, shipment.currency),
          font: TextFont.bebas,
          multiplier: 2.1,
          color: collect ? warning : null
        )
      ])
    );
  }
}

/// A text action that does not compete with the panel's buttons: icon and
/// label in the brand colour, filled only while pointed at.
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.action, this.icon});

  final String label;
  final void Function() action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: label,
      height: AppSize.text * 2,
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.text, color: scheme.primary),
          SizedBox(width: AppSize.gap * 0.5)
        ],
        TextSmall(label, bold: true, color: scheme.primary)
      ])
    );
  }
}

/// One line as a kitchen ticket prints it: how many, what, and for how much,
/// with what was added or left out underneath. The currency is the total's:
/// repeated on every line it is read before the figure.
class _TicketLine extends StatelessWidget {
  const _TicketLine({required this.item});

  final SaleItemModel item;

  static double get qtyWidth => AppSize.text * 2.5;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final extras = [
      for (final pick in item.modifiers) pick.name,
      for (final name in item.omitted) s.sales_detail_item_without(name)
    ].where((part) => part.trim().isNotEmpty).join(", ");

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: qtyWidth,
          child: TextMedium("${saleCountLabel(context, item.qty)}×", bold: true, color: scheme.primary)
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextMedium(item.name.isEmpty ? s.sales_detail_item_concept : item.name, lines: 2, ellipsis: true),
          if (extras.isNotEmpty) TextSmall(extras, lines: 2, ellipsis: true, color: scheme.text.secondary)
        ])),
        if (item.total != null && item.total! > 0) ...[
          SizedBox(width: AppSize.gap),
          TextMedium(item.total!.toStringAsFixed(2), color: scheme.text.secondary)
        ]
      ])
    );
  }
}

/// The stub's tear: a dashed rule between the delivery and its ticket.
class _Tear extends StatelessWidget {
  const _Tear();

  @override
  Widget build(BuildContext context) {
    final color = ThemeColor.of(context).line;
    final dash = AppSize.gap * 0.75;

    return LayoutBuilder(builder: (context, box) {
      final count = (box.maxWidth / (dash * 2)).floor();

      return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < count; i++) Container(width: dash, height: 1.5, color: color)
      ]);
    });
  }
}
