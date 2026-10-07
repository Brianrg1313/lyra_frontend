import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/money/money_currency_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/methods/methods_heading.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// One exchange currency: its rate, where it comes from, and its two actions.
class MoneyExchangeCard extends StatelessWidget {
  const MoneyExchangeCard({
    super.key,
    required this.main,
    required this.exchange,
    required this.onEdit,
    required this.onRemove
  });

  final String main;
  final MoneyExchange exchange;
  final void Function() onEdit;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final currency = CurrencyCatalogService().resolve(exchange.currency);
    final official = exchange.mode == MoneyRateMode.official;

    return SizedBox(
      width: kMoneyCardWidth,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              // Bounded: the tag's label is flexible, and a flexible child in a
              // row with no width to give is a layout error.
              Expanded(child: Align(
                alignment: Alignment.centerLeft,
                child: SettingsTag(
                  label: official
                    ? S.of(context).finance_currency_mode_official
                    : S.of(context).finance_currency_mode_custom,
                  color: official ? scheme.text.secondary : scheme.accent
                )
              )),
              FocusableWidget(
                action: onEdit,
                message: S.of(context).edit,
                child: Icon(
                  CI.edit,
                  size: AppSize.text * 1.1,
                  color: scheme.text.secondary
                )
              ),
              SizedBox(width: AppSize.spaceXS),
              FocusableWidget(
                action: onRemove,
                message: S.of(context).finance_currency_remove,
                child: Icon(
                  CI.trash,
                  size: AppSize.text * 1.1,
                  color: scheme.snackBar.error
                )
              )
            ]),
            SizedBox(height: AppSize.gap),
            TextMedium(
              "${currency.code} · ${currency.name}",
              bold: true,
              ellipsis: true
            ),
            SizedBox(height: AppSize.gap),
            // No rate is said in the alert colour and not drawn as a zero: a
            // `1 USD = Bs. 0,00` is a price somebody would charge.
            if (exchange.rate == null)
              TextSmall(
                S.of(context).finance_currency_no_rate,
                color: scheme.snackBar.alert
              )
            else
              TextMedium(
                moneyRateLabel(main, exchange.rate!, exchange.currency),
                bold: true,
                multiplier: 0.9,
                ellipsis: true
              ),
            if (official && exchange.updated != null) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).finance_currency_updated(
                  moneyDateLabel(context, exchange.updated)
                ),
                color: scheme.text.secondary,
                multiplier: 0.9
              )
            ],
            // Under a custom rate the official one stays in sight: it is how
            // far the company's own figure is from the one it can point at.
            if (!official && exchange.official != null) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).finance_currency_official_today(
                  moneyRateLabel(main, exchange.official!, exchange.currency)
                ),
                color: scheme.text.secondary,
                multiplier: 0.9
              )
            ]
          ]
        )
      )
    );
  }
}
