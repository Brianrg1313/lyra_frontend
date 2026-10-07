import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_receivable_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/money_format.dart';

/// What is still owed, as a table: one row per credit ticket, newest first.
///
/// The three amounts are read across, not down: what the ticket was worth, how
/// much of it has come in and what is left. The last one is the column somebody
/// is here for, so it is frozen at the right end and it is the only one drawn
/// in colour.
///
/// Like the payments table, the columns are not sortable: this is one page of a
/// filter, and a header that sorted it would sort the page and answer a
/// different question from the one it promises.
class ReceivablesTable extends StatelessWidget {
  const ReceivablesTable({
    super.key,
    required this.sales,
    required this.currency,
    required this.onCollect
  });

  final List<MoneyReceivable> sales;

  /// The company's currency, answered once for the whole page instead of on
  /// every row.
  final String currency;

  /// A ticket was asked to be collected against. It opens the record panel with
  /// the settlement already pointed at this sale.
  final void Function(MoneyReceivable sale) onCollect;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return DataTableView<MoneyReceivable>(
      items: sales,
      frozenColumns: 1,
      trailingFrozenColumns: 1,
      style: TableStyle(
        background: scheme.surface,
        headerBackground: scheme.surfaceOver
      ),
      columns: [
        TableColumn(
          id: "ticket",
          title: S.of(context).finance_receivable_ticket,
          width: 130,
          cell: (context, sale, _) => TextSmall(sale.ticket, ellipsis: true)
        ),
        TableColumn(
          id: "customer",
          title: S.of(context).finance_receivable_customer,
          minWidth: 150,
          flex: 2,
          cell: (context, sale, _) => TextSmall(
            sale.customer,
            ellipsis: true
          )
        ),
        TableColumn(
          id: "date",
          title: S.of(context).finance_receivable_date,
          width: 130,
          cell: (context, sale, _) => TextSmall(
            moneyDayLabel(context, sale.date),
            ellipsis: true,
            color: scheme.text.secondary
          )
        ),
        TableColumn(
          id: "total",
          title: S.of(context).finance_receivable_total,
          width: 130,
          alignment: Alignment.centerRight,
          cell: (context, sale, _) => TextSmall(
            moneyLabel(sale.total, currency),
            ellipsis: true
          )
        ),
        TableColumn(
          id: "collected",
          title: S.of(context).finance_receivable_collected,
          width: 130,
          alignment: Alignment.centerRight,
          cell: (context, sale, _) => TextSmall(
            moneyLabel(sale.collected, currency),
            ellipsis: true,
            // Nothing collected yet is dimmed rather than hidden: the column
            // has to line up top to bottom, and a blank cell reads as missing
            // data instead of as a zero.
            color: sale.collected == 0
              ? scheme.text.secondary
              : scheme.text.primary
          )
        ),
        TableColumn(
          id: "outstanding",
          title: S.of(context).finance_receivable_outstanding,
          width: 140,
          alignment: Alignment.centerRight,
          cell: (context, sale, _) => TextMedium(
            moneyLabel(sale.outstanding, currency),
            bold: true,
            multiplier: 0.9,
            ellipsis: true,
            // A settled ticket is only on screen because somebody asked to see
            // them: its zero is the good news, not the alarm.
            color: sale.outstanding <= 0
              ? scheme.snackBar.success
              : scheme.snackBar.alert
          )
        ),
        TableColumn(
          id: "action",
          title: "",
          width: 50,
          alignment: Alignment.center,
          cell: (context, sale, _) => sale.outstanding <= 0
            // Nothing left to collect: the row is here for the record.
            ? const SizedBox.shrink()
            : FocusableWidget(
                action: () => onCollect(sale),
                message: S.of(context).finance_receivable_collect,
                child: Icon(
                  CI.plus,
                  size: AppSize.text * 1.1,
                  color: scheme.text.secondary
                )
              )
        )
      ]
    );
  }
}
