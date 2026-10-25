import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_detail_service.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/sales/sale_items/_sale_items.dart';

import './shipment_facts.dart';

/// **The delivery and the ticket it carries**, as one stub: whose order it is
/// and where it stands above the tear, what goes in the bag below it, and
/// "View ticket" opening every line (`showSaleItems`, stacked on the panel).
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

  /// Lines drawn on the stub; the rest are counted and live behind the button.
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ShipmentHeading(shipment: widget.shipment, service: widget.service),
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
          child: const _Tear()
        ),
        ListenableBuilder(listenable: _detail, builder: (context, _) => _order(context))
      ])
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
        Button(width: null, title: s.shipment_ticket_retry, action: _detail.retry)
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
    final shipment = widget.shipment;
    final shown = sale.items.take(_preview).toList();
    final rest = sale.items.length - shown.length;
    final total = sale.total ?? shipment.total;
    final currency = sale.currency.isNotEmpty ? sale.currency : shipment.currency;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (shown.isEmpty)
        TextSmall(s.shipment_ticket_empty, lines: 2, color: scheme.text.secondary)
      else
        for (final item in shown) _TicketLine(item: item, currency: currency),
      if (rest > 0) Padding(
        padding: EdgeInsets.only(left: AppSize.text * 2.25),
        child: TextSmall(s.shipment_ticket_more(rest), color: scheme.text.secondary)
      ),
      if (total != null) ...[
        SizedBox(height: AppSize.spaceS),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextSmall(
            shipment.charged ? s.shipment_ticket_paid : s.shipment_ticket_collect,
            color: shipment.charged ? scheme.text.secondary : scheme.chart.warning,
            ellipsis: true
          )),
          SizedBox(width: AppSize.gap),
          TextLarge(
            saleAmountLabel(total, currency),
            color: shipment.charged ? null : scheme.chart.warning
          )
        ])
      ],
      if (sale.items.isNotEmpty) ...[
        SizedBox(height: AppSize.spaceS),
        Button(
          title: s.shipment_ticket_open,
          leftIcon: Icon(CI.receipt, size: AppSize.text, color: scheme.button.text),
          action: () => showSaleItems(context, sale: sale)
        )
      ]
    ]);
  }
}

/// One line as a kitchen ticket prints it: how many, what, and for how much,
/// with what was added or left out underneath.
class _TicketLine extends StatelessWidget {
  const _TicketLine({required this.item, required this.currency});

  final SaleItemModel item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final extras = [
      for (final pick in item.modifiers) pick.name,
      for (final name in item.omitted) s.sales_detail_item_without(name)
    ].where((part) => part.trim().isNotEmpty).join(" · ");

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap * 0.75),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: AppSize.text * 2.25,
          child: TextMedium("${saleCountLabel(context, item.qty)}×", bold: true, color: scheme.primary)
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextMedium(item.name.isEmpty ? s.sales_detail_item_concept : item.name, lines: 2, ellipsis: true),
          if (extras.isNotEmpty) TextSmall(extras, lines: 2, ellipsis: true, color: scheme.text.secondary)
        ])),
        if (item.total != null) ...[
          SizedBox(width: AppSize.gap),
          TextSmall(saleAmountLabel(item.total, currency), color: scheme.text.secondary)
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
