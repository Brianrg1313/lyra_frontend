import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/money/money_currencies_service.dart';
import 'package:app/services/money/money_currency_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/finance/methods/widgets/money_exchange_card.dart';
import 'package:app/screens/home/sections/finance/methods/widgets/money_main_currency_card.dart';
import 'package:app/screens/home/sections/finance/methods/widgets/money_no_exchanges.dart';

import './methods_heading.dart';

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
          if (main.isNotEmpty) MoneyMainCurrencyCard(code: main),
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
      MoneyMainCurrencyCard(code: main),
      for (final exchange in service.currencies.exchanges) MoneyExchangeCard(
        main: main,
        exchange: exchange,
        onEdit: () => onEdit(exchange),
        onRemove: () => onRemove(exchange)
      ),
      // Said and not left blank: with only the main card on screen, a
      // company that is paid in bolivars reads "I cannot" instead of "I
      // have not yet".
      if (service.currencies.exchanges.isEmpty) const MoneyNoExchanges()
    ]
  );
}
