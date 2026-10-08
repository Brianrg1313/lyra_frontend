import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/sales/stage/sale_stage_tag.dart';

import './sale_format.dart';

/// The board: one row per sale, newest movement first.
///
/// It is read **left to right as a sentence** — which sale this is, who it is
/// for, where it stands, where it came from, how long it has been standing
/// there — because that is the order the questions are asked in. The ticket is
/// frozen at the left end, so scrolling across the money never takes away the
/// code that names the row.
///
/// **There is no column of actions.** There was one, at the right end and
/// frozen there: a single icon that opened the handover, drawn only on a
/// charged sale the customer does not have yet. That is a minority of the rows
/// on a good day and none of them on most, so what the board actually showed
/// was a third band of empty cells behind its own divider — a column that has
/// to be explained is a column that is not being read. The handover moved to
/// where the rest of the sale already is: the panel every row opens.
///
/// **The columns are not sortable.** The list is one page of a filter and the
/// backend orders it by last movement, which is the order a board has to be in;
/// a header that reordered the page would reorder fifty of several hundred rows
/// and answer a different question from the one it promises. It is the same
/// rule the money history and the receivables follow.
///
/// **Nothing here is computed.** What a sale is worth, what is still owed on
/// it, whether it needs somebody's attention — all of it is measured on the
/// other side and arrives on the row. A figure worked out from the rows on
/// screen would be a different number from the one the question was about.
class SalesTable extends StatelessWidget {
  const SalesTable({
    super.key,
    required this.sales,
    required this.catalog,
    required this.onOpen
  });

  final List<SaleModel> sales;

  /// What the channel codes are called. It is passed in and not read off a
  /// provider so that the table stays a drawing of what it is handed.
  final SalesCatalogService catalog;

  /// A row was tapped: the sale is opened in full. **Every** row offers it —
  /// the columns are the ten facts that fit, and what is on the sale, what it
  /// was taxed and how far the handover got are not among them, so a row that
  /// could not be opened would be a row whose remaining questions have no
  /// answer on this screen.
  final void Function(SaleModel sale) onOpen;

  /// What a cell with nothing in it draws.
  ///
  /// It is punctuation and not copy, which is why it is not an `S` key: a
  /// conversation that has not been priced has no total, and a blank cell in
  /// the middle of a column of amounts reads as data that failed to load rather
  /// than as a value that does not exist.
  static const String _none = "—";

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return DataTableView<SaleModel>(
      items: sales,
      frozenColumns: 1,
      onRowTap: (sale, _) => onOpen(sale),
      style: TableStyle(
        background: scheme.surface,
        headerBackground: scheme.surfaceOver
      ),
      columns: [
        TableColumn(
          id: "ticket",
          title: S.of(context).sales_column_ticket,
          width: 120,
          // A conversation has not been rung up, so it has no code: that is
          // what tells a deal apart from a sale at a glance, and it is the
          // value somebody reads off a printed slip to look one up.
          //
          // A sale this person has not opened yet carries the side bar
          // number's red mark here, at the frozen end, and reads bold: the
          // rows that number counts.
          cell: (context, sale, _) => Row(children: [
            if (sale.unseen) Padding(
              padding: EdgeInsets.only(right: AppSize.gap),
              child: const UnseenMark()
            ),
            Flexible(child: TextSmall(
              sale.ticket.isEmpty ? _none : sale.ticket,
              ellipsis: true,
              bold: sale.unseen,
              color: sale.ticket.isEmpty
                ? scheme.text.secondary
                : scheme.text.primary
            ))
          ])
        ),
        TableColumn(
          id: "customer",
          title: S.of(context).sales_column_customer,
          minWidth: 150,
          flex: 2,
          // The contact is the fallback and not a second line: a row is 46
          // pixels and the name is already the contact when there is no name
          // (the backend reads it down to the one value a list shows).
          cell: (context, sale, _) => TextSmall(
            sale.customer.isEmpty ? _none : sale.customer,
            ellipsis: true,
            bold: sale.unseen,
            color: sale.customer.isEmpty
              ? scheme.text.secondary
              : scheme.text.primary
          )
        ),
        TableColumn(
          id: "stage",
          title: S.of(context).sales_column_stage,
          width: 200,
          cell: (context, sale, _) => SaleStageTag(
            stage: sale.stage,
            label: sale.label,
            level: sale.level,
            attention: sale.attention
          )
        ),
        TableColumn(
          id: "channel",
          title: S.of(context).sales_column_channel,
          width: 130,
          cell: (context, sale, _) => TextSmall(
            catalog.channelName(sale.channel),
            ellipsis: true,
            color: scheme.text.secondary
          )
        ),
        TableColumn(
          id: "wait",
          title: S.of(context).sales_column_wait,
          width: 120,
          // The one column somebody scans down. A sale that has been waiting
          // since this morning and one charged a minute ago are the same word
          // in the stage column and two very different problems, and the ones
          // that are waiting on the company are the ones drawn in full.
          cell: (context, sale, _) => TextMedium(
            saleWaitLabel(context, sale.since),
            multiplier: 0.9,
            ellipsis: true,
            bold: sale.attention,
            color: sale.attention
              ? scheme.text.primary
              : scheme.text.secondary
          )
        ),
        TableColumn(
          id: "units",
          title: S.of(context).sales_column_units,
          width: 80,
          alignment: Alignment.centerRight,
          cell: (context, sale, _) => TextSmall(
            saleCountLabel(context, sale.units),
            ellipsis: true,
            color: scheme.text.secondary
          )
        ),
        TableColumn(
          id: "total",
          title: S.of(context).sales_column_total,
          width: 130,
          alignment: Alignment.centerRight,
          cell: (context, sale, _) {
            final label = saleAmountLabel(sale.total, sale.currency);

            return TextSmall(
              label.isEmpty ? _none : label,
              ellipsis: true,
              // A deal has no price yet, and a zero there would claim the sale
              // is worth nothing rather than that nobody has said.
              color: label.isEmpty ? scheme.text.secondary : scheme.text.primary
            );
          }
        ),
        TableColumn(
          id: "outstanding",
          title: S.of(context).sales_column_outstanding,
          width: 130,
          alignment: Alignment.centerRight,
          // Only a credit ticket owes anything — every other method is money
          // that was there when the ticket was written — so the column is
          // mostly blank on purpose: what is in it is the whole point of it.
          cell: (context, sale, _) {
            final owed = sale.outstanding;

            if (owed == null || owed <= 0) {
              return TextSmall(_none, color: scheme.text.secondary);
            }

            return TextMedium(
              saleAmountLabel(owed, sale.currency),
              bold: true,
              multiplier: 0.9,
              ellipsis: true,
              color: scheme.chart.critical
            );
          }
        ),
        TableColumn(
          id: "seller",
          title: S.of(context).sales_column_seller,
          width: 140,
          // A conversation the assistant is holding has no seller: nobody sold
          // it, it is being sold.
          cell: (context, sale, _) => TextSmall(
            sale.seller.isEmpty ? _none : sale.seller,
            ellipsis: true,
            color: scheme.text.secondary
          )
        )
      ]
    );
  }
}
