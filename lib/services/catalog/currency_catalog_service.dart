import 'package:flutter/foundation.dart';

import 'package:app/services/catalog/currency_model.dart';

/// Code of the currency used to write a price when there's nothing else to say:
/// a business that hasn't declared its own yet, or a screen that paints before
/// the catalog has arrived.
///
/// It's the only currency assumption this app makes, and only as a last resort:
/// if the catalog doesn't bring it, the price is still written, with the code
/// as the symbol (see [CurrencyModel.unknown]).
const String _kDefaultCurrency = "USD";

/// The currencies in which a price can be written, and **how each one is
/// written**.
///
/// It's one of the two platform catalogs that arrive in `/init` (the other is
/// [CountryCatalogService]) and is populated from there, in [ClientService.resolve],
/// before the tree is mounted: by the time the stock sheet paints its first
/// price cell the catalog is already loaded.
///
/// It's a singleton for the same reason as the countries one: it's a single
/// instance for the whole app, it doesn't depend on the active business —each
/// business picks its own from this list, but the list is the same— nor on any
/// screen's lifecycle. It's registered in `initialBuilder` with
/// `ChangeNotifierProvider.value` so it can be observed with `context.watch`,
/// and for that same reason the provider must not destroy it.
///
/// What matters: the symbol, which side it goes on, how many decimals and
/// whether it carries a space are **backend data**, not an enum of this app.
/// Enabling a currency, or fixing its symbol, is a row in `lyra_admin`.
/// `currencies`.
///
/// ```dart
/// // To offer them in a form.
/// final options = context.watch<CurrencyCatalogService>().currencies;
///
/// // To write a saved amount. Always returns a currency.
/// final price = CurrencyCatalogService().resolve(code).label("22.23");
/// ```
class CurrencyCatalogService extends ChangeNotifier {
  //SINGLETON
  static final CurrencyCatalogService _singleton =
    CurrencyCatalogService._internal();

  factory CurrencyCatalogService() => _singleton;

  CurrencyCatalogService._internal();

  List<CurrencyModel> _currencies = const [];

  /// By code: every price cell of a sheet asks for its own.
  Map<String, CurrencyModel> _byCode = const {};

  /// The whole catalog, in the order the backend sends it (legal tender first,
  /// each group alphabetical). It's the order they're offered in: what almost
  /// everyone will pick can't end up under what almost no one does.
  List<CurrencyModel> get currencies => List.unmodifiable(_currencies);

  /// Only legal tender, for forms that don't offer crypto.
  List<CurrencyModel> get fiat => [
    for (final currency in _currencies) if (!currency.isCrypto) currency
  ];

  /// Whether the catalog has arrived. A form looks at it to decide whether it
  /// can offer a list or has to let the code be written by hand.
  bool get isReady => _currencies.isNotEmpty;

  int get total => _currencies.length;

  /// The currency with that code, or `null` if the catalog doesn't have it.
  ///
  /// To write an amount use [resolve], which always returns one: here the
  /// `null` means "this currency can't be picked", which is another question.
  CurrencyModel? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return _byCode[code.trim().toUpperCase()];
  }

  /// The currency used to write an amount saved as [code]. **Always** returns
  /// one, because a price always has to be written:
  ///
  /// - The catalog one, if it exists.
  /// - One built with the saved code, if the catalog doesn't have it (see
  ///   [CurrencyModel.unknown]): `VES 22,23` is shown and not `$22,23`, because
  ///   putting another symbol on it would be lying about the data.
  /// - The app's one ([fallback]) when there's no code, which is the case of a
  ///   business that hasn't declared what it invoices in yet.
  CurrencyModel resolve(String? code) {
    final value = code?.trim().toUpperCase() ?? "";
    if (value.isEmpty) return fallback;

    return _byCode[value] ?? CurrencyModel.unknown(value);
  }

  /// The currency used when none is declared: the dollar if the catalog brings
  /// it —the normal case—, the first legal tender one if not, and only then one
  /// built by hand.
  CurrencyModel get fallback =>
    _byCode[_kDefaultCurrency] ??
    (fiat.isNotEmpty ? fiat.first : CurrencyModel.unknown(_kDefaultCurrency));

  /// Populates the catalog with what `/init` brought.
  ///
  /// It notifies even if called before the tree is mounted —there's no one
  /// listening and it costs nothing— because it's also called by the catalog
  /// re-read with the app already running (see [ClientService.refreshCatalogs]):
  /// if a currency changed its symbol, the open price cells have to find out.
  void seed(dynamic data) {
    _currencies = CurrencyModel.fromResponse(data);
    _byCode = {for (final currency in _currencies) currency.code: currency};

    notifyListeners();
  }

  /// Empties the catalog. For sign out, along with the rest of the services:
  /// the next session brings it back, and it may come back different.
  void clear() {
    _currencies = const [];
    _byCode = const {};

    notifyListeners();
  }
}
