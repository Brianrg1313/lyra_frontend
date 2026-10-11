import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// What the receiving branch counted, per product: only the lines that arrived short.
typedef TransferCount = Map<String, ({int received, StockShortage reason})>;

/// Opens the count of a shipment coming to the branch worked in. Returns what arrived short
/// (a line left as sent arrived whole), or null when closed without receiving.
Future<TransferCount?> showReceiveTransfer(
  BuildContext context, {
  required StockTransfer transfer,
  required String Function(String productId) nameOf
}) => showSideModal(
  context: context,
  title: S.of(context).inventory_transfers_receive_title,
  builder: (context) => ReceiveTransferModal(transfer: transfer, nameOf: nameOf)
).then((value) => value is TransferCount ? value : null);

/// Each line opens on what was sent. What arrived joins this branch's shelf; the rest is
/// written off as the reason picked (`loss` unless said otherwise), one line each.
class ReceiveTransferModal extends StatefulWidget {
  const ReceiveTransferModal({super.key, required this.transfer, required this.nameOf});

  final StockTransfer transfer;
  final String Function(String productId) nameOf;

  @override
  State<ReceiveTransferModal> createState() => _ReceiveTransferModalState();
}

class _ReceiveTransferModalState extends State<ReceiveTransferModal> {
  static const double _width = 420;

  late final Map<String, InputController> _counts = {
    for (final line in widget.transfer.lines)
      line.productId: InputController(key: "RECEIVED_${line.productId}", type: InputType.numeric, max: 6, initial: "${line.quantity}")
  };

  late final Map<String, InputController> _reasons = {
    for (final line in widget.transfer.lines)
      line.productId: InputController.select(key: "REASON_${line.productId}", initial: StockShortage.loss.name)
  };

  @override
  void initState() {
    super.initState();
    for (final count in _counts.values) {
      count.textController.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [..._counts.values, ..._reasons.values]) {
      controller.form.dispose();
    }
    super.dispose();
  }

  int? _received(StockTransferLine line) => int.tryParse(_counts[line.productId]!.value.trim());

  void _submit() {
    final counted = <String, ({int received, StockShortage reason})>{};

    for (final line in widget.transfer.lines) {
      final received = _received(line);

      if (received == null || received < 0 || received > line.quantity) {
        FloatFlag.of(context).error(message: S.of(context).inventory_transfers_count_invalid(line.quantity));
        return;
      }

      if (received < line.quantity) {
        counted[line.productId] = (
          received: received,
          reason: StockShortage.from(_reasons[line.productId]!.value) ?? StockShortage.loss
        );
      }
    }

    Navigator.pop(context, counted);
  }

  String _reason(BuildContext context, StockShortage reason) => switch (reason) {
    StockShortage.damage => S.of(context).inventory_transfers_reason_damage,
    StockShortage.loss => S.of(context).inventory_transfers_reason_loss,
    StockShortage.theft => S.of(context).inventory_transfers_reason_theft
  };

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final transfer = widget.transfer;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              s.inventory_transfers_receive_subtitle(BranchService().nameOf(transfer.from)),
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          for (final line in transfer.lines) ...[
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                TextSmall(
                  widget.nameOf(line.productId).isNotEmpty
                    ? widget.nameOf(line.productId)
                    : line.sku.isNotEmpty ? line.sku : line.productId,
                  ellipsis: true
                ),
                TextSmall(s.inventory_transfers_line_sent(line.quantity), color: scheme.text.secondary, multiplier: 0.8)
              ])),
              SizedBox(width: AppSize.gap),
              SizedBox(width: AppSize.action * 2, child: Input(controller: _counts[line.productId]!, placeholder: "0"))
            ]),
            if ((_received(line) ?? line.quantity) < line.quantity) SelectInput(
              title: s.inventory_transfers_reason,
              placeholder: _reason(context, StockShortage.loss),
              controller: _reasons[line.productId]!,
              searchable: false,
              emptyText: s.business_delivery_select_empty,
              options: [
                for (final reason in StockShortage.values)
                  SelectOption(value: reason.name, placeholder: _reason(context, reason))
              ]
            ),
            SizedBox(height: AppSize.gap)
          ],
          SizedBox(height: AppSize.spaceM),
          Button(title: s.inventory_transfers_receive, action: _submit)
        ]
      )
    );
  }
}
