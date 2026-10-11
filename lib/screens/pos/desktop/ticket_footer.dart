import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:core/button.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_methods_service.dart';
import 'package:app/services/pos/pos_service.dart';

// WIDGETS
import 'package:app/screens/modals/pos/pos_amount/_pos_amount.dart';
import 'package:app/screens/modals/pos/pos_checkout/_pos_checkout.dart';
import 'package:app/screens/modals/pos/pos_tax/_pos_tax.dart';

import './pos_currency.dart';

/// The foot of the ticket: what else can go on it, what it adds up to, and the
/// way it ends.
///
/// The order is the order of the decisions. First **anything the catalog cannot
/// charge for** — a delivery, a repair, something not imported yet — because
/// that is still building the ticket. Then the figures, ending in the total,
/// which is the number said out loud. Then completing the sale, which takes the
/// whole row: it is the only thing left to decide down here. Throwing the ticket
/// away is not a third option beside it — it lives beside the ticket number
/// ([PosTicketHeader]), away from the hand that is reaching for the total.
///
/// **The rate is a control, not a label.** Nothing in the data says what this
/// company charges (see [PosInvoiceService]), so the VAT row is tappable and the
/// modal behind it is the only place the percentage is set.
class PosTicketFooter extends StatelessWidget {
  const PosTicketFooter({
    super.key,
    required this.cart,
    required this.currency
  });

  final PosInvoiceService cart;
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // Charging waits for the ticket to settle: while a line is still travelling
    // the totals on screen are one tap ahead of the invoice, and the backend
    // would charge what it has rather than what is being read out.
    final charged = !cart.isEmpty && !cart.isBusy && !cart.isClosing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AddAmount(action: () => _addAmount(context)),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
        ),
        _Amount(
          label: S.of(context).pos_ticket_tax(_percentage(cart.taxRate)),
          value: posAmount(currency, cart.tax),
          message: S.of(context).pos_ticket_tax_edit,
          action: () => _editTax(context)
        ),
        SizedBox(height: AppSize.gap),
        _Amount(
          label: S.of(context).pos_ticket_subtotal,
          value: posAmount(currency, cart.subtotal)
        ),
        SizedBox(height: AppSize.gap),
        _Amount(
          label: S.of(context).pos_ticket_total,
          value: posAmount(currency, cart.total),
          strong: true
        ),
        SizedBox(height: AppSize.spaceXS),
        // Completing the sale takes the whole row: it is the only thing left to
        // decide down here, and throwing the ticket away moved up beside its
        // number (see [PosTicketHeader]).
        Opacity(
          opacity: charged ? 1 : 0.35,
          child: IgnorePointer(
            ignoring: !charged,
            child: MainButton(
              title: S.of(context).pos_ticket_checkout,
              // While it is being charged the button says so where its icon
              // was: the row keeps its size and nothing else on the panel
              // moves under the hand that just pressed it.
              leftIcon: cart.isClosing
                ? Loading(color: scheme.button.text)
                : Icon(CI.shopping_check, color: scheme.button.text),
              action: () => _checkout(context)
            )
          )
        )
      ]
    );
  }

  /// A rate as it is read: `16`, not `16.0`. Halves exist and keep their
  /// decimal; whole percentages —which is almost all of them— lose the zero
  /// nobody says out loud.
  String _percentage(double rate) => rate == rate.roundToDouble()
    ? rate.toStringAsFixed(0)
    : "$rate";

  /// Puts a charge on the ticket that points at no product.
  ///
  /// It goes on the invoice like any other line and is charged with it —the
  /// backend takes a line with a name and a price instead of a product— and it
  /// **holds nothing**: there is no shelf to take a delivery off. Who typed it
  /// in travels on the document, so it can be audited afterwards.
  Future<void> _addAmount(BuildContext context) async {
    final entry = await showModal(
      context: context,
      title: S.of(context).pos_amount_title,
      builder: (context) => PosAmountModal(currency: currency)
    );

    // Dismissed, or closed some other way. `showModal` answers `dynamic`, so the
    // type is what says the modal finished rather than a flag it had to set.
    if (entry is! PosAmountEntry || !context.mounted) return;

    if (await cart.addAmount(label: entry.label, price: entry.price)) return;
    if (!context.mounted) return;

    _report(context);
  }

  /// Changes the rate charged on this ticket, which **rewrites the lines that
  /// are already on it**: the backend freezes a line's tax when it is created,
  /// so that a ticket charges what was quoted while the customer was standing
  /// there.
  Future<void> _editTax(BuildContext context) async {
    final rate = await showModal(
      context: context,
      title: S.of(context).pos_tax_title,
      builder: (context) => PosTaxModal(rate: cart.taxRate)
    );

    if (rate is! double || !context.mounted) return;

    await cart.setTax(rate);

    if (!context.mounted) return;

    _report(context);
  }

  /// **Charges the ticket**: the held units become sold, the shelf is debited
  /// through the inventory ledger and the document is sealed with the code it
  /// has carried since it opened.
  ///
  /// Nothing about the money is sent — the backend prices the invoice from its
  /// own lines and refuses to take a total from the client — so what this
  /// decides is only how it was paid.
  Future<void> _checkout(BuildContext context) async {
    final methods = context.read<PosMethodsService>();

    // Without the vocabulary there is nothing to charge with: the backend
    // validates `METHOD` against it and never defaults, so guessing at a code
    // here is a sale recorded as something it was not.
    if (methods.methods.isEmpty) {
      FloatFlag.of(context).error(
        message: S.of(context).pos_checkout_methods_error
      );

      unawaited(methods.retry());

      return;
    }

    final entry = await showModal(
      context: context,
      title: S.of(context).pos_checkout_title,
      builder: (context) => PosCheckoutModal(
        methods: methods.methods,
        currency: currency,
        total: cart.total
      )
    );

    if (entry is! PosCheckoutEntry || !context.mounted) return;

    final sale = await cart.checkout(
      method: entry.method,
      reference: entry.reference
    );

    if (!context.mounted) return;

    if (sale == null) {
      _report(context);

      return;
    }

    // The day's count is one sale further along, and the card at the bottom
    // left is what shows it. It is re-read rather than incremented here: it is
    // the backend's figure and it counts more than this till's tickets.
    unawaited(context.read<PosService>().retry());

    FloatFlag.of(context).message(sale.number.isEmpty
      ? S.of(context).pos_checkout_done(sale.ticket)
      : S.of(context).pos_checkout_done_number(sale.number, sale.ticket));
  }

  /// Announces whatever the last write left behind, if it left anything.
  ///
  /// The service has already put the ticket back to what the backend holds, so
  /// what is left is saying why — almost always the shelf not covering what was
  /// asked for, or somebody else having charged this ticket first.
  void _report(BuildContext context) {
    final error = cart.error;

    if (error == null) return;

    FloatFlag.of(context).fromError(error);
  }
}

