import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/home/sections/sales/stage_tag.dart';

/// Which sale this is, at the top of the panel: who is buying, where it stands
/// and how long it has been standing there.
///
/// **It is drawn from the board's row and not from the detail.** The row is
/// already in hand when the panel opens, and the three things somebody needs to
/// know they opened the right sale are all on it — so the header is there
/// before the read lands, and the blocks below fill in under it. A header that
/// waited for the network would blink the customer's name in a second after the
/// panel had already slid in.
///
/// The wait is the figure the board is read by, so it is repeated here at the
/// size the panel gives it: somebody opens a sale *because* of that number.
///
/// **It is also the one place this panel is written from.** The card already
/// carries where the sale stands, so the button that moves it on belongs beside
/// that word and not four blocks down: whoever opened the sale to decide
/// something is looking here, and the comprobante they are deciding on is the
/// block directly underneath. Which action that is —approve the payment, record
/// the handover— is not this card's to work out; it is handed in built, the
/// same way the settings rows take theirs.
class SaleDetailIdentity extends StatelessWidget {
  const SaleDetailIdentity({super.key, required this.sale, this.action});

  /// The row the panel was opened from.
  final SaleModel sale;

  /// What can be done to move this sale on, already built. `null` on a sale
  /// nothing on this screen can move —a cart the till has to charge, a sale the
  /// customer already has— and then the card is a reading like the rest of the
  /// panel.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final wait = saleWaitLabel(context, sale.since);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The customer is the title and the code is the subtitle, which is
            // the opposite of the table: a row is scanned by its code and a
            // panel is read as one purchase by one person.
            TextLarge(
              sale.customer.isEmpty
                ? S.of(context).sales_detail_customer_unknown
                : sale.customer,
              ellipsis: true,
              color: sale.customer.isEmpty ? scheme.text.secondary : null
            ),
            if (sale.ticket.isNotEmpty) ...[
              SizedBox(height: AppSize.gap * 0.5),
              // Selectable because it is the value somebody reads off a printed
              // slip and pastes into a message to the customer.
              TextSmall(
                sale.ticket,
                selectable: true,
                color: scheme.text.secondary
              )
            ],
            SizedBox(height: AppSize.spaceS),
            Wrap(
              spacing: AppSize.gap,
              runSpacing: AppSize.gap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SaleStageTag(
                  stage: sale.stage,
                  label: sale.label,
                  level: sale.level,
                  attention: sale.attention
                ),
                if (wait.isNotEmpty) TextMedium(
                  wait,
                  multiplier: 0.9,
                  bold: sale.attention,
                  color: sale.attention
                    ? scheme.text.primary
                    : scheme.text.secondary
                )
              ]
            ),
            if (action != null) ...[
              SizedBox(height: AppSize.spaceS),
              action!
            ]
          ]
        )
      )
    );
  }
}
