import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/catalog/catalog_table.dart';

/// Whether, how and where the active company delivers, exactly as
/// `GET /business/delivery/` returns it.
///
/// **[delivers] and [pickup] have three states, not two.** `null` is "the
/// company has not said", and it is not "no": an assistant that read a blank
/// as "we do not deliver" would turn away the customers of every shop that
/// simply never filled this in. A company that lists a way to deliver has said
/// yes by doing so, and the backend answers `true` for it without writing it
/// back. When [delivers] is `false` the [options] are still listed, switched
/// off, kept for when delivery is turned back on.
///
/// Every amount is in [currency] (the company's), distances in kilometres and
/// times in minutes. The texts are the company's own words and are shown as
/// they came.
class BusinessDeliveryModel {
  const BusinessDeliveryModel({
    this.delivers,
    this.pickup,
    this.notes = "",
    this.meeting = false,
    this.currency = "",
    this.options = const []
  });

  final bool? delivers;

  /// Whether a customer can collect the order at the company's location.
  final bool? pickup;

  /// The company's own sentence about delivery in general.
  final String notes;

  /// Whether a customer outside every drawn delivery area is offered the
  /// nearest spot the company does reach, to meet the courier there
  /// (`MEETING_POINT`). **Two states, off by default**: unlike [delivers], a
  /// blank here can only mean off — the assistant must never promise to meet
  /// a customer halfway on a guess. The spot is chosen by the backend on the
  /// company's own areas, so without areas it offers nothing.
  final bool meeting;

  /// ISO 4217 code every fee is written in.
  final String currency;

  /// Every way it delivers, in the order the company arranged them.
  final List<DeliveryOption> options;

  factory BusinessDeliveryModel.fromJson(Map json) => BusinessDeliveryModel(
    delivers: _flag(json["delivers"]),
    pickup: _flag(json["pickup"]),
    notes: _text(json["notes"]),
    meeting: _flag(json["meeting"]) ?? false,
    currency: _text(json["currency"]).toUpperCase(),
    options: [
      for (final row in catalogRows(json["options"])) ?DeliveryOption.from(row)
    ]
  );

  static bool? _flag(dynamic value) {
    if (value == null) return null;

    return value == true || value == 1 || value.toString() == "1" ||
      value.toString().toLowerCase() == "true";
  }
}

/// Who carries an order. A closed set because both of its readers act on it:
/// a customer asking "who brings it?" is answered differently for each, and a
/// fee is the company's to charge only when its own riders carry the order.
enum DeliveryMode {
  own,
  platform,
  courier;

  static DeliveryMode? from(dynamic code) =>
    switch (code?.toString().trim().toLowerCase()) {
      "own" => own,
      "platform" => platform,
      "courier" => courier,
      _ => null
    };

  /// Code that travels to the backend.
  String get value => name;

  /// The reach an option gets when the form does not say, which is the
  /// backend's own default: a shop's riders and a delivery app work a city, a
  /// parcel carrier works the country.
  DeliveryCoverage get reach =>
    this == courier ? DeliveryCoverage.national : DeliveryCoverage.local;

  /// Whether the option has to say which company carries it. The shop's own
  /// riders are the shop; "we send it by parcel" is not an answer to "with
  /// which company?", and the backend refuses it.
  bool get namesCarrier => this != own;

  IconData get icon => switch (this) {
    own => CI.delivery,
    platform => CI.shop_mobile,
    courier => CI.delivery_square
  };

  String label(BuildContext context) => switch (this) {
    own => S.of(context).business_delivery_mode_own,
    platform => S.of(context).business_delivery_mode_platform,
    courier => S.of(context).business_delivery_mode_courier
  };

  String description(BuildContext context) => switch (this) {
    own => S.of(context).business_delivery_mode_own_note,
    platform => S.of(context).business_delivery_mode_platform_note,
    courier => S.of(context).business_delivery_mode_courier_note
  };
}

