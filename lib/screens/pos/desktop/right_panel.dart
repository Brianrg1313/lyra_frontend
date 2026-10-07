import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/pos/pos_invoice_event.dart';
import 'package:app/services/pos/pos_invoice_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './pos_currency.dart';
import './ticket_footer.dart';
import './ticket_header.dart';
import './ticket_line.dart';

/// Right panel of POS mode: **the ticket**, which is the sale itself.
///
/// It is one surface and not two like the left one because the three parts of it
/// are one document read top to bottom — which ticket this is, what is on it,
/// what it comes to — and a line between them would read as three cards that
/// happen to be stacked.
///
/// The head and the foot measure what they need and the **lines take the rest**:
/// a ticket of two products and one of thirty are the same screen with a
/// different amount of middle, and the total must not move down the panel as
/// products are added, because it is the number being watched while they are.
///
/// It is the widest of the three panels ([PosBody.rightWidth]) for what is in
/// here: the amounts are what cannot be cut.
///
/// **It is also what speaks for the ticket.** A ticket can be charged, cancelled
/// or have its units released from screens this counter cannot see, and the
/// service that hears it (see [PosInvoiceService]) has nowhere to say so: this
/// panel is the one place the ticket is drawn, so it is the one that announces
/// what happened to it.
class PosRightPanel extends StatefulWidget {
  const PosRightPanel({super.key});

  @override
  State<PosRightPanel> createState() => _PosRightPanelState();
}

class _PosRightPanelState extends State<PosRightPanel> {
  /// Read once and kept, because the listener has to be taken off the same
  /// object it was put on — and by then the tree may already be going away.
  late final PosInvoiceService _cart = context.read<PosInvoiceService>();

  @override
  void initState() {
    super.initState();

    _cart.addListener(_announce);
  }

  @override
  void dispose() {
    _cart.removeListener(_announce);

    super.dispose();
  }

  /// Says out loud what the company did to this ticket, once.
  ///
  /// The notice is cleared as it is said: it arrives on its own and the panel
  /// rebuilds for every tap, so leaving it standing would repeat the same
  /// sentence over a counter somebody is working on.
  void _announce() {
    final notice = _cart.notice;

    if (notice == null || !mounted) return;

    _cart.clearNotice();

    final label = _cart.noticeLabel.isEmpty
      ? S.of(context).pos_product_unnamed
      : _cart.noticeLabel;

    final flag = FloatFlag.of(context);

    switch (notice) {
      case PosTicketNotice.charged:
        flag.notification(message: S.of(context).pos_ticket_taken);
      case PosTicketNotice.cancelled:
        flag.notification(message: S.of(context).pos_ticket_dropped);
      case PosTicketNotice.released:
        flag.alert(message: S.of(context).pos_ticket_released(label));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<PosInvoiceService>();
    final currency = posCurrency(context);

    return Surface(child: Padding(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(children: [
        PosTicketHeader(cart: cart),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
        ),
        Expanded(child: cart.isEmpty
          // Nothing to retry and nothing to fix: an empty ticket is where every
          // sale starts, so the message only says where the products come from.
          ? SectionMessage(
              icon: CI.receipt,
              title: S.of(context).pos_ticket_empty_title,
              subtitle: S.of(context).pos_ticket_empty_subtitle
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: cart.lines.length,
              separatorBuilder: (context, index) => Separator.horizontal(),
              itemBuilder: (context, index) => PosTicketLine(
                key: ValueKey(cart.lines[index].key),
                line: cart.lines[index],
                cart: cart,
                currency: currency
              )
            )
        ),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
        ),
        PosTicketFooter(cart: cart, currency: currency)
      ])
    ));
  }
}
