import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/movements/stock_mover.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';

// WIDGETS
import 'package:app/screens/modals/inventory/stock_history/_stock_history.dart';
import 'package:app/screens/modals/inventory/stock_movement/_stock_movement.dart';

import './summary_layout.dart';
import './summary_number.dart';

/// One of the two summary numbers, with what's done with it on its sides: take
/// on the left, the figure in the middle, add on the right.
///
/// It's what turns the summary from a read into a counter. What brings someone
/// to this screen is looking at how much is left, and what they do half a
/// second later is correct it —six came in, two were sold, three have to be set
/// aside—: doing it here is touching the number being looked at, and not
/// entering the table, hunting for the row among three hundred and coming back.
///
/// Both buttons open the same form ([showStockMovement]) and write nothing on
/// their own. An inventory movement **isn't a counter**: the unit that leaves
/// stock was sold, broke or was set aside for someone, and that difference is
/// the only thing that later lets you ask how much was lost to breakage last
/// month. A `+1` that doesn't say where it came from leaves the ledger with
/// nothing to audit.
///
/// A dimmed button is a movement that can't be made today: releasing reserves
/// when there are none, setting aside units when there's no stock left. Taking
/// from stock stays on even at zero, because a return enters its own counter
/// and doesn't come off the shelf.
///
/// The stock figure itself opens what moved it (`showStockHistory`), where the ledger is read
/// back (`inventory.history`): the number someone doubts is the one they touch.
///
/// The supplies list draws it too, moving through its own service ([mover]).
class SummaryStepper extends StatelessWidget {
  const SummaryStepper({
    super.key,
    required this.productId,
    required this.counter,
    required this.stock,
    required this.reserved,
    this.product = "",
    this.currency,
    this.unit = "",
    this.mover
  });

  /// The row's record, which is the product the movement is written against.
  final String productId;

  /// Which of the two numbers this control draws.
  final StockCounter counter;

  /// The row's two numbers. Both arrive even if one is drawn: the form needs
  /// them to know how far it can move, and setting aside units is limited by
  /// stock and not by what's already reserved.
  final num stock;
  final num reserved;

  /// How the row names the product, and the company's currency: what its movements panel
  /// titles itself with and writes a purchase's cost in.
  final String product;
  final CurrencyModel? currency;

  /// What the product's stock is counted in when it is not its column's ([SummaryNumber.unit]).
  final String unit;

  /// What the movement is written through; without one, the stock summary's
  /// ([StockSummaryService]).
  final StockMover? mover;

  num get _value => counter == StockCounter.stock ? stock : reserved;

  /// If something can be taken from this counter.
  ///
  /// From stock always: even at zero, a return may be registered that just
  /// came in. From reserves only if there's some to release.
  bool get _canTake => counter == StockCounter.stock || reserved > 0;

  /// If something can be added. Reserves need stock to set aside from.
  bool get _canPut => counter == StockCounter.stock || stock > 0;

  @override
  Widget build(BuildContext context) => Row(children: [
    _Step(
      sign: "−",
      message: S.of(context).stock_move_take_hint,
      action: _canTake ? () => _open(context, StockDirection.take) : null
    ),
    Expanded(child: _figure(context)),
    _Step(
      sign: "+",
      message: S.of(context).stock_move_add_hint,
      action: _canPut ? () => _open(context, StockDirection.put) : null
    )
  ]);

  Widget _figure(BuildContext context) {
    final number = SummaryNumber(
      value: _value,
      // Only stock alerts on zero: it's what can't be sold. Zero reserved is
      // normal in almost all products.
      alert: counter == StockCounter.stock,
      align: TextAlign.center,
      unit: counter == StockCounter.stock ? unit : ""
    );

    final currency = this.currency;
    if (counter != StockCounter.stock || currency == null || !CapabilityService().shows("inventory.history")) {
      return number;
    }

    return FocusableWidget(
      action: () => showStockHistory(context, productId: productId, product: product, currency: currency),
      message: S.of(context).stock_history_open,
      child: number
    );
  }

  /// The service is read **here** and travels to the modal: inside the modal
  /// the tree is the root navigator's, which sits above where the inventory
  /// section provides it.
  void _open(BuildContext context, StockDirection direction) =>
    showStockMovement(
      context,
      service: mover ?? context.read<StockSummaryService>(),
      productId: productId,
      counter: counter,
      direction: direction,
      stock: stock,
      reserved: reserved
    );
}

/// One of the control's two buttons.
///
/// The sign is written and not drawn with an icon because there's no minus in
/// the icon set, and an icon plus next to a text minus would be read with
/// different weights. Both written, they're the same stroke.
class _Step extends StatelessWidget {
  const _Step({required this.sign, required this.message, this.action});

  final String sign;
  final String message;

  /// Null when that movement can't be made today. Without an action the button
  /// stops responding to tap and keyboard.
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final enabled = action != null;

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: FeedbackButton(
        action: action,
        message: message,
        mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
        width: SummaryLayout.stepSize,
        height: SummaryLayout.stepSize,
        radius: AppSize.gap,
        color: scheme.surface,
        child: Center(child: TextMedium(
          sign,
          bold: true,
          textAlign: TextAlign.center,
          color: scheme.text.secondary
        ))
      )
    );
  }
}
