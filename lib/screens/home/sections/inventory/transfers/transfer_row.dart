import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart' show DateFormat;

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/services/stock/transfers/stock_transfers_service.dart';

/// One transfer: the other branch, its products, its units, where it stands, and what this
/// branch can do with it — the sender sends or drops a draft and calls a sent one back, the
/// receiver receives it. A step that is the other branch's has no button here.
class TransferRow extends StatelessWidget {
  const TransferRow({
    super.key,
    required this.transfer,
    required this.service,
    required this.onReceive,
    required this.onSend,
    required this.onCancel
  });

  final StockTransfer transfer;
  final StockTransfersService service;
  final void Function() onReceive;
  final void Function() onSend;
  final void Function() onCancel;

  /// How many products the row names before "and N more".
  static const int _named = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final branches = BranchService();
    final outgoing = transfer.sentBy(service.branch);
    final other = branches.nameOf(outgoing ? transfer.to : transfer.from);
    final busy = service.busy == transfer.id;
    final at = transfer.movedAt;

    final names = [
      for (final line in transfer.lines.take(_named))
        "${line.quantity} × ${_product(line)}"
    ].join(" · ");
    final rest = transfer.lines.length - _named;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: TextMedium(
                outgoing
                  ? s.inventory_transfers_to(other.isEmpty ? s.finance_method_branch_other : other)
                  : s.inventory_transfers_from(other.isEmpty ? s.finance_method_branch_other : other),
                bold: true,
                ellipsis: true
              )),
              SizedBox(width: AppSize.gap),
              _StatusTag(status: transfer.status),
              if (!transfer.settled) ...[
                SizedBox(width: AppSize.gap),
                TextSmall(s.inventory_transfers_unsettled, color: scheme.chart.warning)
              ]
            ]),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              rest > 0 ? "$names ${s.inventory_transfers_more(rest)}" : names,
              lines: 2,
              ellipsis: true,
              color: scheme.text.secondary
            ),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              [
                transfer.received == null
                  ? s.inventory_transfers_units(transfer.units)
                  : s.inventory_transfers_units_received(transfer.received!, transfer.units),
                if (at != null) DateFormat.MMMd(Localizations.localeOf(context).toString()).add_Hm().format(at),
                if (transfer.note.isNotEmpty) transfer.note
              ].join(" · "),
              ellipsis: true,
              color: scheme.text.secondary
            )
          ])),
          ..._actions(context, outgoing, busy)
        ])
      )
    );
  }

  String _product(StockTransferLine line) {
    final name = service.nameOf(line.productId);
    if (name.isNotEmpty) return name;

    return line.sku.isNotEmpty ? line.sku : line.productId;
  }

  List<Widget> _actions(BuildContext context, bool outgoing, bool busy) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    Widget button(String label, void Function() action, {Color? color}) => Padding(
      padding: EdgeInsets.only(left: AppSize.gap),
      child: FeedbackButton(
        action: busy || service.busy != null ? null : action,
        height: AppSize.button,
        color: scheme.surfaceOver,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
        message: label,
        child: Center(child: busy
          ? SizedBox(width: AppSize.text, height: AppSize.text, child: const Loading())
          : TextSmall(label, color: color ?? scheme.text.primary))
      )
    );

    return switch (transfer.status) {
      StockTransferStatus.draft when outgoing && service.canSend => [
        button(s.inventory_transfers_drop, onCancel, color: scheme.text.secondary),
        button(s.inventory_transfers_send, onSend, color: scheme.primary)
      ],
      StockTransferStatus.sent when outgoing && service.canSend => [
        button(s.inventory_transfers_call_back, onCancel, color: scheme.text.secondary)
      ],
      StockTransferStatus.sent when !outgoing && service.canReceive => [
        button(s.inventory_transfers_receive, onReceive, color: scheme.primary)
      ],
      _ => const []
    };
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final StockTransferStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    final (label, color) = switch (status) {
      StockTransferStatus.draft => (s.inventory_transfers_status_draft, scheme.text.secondary),
      StockTransferStatus.sent => (s.inventory_transfers_status_sent, scheme.chart.warning),
      StockTransferStatus.received => (s.inventory_transfers_status_received, scheme.snackBar.success),
      StockTransferStatus.cancelled => (s.inventory_transfers_status_cancelled, scheme.text.secondary)
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap, vertical: AppSize.gap * 0.3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSize.gap)
      ),
      child: TextSmall(label, color: color, multiplier: 0.8)
    );
  }
}
