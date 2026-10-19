import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/movements/stock_history_service.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart' show stockFigure;

// WIDGETS
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/inventory/table_settings/settings_format.dart';
import 'package:app/screens/pos/desktop/pos_currency.dart';

/// Opens [productId]'s movements at the branch worked in (`cocina-frontend.md` §10), from its
/// stock figure in the summary. Cloud only (`inventory.history`).
Future<void> showStockHistory(
  BuildContext context, {
  required String productId,
  required String product,
  required CurrencyModel currency
}) => showSideModal(
  context: context,
  title: S.of(context).stock_history_title,
  builder: (context) => StockHistoryModal(
    service: StockHistoryService(productId: productId),
    product: product,
    currency: currency
  )
);

/// The product's ledger, newest first: what moved and which way, why, for which dish or how
/// it was bought, who did it, when, and what was left. Reads only: a movement is never edited.
class StockHistoryModal extends StatefulWidget {
  const StockHistoryModal({super.key, required this.service, required this.product, required this.currency});

  /// Owned by the panel: disposed with it.
  final StockHistoryService service;
  final String product;
  final CurrencyModel currency;

  @override
  State<StockHistoryModal> createState() => _StockHistoryModalState();
}

class _StockHistoryModalState extends State<StockHistoryModal> {
  static const double _width = 440;

  StockHistoryService get _service => widget.service;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    Future.microtask(_service.load);
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    _service.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: switch (_service.status) {
        StockHistoryStatus.error => SectionMessage(
          icon: CI.inventory,
          title: s.stock_history_error,
          action: () => unawaited(_service.load()),
          actionLabel: s.stock_history_retry
        ),
        StockHistoryStatus.empty => SectionMessage(
          icon: CI.inventory,
          title: s.stock_history_empty,
          subtitle: s.stock_history_empty_hint
        ),
        StockHistoryStatus.ready => ScrollableWidget(
          padding: EdgeInsets.only(bottom: AppSize.padding),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.product.isNotEmpty) ...[
              TextMedium(widget.product, bold: true, ellipsis: true),
              SizedBox(height: AppSize.spaceS)
            ],
            for (final entry in _service.entries) StockLedgerLine(
              entry: entry,
              dish: entry.madeFor == null ? "" : _service.dish(entry.madeFor!.productId),
              currency: widget.currency
            ),
            if (_service.hasMore) _service.loadingMore
              ? Padding(padding: EdgeInsets.all(AppSize.spaceS), child: const Center(child: Loading()))
              : SectionMoreButton(
                  label: s.stock_history_more,
                  retryLabel: s.stock_history_retry,
                  failed: _service.moreFailed,
                  onMore: () => unawaited(_service.more()),
                  onRetry: () => unawaited(_service.more())
                )
          ]
        ),
        _ => const Center(child: Loading())
      }
    );
  }
}

/// One movement: «Used in a sale · for 2 × Classic burger» with «−0.4» beside it, then who and
/// when, and the note somebody wrote.
class StockLedgerLine extends StatelessWidget {
  const StockLedgerLine({super.key, required this.entry, required this.dish, required this.currency});

  final StockLedgerEntry entry;

  /// The name of the dish it moved for, empty when unknown or not for one.
  final String dish;
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final made = entry.madeFor;
    final pack = entry.pack;
    final unit = entry.unit;
    final cost = entry.cost;
    String named(String symbol) => symbol.isEmpty ? s.product_table_view_unit_count_symbol : symbol;

    final what = [
      stockLedgerReason(context, entry.operation, entry.reason),
      if (made != null) dish.isEmpty
        ? s.stock_history_for_unnamed(stockFigure(made.qty))
        : s.stock_history_for(stockFigure(made.qty), dish),
      if (pack != null && pack.name.isNotEmpty) s.stock_history_pack(stockFigure(pack.count), pack.name),
      if (unit != null) s.stock_history_unit(named(unit.from), named(unit.to)),
      if (cost != null) posAmount(currency, cost)
    ].join(" · ");

    final available = entry.available;
    final who = [
      entry.actorKind == "user"
        ? entry.actorName ?? s.stock_history_gone
        : entry.actorName ?? s.stock_history_automatic,
      settingsDate(context, entry.date),
      if (available != null) s.stock_history_left(stockFigure(available))
    ].where((part) => part.isNotEmpty).join(" · ");

    final figure = switch (entry.sign) {
      1 => "+${stockFigure(entry.qty)}",
      -1 => "−${stockFigure(entry.qty)}",
      _ => stockFigure(entry.qty)
    };

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceS),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextSmall(what, bold: true, lines: 2),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(who, color: scheme.text.secondary, lines: 2),
          if (entry.note.isNotEmpty) ...[
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall("«${entry.note}»", color: scheme.text.secondary, lines: 3)
          ]
        ])),
        SizedBox(width: AppSize.spaceS),
        TextMedium(
          figure,
          bold: true,
          color: entry.sign == 0 ? scheme.text.secondary : null
        )
      ])
    );
  }
}

/// How a ledger reason is named. The same code means different things in different
/// operations (`waste` of a removal is «Waste», of a batch «Lost from the batch»), so it is
/// read with its operation; one the app doesn't know yet reads as the backend's code.
String stockLedgerReason(BuildContext context, String operation, String reason) {
  final s = S.of(context);

  return switch ((operation, reason)) {
    ("add", "restock") => s.stock_reason_restock,
    ("add", "return") => s.stock_reason_return_approved,
    (_, "correction") => s.stock_reason_correction,
    ("remove", "sale") => s.stock_reason_sale,
    (_, "damage") => s.stock_reason_damage,
    (_, "loss") => s.stock_reason_loss,
    (_, "theft") => s.stock_reason_theft,
    ("remove", "expiration") => s.stock_reason_expiration,
    ("remove", "waste") => s.stock_reason_waste,
    ("remove", "discard") => s.stock_reason_discard,
    ("return", "customer") => s.stock_reason_customer,
    ("return", "defective") => s.stock_reason_defective,
    ("return", "wrong_item") => s.stock_reason_wrong_item,
    ("return", "warranty") => s.stock_reason_warranty,
    ("reserve" || "reservation", "hold") => s.stock_reason_hold,
    ("unreserve", "reintegration") => s.stock_reason_reintegration,
    ("unreserve", "expiration") => s.stock_reason_hold_expired,
    ("unreserve", "cancelled") => s.stock_reason_cancelled,
    ("reservation", "release") => s.stock_reason_release,
    ("reservation", "commit") => s.stock_reason_commit,
    ("transfer", "transfer_out") => s.stock_reason_transfer_out,
    ("transfer", "transfer_in") => s.stock_reason_transfer_in,
    ("transfer", "transfer_back") => s.stock_reason_transfer_back,
    ("recipe", "consumption") => s.stock_reason_consumption,
    ("recipe", "consumed") => s.stock_reason_consumed,
    ("recipe", "production") => s.stock_reason_production,
    ("recipe", "ingredient") => s.stock_reason_ingredient,
    ("recipe", "waste") => s.stock_reason_batch_waste,
    ("recipe", "spoiled") => s.stock_reason_spoiled,
    ("unit", "conversion") => s.stock_reason_conversion,
    _ => reason
  };
}
