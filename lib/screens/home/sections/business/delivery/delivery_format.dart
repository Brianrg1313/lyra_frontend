import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';

/// How the figures of the delivery tab are written.
///
/// Nothing the backend stores about delivery is a sentence: codes, and numbers
/// in one unit each —the company's currency, kilometres, minutes—. This is
/// where they become one, in the language the screen is read in. The amount
/// is the exception and is written the way the **currency** writes it (see
/// `CurrencyModel`): a price belongs to whoever charges it.

/// What an option is called on screen. The shop's own riders with no name of
/// their own are called what they are.
String deliveryOptionName(BuildContext context, DeliveryOption option) =>
  option.name.isNotEmpty ? option.name : S.of(context).business_delivery_own_default;

/// An amount in the company's currency, whole (`$3.00`, `Bs. 4,50`).
String deliveryAmount(double value, String currency) =>
  CurrencyCatalogService().resolve(currency).label(value.toString()) ??
    value.toStringAsFixed(2);

/// What an option costs. No fixed price is said in words and not left out:
/// "the price varies" is an answer too, and the one a customer needs before
/// asking.
String deliveryFeeLabel(BuildContext context, double? fee, String currency) {
  if (fee == null) return S.of(context).business_delivery_fee_varies;
  if (fee == 0) return S.of(context).business_delivery_fee_free;

  return deliveryAmount(fee, currency);
}

/// How long an option takes (`30–60 min`, `1–3 days`, `Up to 2 h`), or `""`
/// when the company did not say.
///
/// A span is written in the largest unit both ends are whole numbers of, so
/// `1440–4320` reads as days and not as four-digit minutes.
String deliveryEtaLabel(BuildContext context, int? min, int? max) {
  if (min == null && max == null) return "";

  if (min != null && max != null && min != max) {
    final unit = DeliveryEtaUnit.fit([min, max]);

    return unit.span(context, min ~/ unit.factor, max ~/ unit.factor);
  }

  if (min != null && max != null) return _time(context, min);

  if (min != null) {
    return S.of(context).business_delivery_eta_from(_time(context, min));
  }

  return S.of(context).business_delivery_eta_up_to(_time(context, max!));
}

/// How far a local option reaches from the company's location.
String deliveryRadiusLabel(BuildContext context, double km) =>
  S.of(context).business_delivery_radius(deliveryNumber(km));

/// The first zones of a local option, each with its own price when it has
/// one, and how many more there are. A list of a hundred areas is read in the
/// panel that edits it, not in a tag.
String deliveryZonesLabel(
  BuildContext context,
  List<DeliveryZone> zones,
  String currency
) {
  const shown = 3;

  final names = [
    for (final zone in zones.take(shown))
      zone.fee == null
        ? zone.name
        : "${zone.name} (${deliveryAmount(zone.fee!, currency)})"
  ].join(", ");

  final rest = zones.length - shown;

  return rest > 0
    ? "$names ${S.of(context).business_delivery_zones_more(rest)}"
    : names;
}

/// A number without the zeros that pad it: `5`, `2.5`.
String deliveryNumber(double value) =>
  value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "");

String _time(BuildContext context, int minutes) {
  final unit = DeliveryEtaUnit.fit([minutes]);

  return unit.write(context, minutes ~/ unit.factor);
}
