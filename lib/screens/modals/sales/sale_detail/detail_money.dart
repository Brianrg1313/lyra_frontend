import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **What the sale comes to and how it is being settled.**
///
/// It is the block the panel is usually opened for, and every figure in it is
/// the backend's: nothing here adds up the lines. A total worked out on this
/// side would be a second arithmetic over the same cart, and the day the two
/// disagreed the screen would be arguing with the till.
///
/// **A missing figure is said with words.** A conversation nobody has priced
/// has no subtotal and no tax, and writing `0,00` over either would claim the
/// sale is worth nothing and that it is tax-free — two statements nobody made.
/// The dash the table uses is not enough room to say that, and a panel has the
/// room.
///
/// **It is read in two columns**, which is the one block of the panel that
/// wants them: every figure here is a handful of characters under a two-word
/// label, so in one column three quarters of the panel's width was blank and
/// the sale's arithmetic ran off the bottom of the screen. Paired, the chain a
/// person actually follows —units, subtotal, tax, total— is four cells read the
/// way anything else on a page is read, left to right and then down, and the
/// two figures that only exist together (what came in, what is still owed) sit
/// where they can be compared instead of one under the other.
///
/// The method keeps a row to itself because it is the only entry that is not a
/// figure: what the payment was identified by hangs under it, and a reference
/// number is as long as the bank felt like making it.
class SaleDetailMoney extends StatelessWidget {
  const SaleDetailMoney({super.key, required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    final payment = sale.payment;

    return SettingsBlock(
      title: S.of(context).sales_detail_money,
      child: _MoneyGrid(rows: [
        [_units(context), _subtotal(context)],
        [_tax(context), _total(context)],
        [_method(context)],
        // Only a sale that can owe anything draws a balance —a credit ticket,
        // or a channel ticket paid in parts or asked for a late delivery—:
        // a "collected" of zero over a cash sale would read as a payment that
        // never came.
        if (payment.hasBalance) [_collected(context), _outstanding(context)],
        if (sale.due != null) [_due(context, sale.due!)],
        if (payment.received.isNotEmpty) [_received(context)]
      ])
    );
  }

  Widget _units(BuildContext context) => SettingsValue(
    icon: CI.basket,
    label: S.of(context).sales_detail_units,
    value: saleCountLabel(context, sale.units)
  );

  Widget _subtotal(BuildContext context) => SettingsValue(
    icon: CI.receipt,
    label: S.of(context).sales_detail_subtotal,
    value: saleAmountLabel(sale.subtotal, sale.currency),
    empty: S.of(context).sales_detail_unpriced
  );

  /// The one figure of the panel that is read from across the room, so it is
  /// the only one drawn larger than its neighbours — which is also what keeps
  /// it standing out in half the width it used to have.
  Widget _total(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SettingsRow(
      icon: CI.wallet,
      label: S.of(context).sales_detail_total,
      child: TextMedium(
        sale.total == null
          ? S.of(context).sales_detail_unpriced
          : saleAmountLabel(sale.total, sale.currency),
        multiplier: 1.4,
        bold: true,
        ellipsis: true,
        color: sale.total == null ? scheme.text.secondary : null
      )
    );
  }

  Widget _collected(BuildContext context) => SettingsValue(
    icon: CI.chack_circle,
    label: S.of(context).sales_detail_collected,
    value: saleAmountLabel(sale.payment.collected, sale.currency)
  );

  Widget _outstanding(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final payment = sale.payment;

    return SettingsRow(
      icon: CI.discount_card,
      label: S.of(context).sales_detail_outstanding,
      child: TextMedium(
        payment.isOwed
          ? saleAmountLabel(payment.outstanding, sale.currency)
          : S.of(context).sales_detail_settled,
        bold: payment.isOwed,
        ellipsis: true,
        // The debt is the only red figure on the panel: it is the one thing on
        // a finished-looking sale that is not finished.
        color: payment.isOwed ? scheme.chart.critical : scheme.text.secondary
      )
    );
  }

  /// What is asked for on top of the total (a delivery chosen after the
  /// charge), line by line; it joins the total once paid.
  Widget _due(BuildContext context, SaleDueModel due) => SettingsValue(
    icon: CI.delivery,
    label: S.of(context).sales_detail_due,
    value: saleAmountLabel(due.total, sale.currency),
    hint: due.items.isEmpty
      ? null
      : [for (final line in due.items) line.name].join(" · ")
  );

  /// Each approval of the money, oldest first: how much, how, when.
  Widget _received(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SettingsRow(
      icon: CI.chack_circle,
      label: S.of(context).sales_detail_received,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, entry) in sale.payment.received.indexed) ...[
            if (index > 0) SizedBox(height: AppSize.gap * 0.5),
            TextMedium(saleAmountLabel(entry.amount, sale.currency), ellipsis: true),
            TextSmall(
              [
                if (entry.method.isNotEmpty) entry.method,
                if (entry.reference.isNotEmpty) entry.reference,
                if (entry.at != null) saleDateLabel(context, entry.at)
              ].join(" · "),
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        ]
      )
    );
  }

  /// The tax, with the breakdown per rate under it when there is more than one.
  ///
  /// One rate needs no breakdown —it is the line above with a percentage on
  /// it— and several is what a fiscal ticket prints, which is the case somebody
  /// opens this to check.
  Widget _tax(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SettingsRow(
      icon: CI.documents,
      label: S.of(context).sales_detail_tax,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextMedium(
            sale.tax == null
              ? S.of(context).sales_detail_untaxed
              : saleAmountLabel(sale.tax, sale.currency),
            ellipsis: true,
            color: sale.tax == null ? scheme.text.secondary : null
          ),
          if (sale.taxes.length > 1)
            for (final rate in sale.taxes) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).sales_detail_tax_rate(
                  _rate(rate.rate),
                  saleAmountLabel(rate.base, sale.currency)
                ),
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
        ]
      )
    );
  }

  /// How it is being settled, with what the payment was identified by under it.
  ///
  /// The label changes with the source: a ticket **was paid** with a method,
  /// and a conversation was only **offered** an account to pay into — the kind
  /// is decided when the ticket is charged, so calling it a payment would be
  /// saying money arrived.
  Widget _method(BuildContext context) => SettingsValue(
    icon: CI.safe_password,
    label: sale.isDeal
      ? S.of(context).sales_detail_method_offered
      : S.of(context).sales_detail_method,
    // The backend resolved the name; the code is the fallback, so a method
    // added there is never a blank row here.
    value: sale.payment.name.isEmpty ? sale.payment.method : sale.payment.name,
    empty: S.of(context).sales_detail_none,
    hint: sale.payment.reference.isEmpty
      ? null
      : "${S.of(context).sales_detail_reference}: ${sale.payment.reference}"
  );

  /// A percentage as people write it: `16`, and `16.5` only when it has a half.
  /// It is not an amount, so it does not go through the currency's own writing.
  static String _rate(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
}

