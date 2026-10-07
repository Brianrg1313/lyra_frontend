import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/methods/methods_heading.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The main currency: read, never edited.
class MoneyMainCurrencyCard extends StatelessWidget {
  const MoneyMainCurrencyCard({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final currency = CurrencyCatalogService().resolve(code);

    return SizedBox(
      width: kMoneyCardWidth,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsTag(
              label: S.of(context).finance_currency_main,
              color: scheme.primary
            ),
            SizedBox(height: AppSize.gap),
            TextMedium(
              "${currency.code} · ${currency.name}",
              bold: true,
              ellipsis: true
            ),
            SizedBox(height: AppSize.gap),
            TextSmall(
              S.of(context).finance_currency_main_hint,
              color: scheme.text.secondary,
              multiplier: 0.9,
              lines: 3
            )
          ]
        )
      )
    );
  }
}