/// What the company's own couriers ride (an own option only): what tells a
/// customer whether a fridge fits. [van] is any van or truck.
enum DeliveryVehicle {
  motorcycle,
  car,
  bicycle,
  van;

  static DeliveryVehicle? from(dynamic code) {
    final text = code?.toString().trim().toLowerCase();

    return values.where((vehicle) => vehicle.name == text).firstOrNull;
  }

  /// Code that travels to the backend.
  String get value => name;

  // The icon font has no vehicles.
  IconData get icon => switch (this) {
    motorcycle => Icons.two_wheeler_rounded,
    car => Icons.directions_car_rounded,
    bicycle => Icons.pedal_bike_rounded,
    van => Icons.local_shipping_rounded
  };

  /// How its trips are measured on the roads: a van or a truck goes where a
  /// car goes (the backend's `Delivery.travel`).
  DeliveryTravelMode get travel => switch (this) {
    motorcycle => DeliveryTravelMode.motorcycle,
    bicycle => DeliveryTravelMode.bicycle,
    car || van => DeliveryTravelMode.car
  };

  String label(BuildContext context) => switch (this) {
    motorcycle => S.of(context).business_delivery_vehicle_motorcycle,
    car => S.of(context).business_delivery_vehicle_car,
    bicycle => S.of(context).business_delivery_vehicle_bicycle,
    van => S.of(context).business_delivery_vehicle_van
  };
}

/// What the company's own delivery costs on each day, when it is not one
/// price every day: free from Monday to Friday and 5 on weekends.
///
/// The backend quotes the day the customer asks, in the company's zone, and a
/// national holiday of its country costs [holiday] over its weekday's.
class DeliveryRates {
  const DeliveryRates({required this.days, this.holiday});

  /// Seven prices by weekday, 0 Sunday to 6 Saturday (the weekdays of the
  /// opening hours). `0` is free; `null` is the option's `fee`.
  final List<double?> days;

  /// `null` is the weekday's price.
  final double? holiday;

  static DeliveryRates? from(dynamic raw) {
    if (raw is! Map || raw["days"] is! List || (raw["days"] as List).length != 7) return null;

    return DeliveryRates(
      days: [for (final day in raw["days"] as List) _number(day)],
      holiday: _number(raw["holiday"])
    );
  }

  /// The body's `RATES`.
  Map<String, dynamic> get request => {"DAYS": days, "HOLIDAY": holiday};
}

/// The four ways the company says how far its own couriers go.
enum DeliveryReachKind {
  /// A circle of kilometres around the branch.
  radius,

  /// As far as they get in some minutes.
  time,

  /// As far as some kilometres of road take them: 15 km of roads is not 15 km
  /// around, a river the roads go round is inside the circle.
  road,

  /// A shape drawn by hand.
  drawn;

  static DeliveryReachKind? from(dynamic code) {
    final text = code?.toString().trim().toLowerCase();

    return values.where((kind) => kind.name == text).firstOrNull;
  }
}

/// **How far the company's own couriers go** (an own option only), kept as
/// what can be measured: a circle ([value] km), or the [points] of the
/// outline the company confirmed on the map — never the request behind it,
/// since a route changes with the engine and a shape does not. The backend
/// decides that option with this alone (`basis: "outline"`).
class DeliveryReach {
  const DeliveryReach({required this.kind, this.value, this.branch, this.points = const []});

  final DeliveryReachKind kind;

  /// Kilometres ([DeliveryReachKind.radius], [DeliveryReachKind.road]) or
  /// minutes ([DeliveryReachKind.time]); `null` for a drawing.
  final double? value;

  /// The branch it was measured from, which the order leaves from when the
  /// outline holds the customer; `null` for whichever serves it.
  final String? branch;

  /// The outline; empty for a radius.
  final List<LatLng> points;