/// The data points of the money block, two to a line.
///
/// It is [SettingsList] with the rows paired: the separator between lines and
/// the space it keeps are the same, so the block still reads as part of the
/// same panel as the ones under it. A line of one is drawn full width, which is
/// what makes the method —whose reference hangs under it— an entry of its own
/// without a second shape to build it with.
///
/// **Under a certain width it is one column again.** The panel is as wide as
/// the window lets it be (`min(_panelWidth, width * .55)`), so on a narrow
/// screen two columns are two figures cut in half — and the whole point of
/// pairing them is that the figure is read at a glance. The fallback is
/// literally [SettingsList], which is the shape this block had before.
class _MoneyGrid extends StatelessWidget {
  const _MoneyGrid({required this.rows});

  /// The lines, each one or two data points wide.
  final List<List<Widget>> rows;

  /// Narrowest a pair is worth drawing at. Below it a cell is about the width
  /// of the label above the figure, and an ellipsis over an amount is a figure
  /// nobody can act on.
  static double get _pairable => AppSize.action * 6;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < _pairable
      ? SettingsList(rows: [for (final row in rows) ...row])
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) Separator.horizontal(
                margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
              ),
              _line(rows[i])
            ]
          ]
        )
  );

  /// One line. The cells share the width evenly rather than taking what they
  /// need: a column that moved with the length of the amount in it would put
  /// the second figure of every sale in a different place.
  Widget _line(List<Widget> cells) {
    if (cells.length == 1) return cells.single;

    return Row(
      // The cells are as tall as what is in them —the tax carries its breakdown
      // when there is more than one rate— and a taller neighbour must not push
      // the shorter one's label off the line it shares.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          if (i > 0) SizedBox(width: AppSize.spaceS),
          Expanded(child: cells[i])
        ]
      ]
    );
  }
}
