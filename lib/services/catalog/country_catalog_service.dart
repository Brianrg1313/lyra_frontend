import 'package:flutter/foundation.dart';

import 'package:app/services/catalog/country_model.dart';

/// The countries where the platform operates.
///
/// It's one of the two platform catalogs that arrive in `/init` (the other is
/// [CurrencyCatalogService]) and is populated from there, in [ClientService.resolve],
/// before the tree is mounted: by the time the first screen is painted it's
/// already loaded and no form has to wait on a future.
///
/// It's a singleton because the catalog is a single one for the whole app and
/// isn't anyone's: it doesn't depend on the active business —changing business
/// doesn't change what countries the platform operates in— nor on any screen's
/// lifecycle. It's also registered in `initialBuilder` with
/// `ChangeNotifierProvider.value` so it can be observed with `context.watch`,
/// and for that same reason the provider must not destroy it.
///
/// The point of this being a catalog and not an enum: enabling a region is a
/// row in `lyra_admin`.`countries`, and the app offers it on the next read of
/// `/init` —without publishing a new version—. That's why no one should write a
/// country list here, nor assume a code exists.
///
/// ```dart
/// // To offer them in a form.
/// final countries = context.watch<CountryCatalogService>().countries;
///
/// // To read a saved code.
/// final name = CountryCatalogService().nameOf(profile.country);
/// ```
class CountryCatalogService extends ChangeNotifier {
  //SINGLETON
  static final CountryCatalogService _singleton =
    CountryCatalogService._internal();

  factory CountryCatalogService() => _singleton;

  CountryCatalogService._internal();

  List<CountryModel> _countries = const [];

  /// By code, to avoid walking the list on every read: a business card and each
  /// row of a listing ask for their own.
  Map<String, CountryModel> _byCode = const {};

  /// The whole catalog, in the order the backend sends it (alphabetical by the
  /// name of each country in its own language).
  List<CountryModel> get countries => List.unmodifiable(_countries);

  /// Whether the catalog has arrived. It's what a form looks at to decide
  /// whether it can offer a list or has to let the code be written by hand:
  /// without a catalog, an empty dropdown leaves the data with no way to be
  /// loaded.
  bool get isReady => _countries.isNotEmpty;

  int get total => _countries.length;

  /// The country with that code, or `null` if the catalog doesn't have it (it
  /// hasn't arrived yet, or the region was disabled).
  CountryModel? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return _byCode[code.trim().toUpperCase()];
  }

  /// How a saved code is read: the country name, or the raw code if the
  /// catalog doesn't have it.
  ///
  /// Returning the code and not an empty text is on purpose: the data belongs
  /// to the business, and hiding it because this app doesn't know how to name
  /// it would be showing an incomplete card.
  String nameOf(String? code) =>
    byCode(code)?.name ?? code?.trim().toUpperCase() ?? "";

  /// The national currency of a country, to propose it when it's picked. Empty
  /// if the country isn't known.
  String currencyOf(String? code) => byCode(code)?.currency ?? "";

  /// The country a saved phone belongs to (`+584121234567` is Venezuela), or
  /// `null` if it doesn't start with `+` or no enabled code matches.
  ///
  /// The longest matching code wins and not the first: `+1` is the United
  /// States and Canada, but `+1868` is neither. It's the only way to split a
  /// phone without asking anyone where it's from.
  CountryModel? byPhone(String? phone) {
    final digits = phone?.trim() ?? "";
    if (!digits.startsWith("+")) return null;

    final number = digits.substring(1);
    CountryModel? match;

    for (final country in _countries) {
      if (country.phone.isEmpty) continue;
      if (!number.startsWith(country.phone)) continue;
      if (match != null && match.phone.length >= country.phone.length) continue;

      match = country;
    }

    return match;
  }

  /// A saved phone split into the two things loaded separately: the country
  /// code and the number.
  ///
  /// What isn't recognized stays whole in the number —a phone loaded without a
  /// code, or one from a disabled region—: it's shown as it's saved instead of
  /// being attributed to a country nobody picked.
  ({String dial, String number}) splitPhone(String? phone) {
    final value = phone?.trim() ?? "";
    final country = byPhone(value);

    if (country == null) return (dial: "", number: value);

    return (
      dial: country.phone,
      number: value.substring(country.phone.length + 1)
    );
  }

  /// Populates the catalog with what `/init` brought.
  ///
  /// It notifies even if called before the tree is mounted —there's no one
  /// listening and it costs nothing— because it's also called by the catalog
  /// re-read with the app already running (see [ClientService.refreshCatalogs]),
  /// and at that moment the open screens have to find out.
  void seed(dynamic data) {
    _countries = CountryModel.fromResponse(data);
    _byCode = {for (final country in _countries) country.code: country};

    notifyListeners();
  }

  /// Empties the catalog. For sign out, along with the rest of the services:
  /// the next session brings it back, and it may come back different.
  void clear() {
    _countries = const [];
    _byCode = const {};

    notifyListeners();
  }
}
