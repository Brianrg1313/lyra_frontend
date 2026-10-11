/// Bodies of the branch writes (`POST` / `PUT /business/branches/`).
///
/// The owning business does not go in any body: it travels in the
/// `business_id` header of every request. `COUNTRY` is never sent: the
/// backend ignores it, every branch has the company's.
library;

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';

/// Everything the branch form collects, as typed. [phone] already carries its
/// country code (`+584121234567`) or is empty.
class BranchDraft {
  const BranchDraft({
    required this.name,
    this.main = false,
    this.storefront = true,
    this.online = true,
    this.legalName = "",
    this.taxId = "",
    this.series = "",
    this.phone = "",
    this.address = "",
    this.landmark = "",
    this.city = "",
    this.region = "",
    this.postalCode = "",
    this.point
  });

  final String name;
  final bool main;
  final bool storefront;
  final bool online;
  final String legalName;
  final String taxId;

  /// The sales' number prefix, as typed (stored uppercase).
  final String series;
  final String phone;
  final String address;
  final String landmark;
  final String city;
  final String region;
  final String postalCode;
  final LatLng? point;
}

/// Builds the body that opens a branch.
///
/// What was left empty is not sent, so the backend keeps its defaults
/// (`LEGAL_NAME`/`TAX_ID` the company's). The flags always travel: the form
/// shows them set, and what is shown is what is stored.
Map<String, dynamic> createBranchRequest(BranchDraft draft) => {
  "NAME": _clean(draft.name),
  "STOREFRONT": draft.storefront,
  "ONLINE": draft.online,
  if (draft.main) "MAIN": true,
  ..._filled("LEGAL_NAME", draft.legalName),
  ..._filled("TAX_ID", draft.taxId),
  ..._filled("SERIES", draft.series.toUpperCase()),
  ..._filled("PHONE", draft.phone.replaceAll(" ", "")),
  ..._filled("ADDRESS", draft.address),
  ..._filled("LANDMARK", draft.landmark),
  ..._filled("CITY", draft.city),
  ..._filled("REGION", draft.region),
  ..._filled("POSTAL_CODE", draft.postalCode.toUpperCase()),
  // The pair travels together or not at all, at six decimals like the
  // column (about 11 cm).
  if (draft.point != null) ...{
    "LATITUDE": _fixed(draft.point!.latitude),
    "LONGITUDE": _fixed(draft.point!.longitude)
  }
};

/// Builds the edit body of [from] with **only what changed**, plus its `ID`.
/// A body with the `ID` alone means there is nothing to save.
///
/// A text emptied travels as `""`, which the backend reads as "erase it" and
/// then the company's own value applies again. `MAIN` only ever travels as
/// `true`: the flag is moved to a branch, never taken off one.
Map<String, dynamic> editBranchRequest({
  required BusinessBranchModel from,
  required BranchDraft draft
}) {
  final body = <String, dynamic>{"ID": from.id};

  void text(String key, String value, String current) {
    final next = _clean(value);
    if (next != current) body[key] = next;
  }

  text("NAME", draft.name, from.name);
  text("LEGAL_NAME", draft.legalName, from.legalName);
  text("TAX_ID", draft.taxId, from.taxId);
  text("SERIES", draft.series.toUpperCase(), from.series);
  text("PHONE", draft.phone.replaceAll(" ", ""), from.phone);
  text("ADDRESS", draft.address, from.address);
  text("LANDMARK", draft.landmark, from.landmark);
  text("CITY", draft.city, from.city);
  text("REGION", draft.region, from.region);
  // Stored uppercased: sending it again only because of its case would be a
  // write that changes nothing.
  text("POSTAL_CODE", draft.postalCode.toUpperCase(), from.postalCode);

  if (draft.storefront != from.storefront) body["STOREFRONT"] = draft.storefront;
  if (draft.online != from.online) body["ONLINE"] = draft.online;
  if (draft.main && !from.main) body["MAIN"] = true;

  final point = draft.point;
  final had = from.latitude != null && from.longitude != null;

  if (point == null) {
    if (had) {
      body["LATITUDE"] = "";
      body["LONGITUDE"] = "";
    }
  } else if (!had ||
      _fixed(point.latitude) != _fixed(from.latitude!) ||
      _fixed(point.longitude) != _fixed(from.longitude!)) {
    body["LATITUDE"] = _fixed(point.latitude);
    body["LONGITUDE"] = _fixed(point.longitude);
  }

  return body;
}

Map<String, String> _filled(String key, String value) {
  final text = _clean(value);
  return text.isEmpty ? const {} : {key: text};
}

/// A text as the backend stores it: trimmed, with its runs of spaces made one.
String _clean(String value) => value.replaceAll(RegExp(r"\s+"), " ").trim();

/// As text with the six decimals the column keeps: a double written by Dart
/// can come out in exponent form (`1e-7`), which the backend refuses.
String _fixed(double value) => value.toStringAsFixed(6);
