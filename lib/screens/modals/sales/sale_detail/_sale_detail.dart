import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_service.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'detail_handover.dart';
import 'detail_identity.dart';
import 'detail_items.dart';
import 'detail_money.dart';
import 'detail_proof.dart';
import 'detail_trace.dart';

/// **What the panel was closed asking for.**
///
/// The two ways a sale is moved on from this screen, and the panel makes
/// neither of them: `SalesService` is provided by the sales section, which
/// lives under the navigator this opens on, so the board is what writes — the
/// same arrangement the handover form has always had.
enum SaleDetailRequest {
  /// Say the payment arrived and close the sale. Offered on a sale standing at
  /// "Pago por verificar", where a person is the missing step.
  approve,

  /// Record how the customer gets it and how far that got.
  fulfil
}

/// Opens one sale in full: what is on it, what it comes to, how it is being
/// paid, where it was made and how far the handover got.
///
/// It slides in from the right and leaves the board in view beside it, like a
/// table's settings and a channel's panel: the row that was tapped is what was
/// being looked at, so it stays reachable while the sale is open.
///
/// **It writes nothing.** The sale is read-only on this screen — what a person
/// can do to it is *asked for* here and recorded by the board (which used to
/// offer the handover as an icon on the row, in a frozen column that was empty
/// on every sale with nothing to hand over). There are two such asks, both on
/// the card at the top and never both at once, because the two sales they
/// belong to are different sales: approving belongs to a conversation whose
/// customer says they paid, and the handover to a ticket that was charged.
/// Charging one is still the counter's job.
///
/// So it returns **what was asked for** and not the write itself
/// ([SaleDetailRequest]): `SalesService` is provided by the sales section,
/// which lives under the navigator this panel opens on. The board makes the
/// write, the same way it does for the form that collects the handover.
Future<SaleDetailRequest?> showSaleDetail(
  BuildContext context, {
  required SaleModel sale,
  required SalesCatalogService catalog
}) async {
  final width = math.min(_panelWidth, MediaQuery.of(context).size.width * .55);

  final asked = await showSideModal(
    context: context,
    // The code names the sale to a person, so it is the title when there is
    // one. A conversation has not been rung up and has no code, and "Venta" is
    // what it honestly is.
    title: sale.ticket.isEmpty ? S.of(context).sales_detail_title : sale.ticket,
    minWidth: width,
    maxWidth: width,
    builder: (context) => SaleDetailModal(sale: sale, catalog: catalog)
  );

  return asked is SaleDetailRequest ? asked : null;
}

/// Width of the panel where there is room for it. Wider than the handover
/// form's 420 because this one carries the lines of a ticket — a product name,
/// its price and its total on one row — and narrower than a page, so the board
/// it was opened from stays beside it.
double get _panelWidth => AppSize.action * 9 + AppSize.padding * 2;

/// Everything about one sale, in the panel its row opens.
///
/// **The header does not wait for the network.** Who is buying, where the sale
/// stands and how long it has been standing there are all on the row that was
/// tapped, so [SaleDetailIdentity] is drawn from it immediately and the blocks
/// fill in underneath. What is read is the half the list deliberately does not
/// carry: the products, the tax breakdown, the handover and the holds.
///
/// **The read is not cached anywhere.** A sale is a measurement of collections
/// that keep moving —the invoice's status, the conversation's cart, the
/// ledger's holds— so it is asked for every time the panel opens; a detail kept
/// between two openings is a drawing of a sale as it was.
class SaleDetailModal extends StatefulWidget {
  const SaleDetailModal({
    super.key,
    required this.sale,
    required this.catalog
  });

  /// The row the panel was opened from. It names the sale to the backend and
  /// draws the header until the detail lands.
  final SaleModel sale;

  /// What the channel codes are called. It comes in as a parameter because
  /// `SalesCatalogService` is provided by the sales section, which lives under
  /// the navigator this panel opens on — the same reason the handover panel
  /// takes its modes.
  final SalesCatalogService catalog;

  @override
  State<SaleDetailModal> createState() => _SaleDetailModalState();
}

