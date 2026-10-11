import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/services/stock/transfers/stock_transfers_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/badges/badge_notes.dart';
import 'package:app/screens/home/sections/_section/filter_chip.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/modals/inventory/receive_transfer/_receive_transfer.dart';
import 'package:app/screens/modals/inventory/transfer_form/_transfer_form.dart';
import 'package:app/services/badges/badge_place.dart';

import './transfer_row.dart';

/// Stock moving between the company's branches (`sedes-frontend.md` §6), from the branch worked
/// in: what is coming here (opens on what is on its way, which is what the receiver acts on)
/// and what was sent from here. A sub-page of inventory (`/home/inventory/transfers`).
///
/// Cloud only (`inventory.transfers`): a master is one site. The buttons follow the person's
/// own grant in this branch (`inventory.transfer`, `inventory.receive`).
class StockTransfersSection extends StatefulWidget {
  const StockTransfersSection({super.key, this.service});

  static const String routeKey = "inventory_transfers";
  static const String path = "/home/inventory/transfers";

  /// Test seam; created here otherwise.
  final StockTransfersService? service;

  @override
  State<StockTransfersSection> createState() => _StockTransfersSectionState();
}

class _StockTransfersSectionState extends State<StockTransfersSection> {
  late final _service = widget.service ?? StockTransfersService();

  @override
  void initState() {
    super.initState();
    if (widget.service == null) Future.microtask(_service.load);
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _service,
    child: Consumer<StockTransfersService>(builder: (context, service, _) => Surface(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header(context, service),
        Separator.horizontal(margin: EdgeInsets.symmetric(vertical: AppSize.padding)),
        BadgeNotes(place: BadgePlace.inventoryTransfers, padding: EdgeInsets.only(bottom: AppSize.spaceS)),
        _filters(context, service),
        SizedBox(height: AppSize.spaceS),
        Expanded(child: _body(context, service))
      ])
    ))
  );

  Widget _header(BuildContext context, StockTransfersService service) => Row(children: [
    FeedbackButton(
      action: () => Navis.push(context, HomeSection.inventory.path),
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).inventory,
      child: Center(child: Icon(CI.arrow_left, color: ThemeColor.of(context).text.primary))
    ),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      TextMedium(S.of(context).inventory_transfers_title, bold: true, ellipsis: true),
      TextSmall(
        S.of(context).inventory_transfers_branch(BranchService().active?.name ?? ""),
        ellipsis: true,
        color: ThemeColor.of(context).text.secondary
      )
    ])),
    if (service.canSend && service.destinations.isNotEmpty)
      FeedbackButton(
        action: () => _create(context, service),
        height: AppSize.button,
        color: ThemeColor.of(context).surfaceOver,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
        message: S.of(context).inventory_transfers_new,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CI.plus, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon),
          SizedBox(width: AppSize.gap),
          TextMedium(S.of(context).inventory_transfers_new)
        ])
      )
  ]);

  Widget _filters(BuildContext context, StockTransfersService service) {
    final s = S.of(context);
    final incoming = service.side == StockTransferSide.incoming;
    String label(StockTransferStatus? status) => switch (status) {
      null => s.inventory_transfers_status_all,
      StockTransferStatus.draft => s.inventory_transfers_status_draft,
      StockTransferStatus.sent => s.inventory_transfers_status_sent,
      StockTransferStatus.received => s.inventory_transfers_status_received,
      StockTransferStatus.cancelled => s.inventory_transfers_status_cancelled
    };
    // A draft is only the sender's to see.
    final statuses = [
      null,
      for (final status in StockTransferStatus.values)
        if (!incoming || status != StockTransferStatus.draft) status
    ];

    return Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
      SectionFilterChip(
        icon: CI.arrow_down,
        title: s.inventory_transfers_incoming,
        isActive: incoming,
        action: () => service.show(StockTransferSide.incoming, StockTransferStatus.sent)
      ),
      SectionFilterChip(
        icon: CI.arrow_top,
        title: s.inventory_transfers_outgoing,
        isActive: !incoming,
        action: () => service.show(StockTransferSide.outgoing, null)
      ),
      SectionMenuChip(
        title: label(service.filter),
        isActive: service.filter != null,
        selected: service.filter?.name ?? "",
        emptyText: s.business_delivery_select_empty,
        options: [
          for (final status in statuses)
            SelectOption(value: status?.name ?? "", placeholder: label(status))
        ],
        onSelected: (value) => service.show(service.side, StockTransferStatus.from(value))
      )
    ]);
  }

  Widget _body(BuildContext context, StockTransfersService service) {
    final s = S.of(context);

    return switch (service.status) {
      StockTransfersStatus.error => SectionMessage(
        icon: CI.warehouse,
        title: s.inventory_transfers_error,
        action: () => unawaited(service.load()),
        actionLabel: s.permission_retry
      ),
      StockTransfersStatus.empty => SectionMessage(
        icon: CI.warehouse,
        title: service.side == StockTransferSide.incoming
          ? s.inventory_transfers_empty_incoming
          : s.inventory_transfers_empty_outgoing
      ),
      StockTransfersStatus.ready => ListView(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        children: [
          for (final transfer in service.transfers) TransferRow(
            transfer: transfer,
            service: service,
            onReceive: () => _receive(context, service, transfer),
            onSend: () => _act(context, () => service.send(transfer)),
            onCancel: () => _cancel(context, service, transfer)
          ),
          if (service.hasMore) SectionMoreButton(
            label: s.sales_more,
            retryLabel: s.permission_retry,
            failed: false,
            onMore: () => unawaited(service.more()),
            onRetry: () => unawaited(service.more())
          )
        ]
      ),
      _ => const Center(child: Loading())
    };
  }

  Future<void> _create(BuildContext context, StockTransfersService service) async {
    final request = await showTransferForm(context, service: service);
    if (request == null || !context.mounted) return;

    try {
      await service.create(request);
      if (context.mounted) {
        FloatFlag.of(context).message(request["SEND"] == true
          ? S.of(context).inventory_transfers_sent
          : S.of(context).inventory_transfers_drafted);
      }
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  Future<void> _receive(BuildContext context, StockTransfersService service, StockTransfer transfer) async {
    final counted = await showReceiveTransfer(context, transfer: transfer, nameOf: service.nameOf);
    if (counted == null || !context.mounted) return;

    await _act(context, () => service.receive(transfer, counted), done: S.of(context).inventory_transfers_received);
  }

  Future<void> _cancel(BuildContext context, StockTransfersService service, StockTransfer transfer) async {
    final s = S.of(context);
    final sent = transfer.status == StockTransferStatus.sent;

    final confirmed = await showAlertModal(
      context: context,
      title: sent ? s.inventory_transfers_call_back_title : s.inventory_transfers_drop_title,
      message: sent ? s.inventory_transfers_call_back_message : s.inventory_transfers_drop_message,
      confirmText: sent ? s.inventory_transfers_call_back : s.inventory_transfers_drop,
      cancelText: s.cancel
    );
    if (!confirmed || !context.mounted) return;

    await _act(context, () => service.cancel(transfer));
  }

  Future<void> _act(BuildContext context, Future<void> Function() call, {String? done}) async {
    try {
      await call();
      if (done != null && context.mounted) FloatFlag.of(context).message(done);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }
}