  static DeliveryReach? from(dynamic raw) {
    if (raw is! Map) return null;

    final kind = DeliveryReachKind.from(raw["kind"]);

    if (kind == null) return null;

    final branch = raw["branch"]?.toString() ?? "";

    return DeliveryReach(
      kind: kind,
      value: _number(raw["value"]),
      branch: branch.isEmpty ? null : branch,
      points: readRing(raw["polygon"])
    );
  }

  /// The body's `REACH`.
  Map<String, dynamic> get request => {
    "KIND": kind.name,
    "VALUE": value,
    "BRANCH": branch ?? "",
    if (kind != DeliveryReachKind.radius) "POLYGON": [
      for (final point in points) [point.latitude, point.longitude]
    ]
  };
}

/// How far an option reaches. It is what answers "do you ship to another
/// country?" once the customer's country is known.
enum DeliveryCoverage {
  local,
  national,
  international;

  static DeliveryCoverage? from(dynamic code) =>
    switch (code?.toString().trim().toLowerCase()) {
      "local" => local,
      "national" => national,
      "international" => international,
      _ => null
    };

  String get value => name;

  String label(BuildContext context) => switch (this) {
    local => S.of(context).business_delivery_coverage_local,
    national => S.of(context).business_delivery_coverage_national,
    international => S.of(context).business_delivery_coverage_international
  };

  String description(BuildContext context) => switch (this) {
    local => S.of(context).business_delivery_coverage_local_note,
    national => S.of(context).business_delivery_coverage_national_note,
    international => S.of(context).business_delivery_coverage_international_note
  };
}

/// An area a local option reaches, as the company names it. Free text on
/// purpose: there is no list of every neighbourhood in nine countries, and the
/// company knows its areas by the names its customers use.
class DeliveryZone {
  const DeliveryZone({required this.name, this.fee});

  final String name;

  /// Its own price when it differs from the option's. `null` is "the
  /// option's price".
  final double? fee;

  static DeliveryZone? from(dynamic raw) {
    final name = _text(raw is Map ? raw["name"] : raw);

    if (name.isEmpty) return null;

    return DeliveryZone(name: name, fee: raw is Map ? _number(raw["fee"]) : null);
  }
}

/// One way the company gets an order to a customer.
class DeliveryOption {
  const DeliveryOption({
    required this.id,
    required this.mode,
    this.provider = "",
    this.providerName = "",
    this.icon = "",
    this.label = "",
    this.coverage = DeliveryCoverage.local,
    this.radius,
    this.zones = const [],
    this.fee,
    this.freeFrom,
    this.etaMin,
    this.etaMax,
    this.notes = "",
    this.branch,
    this.position = 100,
    this.vehicle,
    this.rates,
    this.reach,
    this.minimum,
    this.onDelivery = true
  });

  /// Public uuid: what an edit and a removal name it by.
  final String id;

  final DeliveryMode mode;

  /// Code of the carrier in the platform's catalog (`pedidos_ya`, `mrw`).
  /// Empty for the shop's own riders and for a carrier the catalog does not
  /// list, which is named by [label] alone.
  final String provider;

  /// What that carrier is called: a brand, never translated. Resolved against
  /// the whole catalog, so a company that moved still reads the carrier it
  /// picked before.
  final String providerName;

  /// Platform asset id of the carrier's mark. Empty when it has none.
  final String icon;

  /// What the **company** calls this option ("Downtown riders"), and the
  /// whole name of a carrier the catalog does not list.
  final String label;

  final DeliveryCoverage coverage;

  /// Kilometres from the company's location it reaches (local only).
  final double? radius;

  /// Areas it reaches (local only).
  final List<DeliveryZone> zones;

  /// What it costs the customer. `0` is free; `null` is "not a fixed price"
  /// — the app or the carrier charges it, or it is quoted per order.
  final double? fee;

  /// Order total from which it costs nothing.
  final double? freeFrom;

  /// Fastest and slowest it arrives, in minutes.
  final int? etaMin;
  final int? etaMax;

  final String notes;