/// The button that opens the typed-in charge.
///
/// It is a full-width outlined row and not one of the package buttons because it
/// is not an action of the same weight as the two below it: it adds a line, the
/// way tapping a product in the grid does, and reading like a filled button
/// would put it in competition with completing the sale.
class _AddAmount extends StatelessWidget {
  const _AddAmount({required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FocusableWidget(
      action: action,
      message: S.of(context).pos_amount_subtitle,
      child: Surface.line(
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
        borderColor: scheme.line,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CI.plus, size: AppSize.text, color: scheme.text.secondary),
            SizedBox(width: AppSize.gap),
            TextSmall(
              S.of(context).pos_ticket_add_amount,
              color: scheme.text.secondary
            )
          ]
        )
      )
    );
  }
}

/// One figure of the ticket: what it is called on the left, what it is worth on
/// the right.
///
/// With an [action] the whole row becomes the control that changes it, which is
/// how the rate is set. Without one it is a number being reported.
class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.strong = false,
    this.action,
    this.message
  });

  final String label;
  final String value;

  /// The total. It is the only line of the block read from across the counter,
  /// so it is the only one drawn heavier than the rest.
  final bool strong;

  final void Function()? action;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final row = Row(children: [
      Expanded(child: strong
        ? TextMedium(label, bold: true, ellipsis: true)
        : TextSmall(label, ellipsis: true, color: scheme.text.secondary)),
      SizedBox(width: AppSize.gap),
      Flexible(child: strong
        // Bigger than the rest of the block but not [TextLarge]: at its x2 the
        // total of a four-figure sale no longer fits the panel, and a total
        // that ellipsises is worse than a small one.
        ? TextMedium(
            value,
            bold: true,
            multiplier: 1.25,
            ellipsis: true,
            textAlign: TextAlign.right
          )
        : TextSmall(value, ellipsis: true, textAlign: TextAlign.right))
    ]);

    if (action == null) return row;

    return FocusableWidget(action: action, message: message, child: row);
  }
}
