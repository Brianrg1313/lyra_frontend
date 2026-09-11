import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';

/// The currency the company charges with, which is what every figure of the
/// counter is written in — the catalog's prices and the ticket's totals both.
///
/// **They are two subscriptions and not one**: the company says *in which*
/// currency it charges ([BusinessService.currencyCode]) and the catalog says
/// *how it is written* ([CurrencyCatalogService.resolve]). Both are `select`s,
/// so a widget reading this repaints when the business changes or the catalog
/// arrives, and not on every other change of either service.
///
/// It is called from the two roots that need it —the product grid and the
/// ticket— and the value goes down from there. Reading it in each tile or each
/// line would subscribe the whole grid to the catalog.
CurrencyModel posCurrency(BuildContext context) {
  final code = context.select<BusinessService, String>(
    (business) => business.currencyCode
  );

  return context.select<CurrencyCatalogService, CurrencyModel>(
    (catalog) => catalog.resolve(code)
  );
}

/// An amount written the way the company charging it writes it, symbol
/// included: `$1,234.50`, `1.234,50€`, `Bs. 1.234,50`.
///
/// The number is fixed to the currency's own decimals before it is formatted
/// because what arrives here is arithmetic —a price times units, a percentage of
/// a subtotal— and a double straight out of that is `10.199999999999999` as
/// often as not. [CurrencyModel.label] rounds for display anyway; doing it here
/// as well is what keeps a very large total out of scientific notation, which
/// [CurrencyModel.parse] cannot read back.
String posAmount(CurrencyModel currency, double value) {
  final written = value.toStringAsFixed(currency.decimals);

  return currency.label(written) ?? written;
}
