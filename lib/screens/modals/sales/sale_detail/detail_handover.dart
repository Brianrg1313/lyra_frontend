import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **How the customer gets this sale, and how far that got.**
///
/// It is the one fact in the pipeline nobody measured: the ledger knows the
/// units left the shelf and the ticket knows the money arrived, and not one
/// collection in the platform can see a van going out or a customer walking in
/// for their box. So the block says two things and the second is the important
/// one — where it got to, and **whether anybody actually said so**
/// ([SaleHandoverModel.stored]). A counter sale is handed over by definition
/// and one that came in over a channel is not, so an unstored reading is a
/// default the backend inferred, not a record somebody left.
///
/// A sale with no handover at all says why in words. An unpaid cart has not
/// been charged and a conversation has no document, and both would otherwise
/// read as a delivery nobody has got round to.
///
/// **It is a reading and nothing else.** Recording the handover is asked for
/// from the card at the top of the panel, which is where every action on a sale
/// now lives: the card is what carries the state a person came to change, and
/// two buttons for one write —one beside the state, one under the facts— is the
/// same request offered twice.
class SaleDetailHandover extends StatelessWidget {
  const SaleDetailHandover({super.key, required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    final handover = sale.handover;

    return SettingsBlock(
      title: S.of(context).sales_detail_handover,
      child: handover == null ? _none(context) : _state(context, handover)
    );
  }

  /// Nothing to hand over, and the reason depends on which of the two sources
  /// it is — the panel says which, because "no handover" alone reads as a
  /// delivery somebody forgot.
  Widget _none(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextMedium(S.of(context).sales_detail_handover_none, ellipsis: true),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          sale.isDeal
            ? S.of(context).sales_detail_handover_none_deal
            : S.of(context).sales_detail_handover_none_open,
          lines: 3,
          color: scheme.text.secondary
        )
      ]
    );
  }

  Widget _state(BuildContext context, SaleHandoverModel handover) {
    final scheme = ThemeColor.of(context);

    return SettingsList(rows: [
      SettingsValue(
        icon: CI.delivery,
        label: S.of(context).sales_detail_handover_mode,
        // The names are the backend's, like the stage words: which modes exist
        // is declared once on the other side, so one added there shows up here
        // without a new version of the app.
        value: handover.modeName.isEmpty ? handover.mode : handover.modeName,
        empty: S.of(context).sales_detail_none
      ),
      SettingsRow(
        icon: CI.delivery_square,
        label: S.of(context).sales_detail_handover_state,
        // The reading is worth as much as its source, so the hint is not a
        // footnote: it is the difference between a driver who went out and a
        // sale the backend assumed was over.
        hint: handover.stored
          ? null
          : S.of(context).sales_detail_handover_unstored,
        child: TextMedium(
          handover.stateName.isEmpty ? handover.state : handover.stateName,
          ellipsis: true,
          bold: handover.isDelivered,
          color: handover.stored ? null : scheme.text.secondary
        )
      ),
      if (handover.at != null) SettingsValue(
        icon: CI.calendar,
        label: S.of(context).sales_detail_handover_at,
        value: saleDateLabel(context, handover.at)
      ),
      if (handover.by.isNotEmpty) SettingsValue(
        icon: CI.employee,
        label: S.of(context).sales_detail_handover_by,
        value: handover.by
      ),
      if (handover.note.isNotEmpty) SettingsValue(
        icon: CI.pen,
        label: S.of(context).sales_detail_handover_note,
        value: handover.note,
        // A tracking number is pasted into a courier's site, not read out.
        selectable: true
      )
    ]);
  }
}

/// **What the shelf is keeping for this customer**, from the ledger's own
/// holds.
///
/// It is not the cart. The cart says what the customer was quoted and this says
/// what is actually set aside, and the two disagreeing is the case worth
/// opening a sale for: a hold lapses on its own, so a conversation that has
/// been going since yesterday can be promising units the shelf let go of hours
/// ago.
///
/// It is drawn only where the question exists. A ticket holds its units on its
/// own lines and the backend answers `null` rather than an empty list, which is
/// the difference between "there is no list here" and "nothing is held".
class SaleDetailHolds extends StatelessWidget {
  const SaleDetailHolds({super.key, required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final holds = sale.reservations ?? const <SaleHoldModel>[];

    return SettingsBlock(
      title: S.of(context).sales_detail_holds,
      child: holds.isEmpty
        ? TextSmall(
            S.of(context).sales_detail_holds_empty,
            lines: 2,
            color: scheme.text.secondary
          )
        : SettingsList(rows: [
            SettingsValue(
              icon: CI.warehouse,
              label: S.of(context).sales_detail_held,
              value: saleCountLabel(context, sale.held)
            ),
            for (final hold in holds) SettingsValue(
              icon: CI.product,
              // The sku is what a person finds the row by; the product id is
              // the ledger's own and says nothing on a shelf.
              label: hold.sku.isEmpty ? hold.productId : hold.sku,
              value: S.of(context).sales_detail_hold_units(hold.qty),
              // When it lapses is the whole reason to look: a hold nobody
              // converts goes back on the shelf on its own.
              hint: hold.expiresAt == null
                ? null
                : "${S.of(context).sales_detail_hold_expires}:"
                    " ${saleDateLabel(context, hold.expiresAt)}"
            )
          ])
    );
  }
}
