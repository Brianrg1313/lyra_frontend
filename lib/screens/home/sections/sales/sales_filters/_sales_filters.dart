import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

import './sales_count.dart';
import './sales_filter_controls.dart';
import './sales_search_caption.dart';

/// **The bar above the board**: what the list is showing on the left, what
/// narrows it on the right.
///
/// It is one row. The count and the controls answer two halves of the same
/// question —how much there is, and of what— and reading them as two stacked
/// strips cost the board a line it needed for rows.
///
/// **Every control here is the service's and travels to the backend**, none of
/// them is applied over the rows already read. That is not a preference: a
/// stage is measured on read and not stored, so the page that comes back is
/// already the answer to the whole question, and filtering it again here would
/// hide rows the count beside it still includes. The one thing that does narrow
/// the rows on screen is the header's search, which is not a control of this
/// bar and is the reason the bar carries a caption for it ([SalesSearchCaption]).
///
/// **The states are a dropdown.** They were a strip of chips, one per state
/// with its own dot, and a dozen words on a board that is read at a glance is
/// a line and a half of controls plus a horizontal scroll to reach the last
/// one. Folded into a list, the states are still the words the backend wrote
/// and still carry their dots — the open list is where they are read, and the
/// closed control says which one is on.
class SalesFilters extends StatelessWidget {
  const SalesFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SalesService>();
    final catalog = context.watch<SalesCatalogService>();

    return Padding(
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            // **Both halves flex, and the controls get four fifths of it.** The
            // count is one short sentence and the controls wear the backend's
            // words, so the space belongs to the side that can run out of it; a
            // control that lost half its label is a control nobody can read,
            // while a count with room to spare is just a count.
            SalesCount(service: service),
            SizedBox(width: AppSize.gap),
            Expanded(child: SalesFilterControls(service: service, catalog: catalog))
          ]),
          // The backend answers a request that names a till-only filter with
          // tickets alone: a conversation the assistant is in the middle of has
          // no seller and no channel of the kind being asked about, and filing it
          // under one would be inventing an answer. A list that quietly drops
          // half its rows is a list nobody trusts, so it says so.
          //
          // Under the row and not in it: it is a caption about what was just
          // asked for, not a fourth control.
          if (service.isTicketsOnly) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: TextSmall(
              S.of(context).sales_tickets_only,
              lines: 2,
              color: ThemeColor.of(context).text.secondary
            )
          ),
          const SalesSearchCaption()
        ]
      )
    );
  }
}
