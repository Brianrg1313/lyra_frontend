import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_payment_model.dart';

import '../money_format.dart';

/// The history as a table: one row per movement, newest first.
///
/// The order is the backend's and the columns are not sortable on purpose. What
/// is on screen is one page of a filter that can run into thousands of rows, so
/// a column that sorted here would sort **the page** and quietly answer a
/// different question from the one the header promises. Narrowing the list is
/// what the filters above are for.
///
/// The date and the amount are frozen at the two ends: they are what a movement
/// is looked up by and what it is looked up for, and the middle —who, what for,
/// through where— is what scrolls when the window is narrow.
///
/// A voided row is dimmed and tagged instead of being hidden: it is in view
/// only because somebody asked for it in the filter, and what it is there to
/// show is precisely that it no longer counts.
class PaymentsTable extends StatelessWidget {
  const PaymentsTable({
    super.key,
    required this.payments,
    required this.onVoid
  });

  final List<MoneyPayment> payments;

  /// A movement was asked to be annulled. It is not offered on the rows that
  /// cannot be —an already voided one— whose action cell is left empty.
  final void Function(MoneyPayment payment) onVoid;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return DataTableView<MoneyPayment>(
      items: payments,
      frozenColumns: 1,
      trailingFrozenColumns: 1,
      style: TableStyle(
        background: scheme.surface,
        headerBackground: scheme.surfaceOver
      ),
      columns: [
        TableColumn(
          id: "date",
          title: S.of(context).finance_payment_date,
          width: 170,
          cell: (context, payment, _) => _Cell(
            payment: payment,
            text: moneyDateLabel(context, payment.date)
          )
        ),
        TableColumn(
          id: "concept",
          title: S.of(context).finance_payment_concept,
          minWidth: 150,
          flex: 2,
          cell: (context, payment, _) => Row(children: [
            Icon(
              payment.direction.isIncoming ? CI.arrow_down : CI.arrow_top,
              size: AppSize.text * 0.9,
              color: payment.isVoided
                ? scheme.text.secondary
                : payment.direction.isIncoming
                  ? scheme.snackBar.success
                  : scheme.snackBar.error
            ),
            SizedBox(width: AppSize.gap),
            if (payment.isVoided) const _VoidedTag(),
            Expanded(child: _Cell(
              payment: payment,
              // The backend writes the concept's name; a code it has no name
              // for is still drawn rather than left as a blank cell.
              text: payment.conceptName.isNotEmpty
                ? payment.conceptName
                : payment.concept
            ))
          ])
        ),
        TableColumn(
          id: "counterpart",
          title: S.of(context).finance_payment_counterpart,
          minWidth: 140,
          flex: 2,
          cell: (context, payment, _) => _Cell(
            payment: payment,
            text: payment.counterpart
          )
        ),
        TableColumn(
          id: "method",
          title: S.of(context).finance_payment_method,
          minWidth: 130,
          cell: (context, payment, _) => _Cell(
            payment: payment,
            // Which of the company's accounts it landed in is the useful half
            // when there is one: two transfers of the same shop are told apart
            // by the account and not by the rail.
            text: payment.account.isNotEmpty
              ? payment.account
              : payment.methodName.isNotEmpty
                ? payment.methodName
                : payment.method
          )
        ),
        TableColumn(
          id: "reference",
          title: S.of(context).finance_payment_reference,
          minWidth: 110,
          cell: (context, payment, _) => _Cell(
            payment: payment,
            text: payment.reference
          )
        ),
        TableColumn(
          id: "amount",
          title: S.of(context).finance_payment_amount,
          width: 140,
          alignment: Alignment.centerRight,
          cell: (context, payment, _) => TextMedium(
            moneyLabel(payment.amount, payment.currency),
            bold: true,
            multiplier: 0.9,
            ellipsis: true,
            color: payment.isVoided
              ? scheme.text.secondary
              : payment.direction.isIncoming
                ? scheme.snackBar.success
                : scheme.snackBar.error
          )
        ),
        TableColumn(
          id: "action",
          title: "",
          width: 50,
          alignment: Alignment.center,
          cell: (context, payment, _) => payment.isVoided
            // Nothing to do with a voided movement: it is already annulled, and
            // a payment is never edited or deleted afterwards.
            ? const SizedBox.shrink()
            : FocusableWidget(
                action: () => onVoid(payment),
                message: S.of(context).finance_payment_void,
                child: Icon(
                  CI.delete,
                  size: AppSize.text * 1.1,
                  color: scheme.text.secondary
                )
              )
        )
      ]
    );
  }
}

/// The text of a cell, dimmed when the movement no longer counts.
class _Cell extends StatelessWidget {
  const _Cell({required this.payment, required this.text});

  final MoneyPayment payment;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return TextSmall(
      text,
      ellipsis: true,
      color: payment.isVoided ? scheme.text.secondary : scheme.text.primary
    );
  }
}

/// The mark on a movement that was annulled.
///
/// Dimming the row is not enough on its own —a pale row reads as a row that is
/// still loading— so what it is is written next to the concept, which is the
/// cell somebody reads first.
class _VoidedTag extends StatelessWidget {
  const _VoidedTag();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      margin: EdgeInsets.only(right: AppSize.gap),
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      decoration: BoxDecoration(
        color: scheme.line,
        borderRadius: BorderRadius.circular(AppSize.gap)
      ),
      child: TextSmall(
        S.of(context).finance_payments_voided,
        multiplier: 0.85,
        color: scheme.text.secondary
      )
    );
  }
}
