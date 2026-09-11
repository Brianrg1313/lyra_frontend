import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/pos/pos_cart_line.dart';
import 'package:app/services/pos/pos_invoice_service.dart';

// WIDGETS
import './pos_currency.dart';

/// One line of the ticket, in two rows.
///
/// It is not one row because the panel is 300-odd pixels wide and the line has
/// four things to say: what it is, what it costs, how many, and what those add
/// up to. Squeezed into a single row on a hi-dpi screen —where `AppSize` scales
/// and the panel does not— the name is the one that loses, and the name is what
/// the line is looked up by.
///
/// So the top row is **what it is and what it comes to**, which is what is read
/// when checking a ticket against the counter, and the bottom one is the
/// controls: the two buttons and the unit price they are moving.
///
/// **Every step travels**: a unit more holds a unit more in the ledger and a
/// unit less gives it back, so the buttons write to the invoice and not to a
/// list in memory. They are still drawn immediately —a counter cannot wait for
/// a round trip to show a tap— and the answer corrects them when it lands (see
/// [PosInvoiceService]). What fails is announced by the service and the line
/// goes back to what the backend has.
///
/// A line also says when it is **no longer held**: the units are still being
/// charged, but the shelf gave them back to somebody else's screen and this one
/// is the only place that can show it before the customer is at the card reader.
class PosTicketLine extends StatelessWidget {
  const PosTicketLine({
    super.key,
    required this.line,
    required this.cart,
    required this.currency
  });

  final PosCartLine line;

  /// The ticket the buttons write to. It is handed down instead of read here so
  /// the whole list does not subscribe to it once per line.
  final PosInvoiceService cart;

  final CurrencyModel currency;

  /// Whether the line can be moved yet.
  ///
  /// A product always can —it is addressed by its product, so "one more of
  /// this" is answerable before the line's own id exists— and a typed-in charge
  /// only once the backend has given it one: it has nothing else to be pointed
  /// at, and a step that could not travel would be a number moving on screen
  /// over an invoice that never heard about it.
  bool get _editable => !line.isConcept || !line.isPending;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              flex: 3,
              child: TextSmall(
                // A product with neither name nor code says so, the same way
                // its tile in the catalog does.
                line.label.isEmpty
                  ? S.of(context).pos_product_unnamed
                  : line.label,
                ellipsis: true,
                color: line.label.isEmpty
                  ? scheme.text.secondary
                  : scheme.text.primary
              )
            ),
            SizedBox(width: AppSize.gap),
            Expanded(
              flex: 2,
              child: TextMedium(
                posAmount(currency, line.total),
                bold: true,
                ellipsis: true,
                textAlign: TextAlign.right
              )
            )
          ]),
          // Only when the shelf stopped holding what this line is charging.
          // It is written under the name and not beside the quantity because
          // it is about the product and not about the number: the units are on
          // the ticket, they are simply not set aside any more.
          if (!line.isHeld) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              S.of(context).pos_ticket_unheld,
              ellipsis: true,
              multiplier: 0.85,
              color: scheme.snackBar.error
            )
          ],
          SizedBox(height: AppSize.gap),
          Row(children: [
            _Step(
              sign: "−",
              message: S.of(context).pos_ticket_less,
              // At one unit this takes the line off the ticket, which is how a
              // product is un-rung at a counter (see
              // [PosInvoiceService.decrease]) and what gives its units back to
              // the shelf. That is why it is never disabled for a product:
              // there is always something for it to do.
              action: _editable
                ? () => _move(context, cart.decrease(line.key))
                : null
            ),
            SizedBox(
              width: AppSize.action,
              child: TextMedium(
                "${line.quantity}",
                bold: true,
                textAlign: TextAlign.center
              )
            ),
            _Step(
              sign: "+",
              message: S.of(context).pos_ticket_more,
              action: !_editable || line.quantity >= PosInvoiceService.maxQuantity
                ? null
                : () => _move(context, cart.increase(line.key))
            ),
            Expanded(child: TextSmall(
              S.of(context).pos_ticket_each(posAmount(currency, line.price)),
              ellipsis: true,
              multiplier: 0.85,
              textAlign: TextAlign.right,
              color: scheme.text.secondary
            ))
          ])
        ]
      )
    );
  }

  /// Waits for a step to land and says so if it did not.
  ///
  /// The service has already put the line back to what the backend holds — what
  /// is left to do is tell whoever pressed the button why the number went back,
  /// which is almost always the shelf not covering the unit that was asked for.
  Future<void> _move(BuildContext context, Future<bool> step) async {
    if (await step) return;
    if (!context.mounted) return;

    final error = cart.error;

    if (error != null) FloatFlag.of(context).fromError(error);
  }
}

/// One of the two buttons that move a line's quantity.
///
/// Square and the size of an action so it can be hit without looking, which is
/// the whole point of having them at a counter: the ordinary sale is one, two or
/// three units, and tapping is faster and misses less than typing.
///
/// The sign is written and not an icon for the same reason `QuantityField`
/// writes it: there is no minus in the icon font, and an icon plus beside a text
/// minus reads with two different weights.
class _Step extends StatelessWidget {
  const _Step({required this.sign, required this.action, this.message});

  final String sign;
  final String? message;

  /// Null when the step has nowhere to go. Without an action the button stops
  /// responding to tap and to the keyboard.
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final enabled = action != null;
    final radius = AppSize.cornerInset(AppSize.gap);

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: FeedbackButton(
        action: action,
        message: message,
        mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
        width: AppSize.action,
        height: AppSize.action,
        radius: radius,
        color: scheme.surfaceOver,
        feedbackColor: scheme.input.focus,
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