class _SaleDetailModalState extends State<SaleDetailModal> {
  /// Owned by the panel: created when it opens, released when it closes.
  final _detail = SaleDetailService();

  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because the read notifies its service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build — the same rule the sections follow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The row's own id, whatever the row is: the endpoint resolves a ticket
      // id, an invoice id and a conversation id to the same sale, so the panel
      // never has to work out which of the three it is holding.
      _detail.load(widget.sale.id);
    });
  }

  @override
  void dispose() {
    _detail.dispose();

    super.dispose();
  }

  /// **What this sale can be moved on to, as the button that asks for it.**
  ///
  /// It is read off the **row** the panel was opened from and not off the
  /// detail, which is the same rule the header follows: the button is there
  /// with the card, before the read lands, and the two facts it depends on
  /// —where the sale stands and whether it has a handover left— are both on the
  /// row already.
  ///
  /// The two are mutually exclusive by what they are: only a conversation
  /// reaches "Pago por verificar" and only a charged ticket has a handover. The
  /// approval is offered first anyway, because a sale is only ever worked in
  /// that order — the money, and then the box.
  ///
  /// Asking closes the panel. Both open something on the board —a confirmation,
  /// a form— and stacking that over a side modal leaves the sale peeking out
  /// behind the thing it is about; from that point on what the person is doing
  /// is answering it.
  Widget? _action(BuildContext context) {
    if (widget.sale.canApprove) {
      return _button(
        context,
        title: S.of(context).sales_approve_action,
        icon: CI.chack_circle,
        request: SaleDetailRequest.approve
      );
    }

    if (widget.sale.canFulfil) {
      return _button(
        context,
        title: S.of(context).sales_handover_action,
        icon: CI.delivery,
        request: SaleDetailRequest.fulfil
      );
    }

    return null;
  }

  Widget _button(
    BuildContext context, {
    required String title,
    required IconData icon,
    required SaleDetailRequest request
  }) => Button(
    title: title,
    leftIcon: Icon(
      icon,
      size: AppSize.text,
      color: ThemeColor.of(context).button.text
    ),
    action: () => Navigator.pop(context, request)
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SaleDetailIdentity(sale: widget.sale, action: _action(context)),
      Expanded(child: ListenableBuilder(
        listenable: _detail,
        builder: (context, _) => _body(context)
      ))
    ]
  );

  Widget _body(BuildContext context) => switch (_detail.status) {
    // The row was there a moment ago and cannot be opened, which is its own
    // piece of news and not a failure: the units went back, the question was
    // never a purchase, or it was rung up under another record. There is
    // nothing to retry, so nothing is offered.
    SaleDetailStatus.missing => SectionMessage(
      icon: CI.info,
      title: S.of(context).sales_detail_missing_title,
      subtitle: S.of(context).sales_detail_missing_subtitle
    ),
    SaleDetailStatus.error => SectionMessage(
      icon: CI.info,
      title: S.of(context).sales_detail_error_title,
      subtitle: S.of(context).sales_detail_error_subtitle,
      action: _detail.retry,
      actionLabel: S.of(context).sales_retry
    ),
    SaleDetailStatus.ready => _sale(),
    _ => const Center(child: Loading())
  };

  /// The sale, in the order the questions are asked in: what it comes to, what
  /// is on it, whether the customer has it, and only then where it came from.
  ///
  /// The panel scrolls itself — `showSideModal` hands the builder a bounded
  /// height and no scroll of its own — and the bottom padding is added back
  /// because the side panel leaves its own out so scrolled content reaches the
  /// edge.
  Widget _sale() {
    final sale = _detail.sale;

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      children: [
        // Directly under the card, and above the money: it is what the button
        // on that card is decided from, and somebody about to say a payment
        // arrived should not have to scroll past the totals to see it. Only
        // where the question can be asked at all — a sale rung up at the
        // counter has no conversation for a comprobante to have come through.
        if (SaleDetailProof.belongsTo(sale)) SaleDetailProof(sale: sale),
        SaleDetailMoney(sale: sale),
        SaleDetailItems(sale: sale),
        SaleDetailHandover(sale: sale),
        // Only where the question exists. A ticket holds its units on its own
        // lines and the backend answers `null` rather than an empty list, so a
        // block here would be a heading over a fact that belongs to the lines.
        if (sale.reservations != null) SaleDetailHolds(sale: sale),
        SaleDetailTrace(sale: sale, catalog: widget.catalog)
      ]
    );
  }
}