  /// The branch a national or international option leaves from (the warehouse that hands the
  /// order to the courier); null is whichever branch serves the order. A local option ignores
  /// it: there the map decides.
  final String? branch;

  final int position;

  /// What its couriers ride; own options only, `null` when it did not say.
  final DeliveryVehicle? vehicle;

  /// Its price per day; own options only, `null` is [fee] every day.
  final DeliveryRates? rates;

  /// How far its couriers go; own options only, `null` is what [radius] and
  /// the drawn areas say.
  final DeliveryReach? reach;

  /// Order total below which it is not delivered; own options only, `null`
  /// is none. A drawn area's own minimum outranks it where it has one.
  final double? minimum;

  /// Whether whoever carries it takes the payment when the order arrives (`on_delivery`):
  /// own riders and a platform's, on unless said; never a parcel courier, paid before it
  /// ships. An account is offered at the door only when it is marked too.
  final bool onDelivery;

  /// The carrier's brand: its catalog name, or its code when the catalog no
  /// longer knows it. Empty when the option names none.
  String get carrier => providerName.isNotEmpty ? providerName : provider;

  /// What the option is called on screen: the company's name for it, and the
  /// carrier's without one. Empty for the shop's own riders with no name,
  /// which the screen names itself.
  String get name => label.isNotEmpty ? label : carrier;

  /// The option in a row of `options`, or `null` when it is not one: a row
  /// without an id cannot be edited, and one with a mode this app does not
  /// know cannot be told apart from the others.
  static DeliveryOption? from(Map<String, dynamic> row) {
    final id = _text(row["id"]);
    final mode = DeliveryMode.from(row["mode"]);

    if (id.isEmpty || mode == null) return null;

    final zones = row["zones"];

    return DeliveryOption(
      id: id,
      mode: mode,
      provider: _text(row["provider"]),
      providerName: _text(row["provider_name"]),
      icon: _text(row["icon"]),
      label: _text(row["label"]),
      coverage: DeliveryCoverage.from(row["coverage"]) ?? mode.reach,
      radius: _number(row["radius"]),
      zones: zones is List
        ? [for (final zone in zones) ?DeliveryZone.from(zone)]
        : const [],
      fee: _number(row["fee"]),
      freeFrom: _number(row["free_from"]),
      etaMin: _number(row["eta_min"])?.round(),
      etaMax: _number(row["eta_max"])?.round(),
      notes: _text(row["notes"]),
      branch: _text(row["branch"]).isEmpty ? null : _text(row["branch"]),
      position: _number(row["position"])?.round() ?? 100,
      vehicle: DeliveryVehicle.from(row["vehicle"]),
      rates: DeliveryRates.from(row["rates"]),
      reach: DeliveryReach.from(row["reach"]),
      minimum: _number(row["minimum"]),
      onDelivery: mode != DeliveryMode.courier &&
        row["on_delivery"] != false && row["on_delivery"] != 0
    );
  }
}

/// A carrier the company may pick, from `GET /business/delivery/providers/`.
class DeliveryProvider {
  const DeliveryProvider({
    required this.code,
    required this.name,
    required this.kind,
    this.global = false,
    this.icon = ""
  });

  final String code;

  /// A brand, shown as it came.
  final String name;

  /// The mode an option naming this carrier has: the carrier decides it, so a
  /// picker only offers it under that mode.
  final DeliveryMode kind;

  /// Whether it works in every country and not only in the company's.
  final bool global;

  /// Platform asset id of its mark. Empty when it has none.
  final String icon;

  static DeliveryProvider? from(Map<String, dynamic> row) {
    final code = _text(row["code"]);
    final kind = DeliveryMode.from(row["kind"]);

    if (code.isEmpty || kind == null || kind == DeliveryMode.own) return null;

    final name = _text(row["name"]);

    return DeliveryProvider(
      code: code,
      name: name.isEmpty ? code : name,
      kind: kind,
      global: _text(row["scope"]).toLowerCase() == "global",
      icon: _text(row["icon"])
    );
  }
}

