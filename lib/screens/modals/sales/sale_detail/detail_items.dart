import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/sales/sale_items/_sale_items.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **What is on the sale**, as much of it as a block can honestly hold: how
/// many lines there are, the ones worth stopping on, and the way into them.
///
/// This is the half the board cannot carry —fifty sales with every line of
/// every one of them is a payload nobody reads— and it is the reason the detail
/// endpoint exists at all. It used to be drawn here in full, and that is what
/// this block is not any more: **a ticket has one line or it has three
/// hundred**, and three hundred of them in the middle of the panel pushed the
/// handover, the holds and where the sale came from past the bottom of a screen
/// that is read top to bottom. The lines now open in their own panel
/// ([showSaleItems]), which stacks on this one and comes back to it.
///
/// **What does not move behind a button is what somebody has to see without
/// asking.** A product that can no longer be sold, and above all a line that
/// says its units are held while the ledger holds none of them — the customer
/// was told those were theirs and they are not. Counted here, they are the
/// reason to open the list; hidden inside it they would be a warning nobody
/// meets until they go looking for it.
class SaleDetailItems extends StatelessWidget {
  const SaleDetailItems({super.key, required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SettingsBlock(
      title: S.of(context).sales_detail_items,
      child: sale.items.isEmpty
        ? TextSmall(
            S.of(context).sales_detail_items_empty,
            lines: 2,
            color: scheme.text.secondary
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsList(rows: [
                SettingsValue(
                  icon: CI.list,
                  label: S.of(context).sales_detail_items_lines,
                  value: saleCountLabel(context, sale.items.length)
                ),
                ?_flags(context)
              ]),
              SizedBox(height: AppSize.spaceS),
              Button(
                title: S.of(context).sales_detail_items_open,
                leftIcon: Icon(
                  CI.product,
                  size: AppSize.text,
                  color: scheme.button.text
                ),
                action: () => showSaleItems(context, sale: sale)
              )
            ]
          )
    );
  }

  /// The lines the shelf disagrees with, counted. `null` when it agrees about
  /// all of them, which is the ordinary sale and gets no row at all — a "0
  /// problems" line on every ticket is a row people stop reading.
  Widget? _flags(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final gone = sale.items.where((item) => item.gone).length;
    final unheld = sale.items.where((item) => item.isUnheld).length;

    if (gone == 0 && unheld == 0) return null;

    return SettingsRow(
      icon: CI.info,
      label: S.of(context).sales_detail_items_flags,
      child: Wrap(
        spacing: AppSize.gap * 0.75,
        runSpacing: AppSize.gap * 0.75,
        children: [
          // The promise the shelf is not keeping goes first: it is the one that
          // is about to be made to somebody else.
          if (unheld > 0) SettingsTag(
            label: S.of(context).sales_detail_items_unheld_count(unheld),
            color: scheme.chart.warning,
            icon: CI.info
          ),
          if (gone > 0) SettingsTag(
            label: S.of(context).sales_detail_items_gone_count(gone),
            color: scheme.chart.critical,
            icon: CI.info
          )
        ]
      )
    );
  }
}
