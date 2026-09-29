/// Bodies of the delivery writes: the general settings (`PUT
/// /business/delivery/`) and the ways the company delivers (`POST` / `PUT` /
/// `DELETE /business/delivery/options/`).
///
/// The owning business does not go in any body: it travels in the
/// `business_id` header of every request.
///
/// Amounts, distances and times travel as numbers the form already read
/// ([readDeliveryAmount]), never as the text that was typed: the backend takes
/// a decimal comma only where it cannot be a thousands separator, and a
/// `1,500` it had to refuse is better caught where it was written.
library;

import 'package:app/services/business/business_delivery_model.dart';

/// The two yes/no settings. Each is three-state (see `BusinessDeliveryModel`).
enum DeliveryFlag {
  delivers,
  pickup;

  String get key => name.toUpperCase();
}

/// Sets one of the flags. `null` puts it back to "has not said", which is not
/// "no" and is what a company that is not sure yet should have.
Map<String, dynamic> deliveryFlagRequest(DeliveryFlag flag, bool? value) =>
  {flag.key: value};

/// Sets whether a customer the company does not reach is offered a spot
/// halfway (flexible areas) or turned away (fixed areas). Two states: the
/// backend refuses an empty value, so it never travels as `null`.
Map<String, dynamic> deliveryMeetingRequest(bool value) =>
  {"MEETING_POINT": value};

/// Sets the company's sentence about delivery in general; empty erases it.
Map<String, dynamic> deliveryNotesRequest(String notes) =>
  {"NOTES": _orNull(notes)};

/// Builds the body that adds a way of delivering.
///
/// What was left empty is not sent: on a creation a missing key is the
/// backend's default — the mode's own reach, no price, no time.
///
/// [provider] is a catalog code, or empty for a carrier named by [label]
/// alone (and always for the shop's own riders). The zones and the radius
/// only travel for a local reach: a national courier with a list of
/// neighbourhoods beside it would read as a limit it does not have.
Map<String, dynamic> createDeliveryOptionRequest({
  required DeliveryMode mode,
  String provider = "",
  String label = "",
  DeliveryCoverage? coverage,
  double? radius,
  List<DeliveryZone> zones = const [],
  double? fee,
  double? freeFrom,
  int? etaMin,
  int? etaMax,
  String notes = ""
}) {
  final local = (coverage ?? mode.reach) == DeliveryCoverage.local;
  final carrier = mode.namesCarrier ? provider.trim() : "";

  return {
    "MODE": mode.value,
    if (carrier.isNotEmpty) "PROVIDER": carrier,
    if (label.trim().isNotEmpty) "LABEL": label.trim(),
    "COVERAGE": ?coverage?.value,
    if (local) "RADIUS": ?radius,
    if (local && zones.isNotEmpty) "ZONES": _zones(zones),
    "FEE": ?fee,
    "FREE_FROM": ?freeFrom,
    "ETA_MIN": ?etaMin,
    "ETA_MAX": ?etaMax,
    if (notes.trim().isNotEmpty) "NOTES": notes.trim()
  };
}

/// Builds the body that edits [from].
///
/// Everything the form draws travels, and what was emptied travels as `null`:
/// the backend writes only the keys it receives, so a missing key is "leave
/// it" and `null` is "erase it" — a price emptied is a price that varies.
///
/// **Except who carries it, which travels only when it changed.** A carrier is
/// checked against the catalog of the company's country *today*, so a company
/// that picked MRW and then moved could not fix a typo in its notes if the
/// form resent the MRW it already has.
Map<String, dynamic> updateDeliveryOptionRequest({
  required DeliveryOption from,
  required DeliveryMode mode,
  String provider = "",
  String label = "",
  DeliveryCoverage? coverage,
  double? radius,
  List<DeliveryZone> zones = const [],
  double? fee,
  double? freeFrom,
  int? etaMin,
  int? etaMax,
  String notes = ""
}) {
  final carrier = mode.namesCarrier ? provider.trim() : "";
  final moved = mode != from.mode || carrier != from.provider;
  final local = (coverage ?? from.coverage) == DeliveryCoverage.local;

  return {
    "ID": from.id,
    if (moved) "MODE": mode.value,
    if (moved) "PROVIDER": carrier.isEmpty ? null : carrier,
    "LABEL": _orNull(label),
    "COVERAGE": ?coverage?.value,
    // Off a local reach the backend drops both on its own, so they only travel
    // where they mean something. On one, an empty list clears the zones.
    if (local) "RADIUS": radius,
    if (local) "ZONES": _zones(zones),
    "FEE": fee,
    "FREE_FROM": freeFrom,
    "ETA_MIN": etaMin,
    "ETA_MAX": etaMax,
    "NOTES": _orNull(notes)
  };
}

/// Builds the body that removes a way of delivering. The row is soft-deleted
/// on the other side, and removing the last one does not change whether the
/// company says it delivers.
Map<String, dynamic> removeDeliveryOptionRequest(String id) => {"ID": id};

/// Reads an amount as it is typed: digits and at most two decimals, after a
/// dot or a comma, and nothing else.
///
/// It is stricter than a price field elsewhere in this app on purpose, and the
/// same as the backend: a comma is only a decimal mark when it cannot be a
/// thousands separator. `1,500` is refused rather than guessed — read as 1.5
/// it would quote a delivery a thousand times cheaper than the company meant.
///
/// `valid` is `false` when the text is not an amount; an empty text is a valid
/// "no amount" (`value` `null`).
({bool valid, double? value}) readDeliveryAmount(String raw) {
  final text = raw.trim();

  if (text.isEmpty) return (valid: true, value: null);

  if (!RegExp(r"^\d+(?:[.,]\d{1,2})?$").hasMatch(text)) {
    return (valid: false, value: null);
  }

  return (valid: true, value: double.parse(text.replaceAll(",", ".")));
}

/// Zones travel with their own price even when they have none (`FEE` null):
/// one shape for every entry is simpler to read on the other side than a list
/// mixing names and objects.
List<Map<String, dynamic>> _zones(List<DeliveryZone> zones) => [
  for (final zone in zones) {"NAME": zone.name.trim(), "FEE": zone.fee}
];

/// What a cleared text travels as: `null`, never `""`, which the backend's
/// rules would refuse as too short instead of reading it as "clear it".
String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();
