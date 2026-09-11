import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_service.dart';

/// The head of the ticket: which one it is, how much is on it, and the way to
/// throw it away.
///
/// **The number is the ticket's own code once there is one.** The backend mints
/// it when the invoice opens —`K7M4-2QX9`, on the first product— and it never
/// changes, so it can be read out over the phone and printed on a provisional
/// slip long before anything is paid, and the ticket the customer walks out with
/// is the one the cashier was looking at all along.
///
/// Before that there is no ticket yet, so what is drawn is the day's running
/// count: the sales this person has completed today plus the one about to
/// start. It is the number they would say out loud, and it is replaced by the
/// real code the moment the first product lands.
///
/// **Discarding lives up here, beside the number.** It is what the head of a
/// ticket is about — which one this is, and getting rid of it — and it keeps the
/// destructive action away from the foot, where the hand already is for
/// completing the sale.
class PosTicketHeader extends StatelessWidget {
  const PosTicketHeader({super.key, required this.cart});

  /// The ticket. The head reads how much is on it and cancels it; it is handed
  /// down rather than watched here because the panel above already watches it.
  final PosInvoiceService cart;

  /// What is written where the ticket number goes while the day's summary is
  /// still on its way and nothing has been rung up.
  static const String _unknown = "—";

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final summary = context.watch<PosService>();
    final ticket = cart.ticket;

    final number = ticket.isNotEmpty
      ? ticket
      : summary.status == PosSummaryStatus.ready
        ? "${summary.mineSales + 1}"
        : _unknown;

    return Row(children: [
      Surface.over(
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Icon(CI.receipt, size: AppSize.text * 1.2, color: scheme.icon)
      ),
      SizedBox(width: AppSize.gap),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(
            // The real code is the ticket's name and is written as it is; the
            // running count is a number and reads as one.
            ticket.isNotEmpty
              ? ticket
              : S.of(context).pos_ticket_number(number),
            bold: true,
            ellipsis: true
          ),
          TextSmall(
            S.of(context).pos_ticket_units(cart.units),
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      )),
      SizedBox(width: AppSize.gap),
      _Discard(enabled: !cart.isEmpty, action: () => _clear(context))
    ]);
  }

  /// Throws the ticket away, after asking.
  ///
  /// **It is the call that has to be made when a sale does not happen**: until
  /// it is, every product on this invoice is held and no other till is offered
  /// it. The document is kept and closed as cancelled — a cart somebody built
  /// and walked away from is a fact about the day, and the ledger's release
  /// movements point at it.
  ///
  /// It is behind a confirmation and completing the sale is not, which is the
  /// right way round: one of the two is undone by ringing the sale up again, and
  /// the other is the sale.
  Future<void> _clear(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).pos_ticket_clear_title,
      message: S.of(context).pos_ticket_clear_message,
      confirmText: S.of(context).pos_ticket_clear_confirm,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    final discarded = await cart.discard();

    if (!context.mounted) return;

    if (!discarded) {
      final error = cart.error;

      if (error != null) FloatFlag.of(context).fromError(error);

      return;
    }

    FloatFlag.of(context).message(S.of(context).pos_ticket_cleared);
  }
}

/// The button that throws the ticket away.
///
/// Square, icon-only and red in a corner: it is one tap like everything else on
/// this panel, and what keeps it from being the easy one is that it is small,
/// out of the way of the amounts, and asks before doing anything.
///
/// With nothing on the ticket it is dimmed and inert rather than hidden: a
/// control that comes and goes from a corner is one the eye has to look for
/// again every time a product is added.
class _Discard extends StatelessWidget {
  const _Discard({required this.enabled, required this.action});

  final bool enabled;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: FeedbackButton(
        action: enabled ? action : null,
        message: S.of(context).pos_ticket_clear,
        mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
        width: AppSize.action,
        height: AppSize.action,
        radius: AppSize.cornerInset(AppSize.gap),
        color: scheme.surfaceOver,
        feedbackColor: scheme.input.focus,
        child: Center(child: Icon(
          CI.trash,
          size: AppSize.text * 1.2,
          color: Colors.red.withAlpha(150)
        ))
      )
    );
  }
}
