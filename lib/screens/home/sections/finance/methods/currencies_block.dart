import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/money/money_currencies_service.dart';
import 'package:app/services/money/money_currency_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import '../money_format.dart';
import 'methods_heading.dart';

/// The first half of the tab: what the company's money is.
///
/// The **main** currency is the one the catalog, the stock and the services
/// are priced in, and it is written here and not offered: changing it
/// relabels every stored price instead of converting it. The **exchange**
/// currencies are what the company also takes —a shop in Caracas priced in
/// dollars that is paid by Pago Movil in bolivars—, each at the official rate
/// or at one the company sets.
///
/// This is the only place the app shows the company's currencies; the
/// business profile no longer does.
///
/// It goes above the accounts because they depend on it: every account is in
/// one of these currencies, and one with no rate is money the charge cannot be
/// converted into.
class MoneyCurrenciesBlock extends StatelessWidget {
  const MoneyCurrenciesBlock({
    super.key,
    required this.service,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove
  });

  final MoneyCurrenciesService service;
  final void Function() onAdd;
  final void Function(MoneyExchange exchange) onEdit;
  final void Function(MoneyExchange exchange) onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MethodsHeading(
        title: S.of(context).finance_currencies_title,
        subtitle: S.of(context).finance_currencies_subtitle,
        // Nothing can be added against a setup that did not load: the main
        // currency every rate is a price of is not known yet.
        actionLabel: service.status == MoneyCurrenciesStatus.ready
          ? S.of(context).finance_currencies_add
          : null,
        onAction: onAdd
      ),
      SizedBox(height: AppSize.spaceS),
      _body(context)
    ]
  );

  Widget _body(BuildContext context) {
    // The business's own currency, from `/init`: the main card is still drawn
    // when the setup did not answer (or answered without one), because what
    // the catalog is priced in is known without it.
    final fallback = context.select<BusinessService, String>(
      (business) => business.currencyCode
    );
    final main = service.currencies.main.isNotEmpty
      ? service.currencies.main
      : fallback;

    return switch (service.status) {
      MoneyCurrenciesStatus.error => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (main.isNotEmpty) _MainCard(code: main),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
            child: SectionMessage(
              icon: CI.info,
              title: S.of(context).finance_currencies_error_title,
              subtitle: S.of(context).finance_currencies_error_subtitle,
              action: service.retry,
              actionLabel: S.of(context).finance_retry
            )
          )
        ]
      ),
      MoneyCurrenciesStatus.ready => _ready(main),
      _ => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
        child: const Center(child: Loading())
      )
    };
  }

  Widget _ready(String main) => Wrap(
    spacing: AppSize.gap,
    runSpacing: AppSize.gap,
    children: [
      _MainCard(code: main),
      for (final exchange in service.currencies.exchanges) _ExchangeCard(
        main: main,
        exchange: exchange,
        onEdit: () => onEdit(exchange),
        onRemove: () => onRemove(exchange)
      ),
      // Said and not left blank: with only the main card on screen, a
      // company that is paid in bolivars reads "I cannot" instead of "I
      // have not yet".
      if (service.currencies.exchanges.isEmpty) const _NoExchanges()
    ]
  );
}

/// The main currency: read, never edited.
class _MainCard extends StatelessWidget {
  const _MainCard({required this.code});

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

/// One exchange currency: its rate, where it comes from, and its two actions.
class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
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

/// What sits beside the main card while the company takes nothing else.
class _NoExchanges extends StatelessWidget {
  const _NoExchanges();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: kMoneyCardWidth,
      child: Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: Row(children: [
          Icon(CI.info, size: AppSize.text, color: scheme.text.secondary),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            S.of(context).finance_currencies_empty,
            color: scheme.text.secondary,
            lines: 3
          ))
        ])
      )
    );
  }
}
