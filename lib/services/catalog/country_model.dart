// SERVICES
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';

import 'catalog_table.dart';

/// A country where the platform operates, as listed by `/init`.
///
/// The list belongs to the backend (`lyra_admin`.`countries`, only the enabled
/// ones) and not to this app: enabling a region is adding a row there, and the
/// app offers it in the next session without publishing a new version. That's
/// why none of this is an enum.
///
/// Each country brings what's needed to offer it and to fill in what's derived
/// from it: how it's called in its own language ([name]), its phone code
/// ([phone]), what currency it invoices in ([currency]) and its flag ([flag]).
class CountryModel {
  const CountryModel({
    required this.code,
    required this.name,
    this.phone = "",
    this.currency = "",
    this.flag = ""
  });

  /// ISO 3166-1 alpha-2 code, in uppercase. It's the value that travels to the
  /// backend (`companies`.`country`).
  final String code;

  /// Name of the country in its own language. Not translated: it arrives
  /// written.
  final String name;

  /// Phone code, without the `+`.
  final String phone;

  /// ISO 4217 code of its national currency. It's a suggestion for forms
  /// —picking a country proposes its currency—, not the business currency:
  /// that one is chosen by whoever creates it.
  final String currency;

  /// Id of the flag icon, or `""` if the country doesn't have one loaded yet.
  /// It's a platform file and not a business one, so it's downloaded from
  /// [FileScope.assets]; the address is built with [flagUrl].
  final String flag;

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    code: json["code"]?.toString().trim().toUpperCase() ?? "",
    name: json["name"]?.toString().trim() ?? "",
    phone: json["phone"]?.toString().trim() ?? "",
    currency: json["currency"]?.toString().trim().toUpperCase() ?? "",
    flag: json["flag"]?.toString().trim() ?? ""
  );

  /// The catalog countries, in the order the backend sends them (alphabetical
  /// by name). Those arriving without a code are discarded: the code is the
  /// data that travels, and an option that can't be saved isn't an option.
  static List<CountryModel> fromResponse(dynamic data) {
    final countries = <CountryModel>[];

    for (final row in catalogRows(data)) {
      final country = CountryModel.fromJson(row);
      if (country.code.isNotEmpty) countries.add(country);
    }

    return countries;
  }

  /// The phone code as it's written: `+58`. Empty if the country doesn't bring
  /// one.
  String get dial => phone.isEmpty ? "" : "+$phone";

  /// The flag address, or `""` if the country has none —or if the image base
  /// hasn't arrived yet—. Empty reads as "no flag", which is a valid answer:
  /// the country is offered all the same, by its name.
  ///
  /// [width] asks for a small version. A flag is drawn next to a row of text,
  /// so it's almost always worth asking for it.
  String flagUrl([int? width]) =>
    CdnService().url(FileScope.assets, flag, width: width);

  @override
  bool operator ==(Object other) =>
    other is CountryModel &&
    other.code == code &&
    other.name == name &&
    other.phone == phone &&
    other.currency == currency &&
    other.flag == flag;

  @override
  int get hashCode => Object.hash(code, name, phone, currency, flag);

  @override
  String toString() => "CountryModel($code)";
}
