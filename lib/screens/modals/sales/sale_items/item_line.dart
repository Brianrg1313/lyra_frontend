import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// One line of a sale: how many, of what, at what, for how much — and what the
/// shelf says about it.
///
/// It lives with the panel that draws the lines and not with the sale's own,
/// which carries the summary and the button that opens this one.
class SaleItemLine extends StatelessWidget {
  const SaleItemLine({
    super.key,
    required this.item,
    required this.currency
  });

  final SaleItemModel item;

  /// The sale's currency. A line does not carry its own: one ticket is charged
  /// in one currency, and the backend writes the figures in it.
  final String currency;

  /// What a line with no figure draws.
  ///
  /// It is punctuation and not copy —the same mark the board uses— and it is
  /// deliberately not the sentence the money block is allowed: a line sits at
  /// the right edge of a narrow panel, and "nobody has priced it" written once
  /// per product pushes the column off the panel and says the same thing five
  /// times.
  static const String _none = "—";

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final unit = saleAmountLabel(item.price, currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The quantity leads the line because it is what is checked against
            // the box: what is being counted is how many of this went out, and
            // the name is what it is.
            SizedBox(
              width: AppSize.text * 2.5,
              child: TextMedium(
                "${saleCountLabel(context, item.qty)}×",
                bold: true,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextMedium(
                  item.name.isEmpty
                    ? S.of(context).sales_detail_item_concept
                    : item.name,
                  lines: 2,
                  ellipsis: true,
                  color: item.name.isEmpty ? scheme.text.secondary : null
                ),
                if (_extras(context).isNotEmpty) ...[
                  SizedBox(height: AppSize.gap * 0.5),
                  TextSmall(_extras(context), lines: 3, color: scheme.text.secondary)
                ],
                if (item.sku.isNotEmpty) ...[
                  SizedBox(height: AppSize.gap * 0.5),
                  TextSmall(item.sku, ellipsis: true, color: scheme.text.secondary)
                ],
                if (unit.isNotEmpty) ...[
                  SizedBox(height: AppSize.gap * 0.5),
                  Row(children: [
                    Flexible(child: TextSmall(
                      unit,
                      ellipsis: true,
                      color: scheme.text.secondary
                    )),
                    // The list price beside the net one, so a discounted line
                    // reads as the offer it is instead of as a figure nobody
                    // can compare. Only a cart carries it.
                    if (item.list != null && item.list != item.price) ...[
                      SizedBox(width: AppSize.gap),
                      Flexible(child: TextSmall(
                        S.of(context).sales_detail_item_list(
                          saleAmountLabel(item.list, currency)
                        ),
                        ellipsis: true,
                        color: scheme.text.secondary
                      ))
                    ]
                  ])
                ]
              ]
            )),
            SizedBox(width: AppSize.gap),
            TextMedium(
              item.total == null ? _none : saleAmountLabel(item.total, currency),
              ellipsis: true,
              color: item.total == null ? scheme.text.secondary : null
            )
          ]
        ),
        _flags(context)
      ]
    );
  }

  /// What was chosen on a dish and what it went without: «+ Cheese $1.00 · Medium · without
  /// fries», what the kitchen made.
  String _extras(BuildContext context) => [
    for (final pick in item.modifiers)
      pick.price > 0 ? "+ ${pick.name} ${saleAmountLabel(pick.price, currency)}" : pick.name,
    for (final name in item.omitted) S.of(context).sales_detail_item_without(name)
  ].where((part) => part.trim().isNotEmpty).join(" · ");

  /// What the shelf says about this line, when it says anything.
  ///
  /// **The one worth stopping on is the third.** A cart entry that says
  /// `reserved` while the ledger holds nothing for it is a hold that lapsed or
  /// was released: the customer was told those units were theirs and they are
  /// not, which is a thing to see before promising the last one to somebody
  /// else. The others are quieter facts and are drawn as such.
  Widget _flags(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final flags = <Widget>[
      if (item.gone) SettingsTag(
        label: S.of(context).sales_detail_item_gone,
        color: scheme.chart.critical,
        icon: CI.info
      ),
      if (item.isUnheld) SettingsTag(
        label: S.of(context).sales_detail_item_unheld,
        color: scheme.chart.warning,
        icon: CI.info
      ) else if (item.held > 0) SettingsTag(
        label: S.of(context).sales_detail_item_held(item.held),
        color: scheme.text.secondary,
        icon: CI.warehouse
      ),
      if (item.available != null) SettingsTag(
        label: S.of(context).sales_detail_item_available(item.available!),
        color: scheme.text.secondary
      )
    ];

    if (flags.isEmpty) return const SizedBox.shrink();

    return Padding(
      // Indented to the name and not to the quantity: they say something about
      // the product, not about how many were sold.
      padding: EdgeInsets.only(
        left: AppSize.text * 2.5,
        top: AppSize.gap * 0.75
      ),
      child: Wrap(
        spacing: AppSize.gap * 0.75,
        runSpacing: AppSize.gap * 0.75,
        children: flags
      )
    );
  }
}