/// What the delivery form is built from: the modes and reaches an option can
/// have, and the carriers available in the company's country.
///
/// The carriers are offered per country exactly as payment rails are: a shop
/// in Caracas sees PedidosYa, Yummy, Zoom and MRW beside DHL, one in Mexico
/// City sees Rappi and Estafeta instead. A company that never said where it
/// operates gets the global carriers alone ([country] empty).
class DeliveryCatalog {
  const DeliveryCatalog({
    this.country = "",
    this.modes = DeliveryMode.values,
    this.coverages = DeliveryCoverage.values,
    this.providers = const []
  });

  final String country;
  final List<DeliveryMode> modes;
  final List<DeliveryCoverage> coverages;
  final List<DeliveryProvider> providers;

  /// The modes and reaches are the backend's codes and this app draws their
  /// names; a code it does not know is left out, and a list that did not come
  /// is every one this app knows.
  factory DeliveryCatalog.fromJson(Map json) {
    final modes = [
      for (final code in _list(json["modes"])) ?DeliveryMode.from(code)
    ];
    final coverages = [
      for (final code in _list(json["coverages"])) ?DeliveryCoverage.from(code)
    ];

    return DeliveryCatalog(
      country: _text(json["country"]).toUpperCase(),
      modes: modes.isEmpty ? DeliveryMode.values : modes,
      coverages: coverages.isEmpty ? DeliveryCoverage.values : coverages,
      providers: [
        for (final row in catalogRows(json["providers"]))
          ?DeliveryProvider.from(row)
      ]
    );
  }

  /// The carriers an option of [mode] can name.
  List<DeliveryProvider> of(DeliveryMode mode) =>
    providers.where((provider) => provider.kind == mode).toList();

  DeliveryProvider? byCode(String code) {
    for (final provider in providers) {
      if (provider.code == code) return provider;
    }

    return null;
  }

  static List _list(dynamic value) => value is List ? value : const [];
}

/// The unit a delivery time is typed and read in. Stored in minutes, always;
/// this is only how a person says it — "45 min", "2 h", "3 days".
enum DeliveryEtaUnit {
  minutes(1),
  hours(60),
  days(1440);

  const DeliveryEtaUnit(this.factor);

  /// Minutes in one of this unit.
  final int factor;

  /// The largest unit every one of [values] is a whole number of: `120` and
  /// `240` read in hours, `90` in minutes. Minutes when there are none.
  static DeliveryEtaUnit fit(Iterable<int> values) {
    for (final unit in [days, hours]) {
      if (values.isNotEmpty && values.every((value) => value % unit.factor == 0)) {
        return unit;
      }
    }

    return minutes;
  }

  String label(BuildContext context) => switch (this) {
    minutes => S.of(context).business_delivery_unit_minutes,
    hours => S.of(context).business_delivery_unit_hours,
    days => S.of(context).business_delivery_unit_days
  };

  /// One amount of time already written: `45 min`, `2 h`, `1 day`.
  String write(BuildContext context, int count) => switch (this) {
    minutes => S.of(context).business_delivery_eta_minutes(count),
    hours => S.of(context).business_delivery_eta_hours(count),
    days => S.of(context).business_delivery_eta_days(count)
  };

  /// A span already written: `30–60 min`, `1–3 days`.
  String span(BuildContext context, int from, int to) => switch (this) {
    minutes => S.of(context).business_delivery_eta_range_minutes(from, to),
    hours => S.of(context).business_delivery_eta_range_hours(from, to),
    days => S.of(context).business_delivery_eta_range_days(from, to)
  };
}

String _text(dynamic value) => value?.toString().trim() ?? "";

/// DECIMAL columns reach the client as numbers or as strings, depending on the
/// database driver behind the endpoint.
double? _number(dynamic value) {
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString().trim() ?? "");
}
