import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/catalog/catalog_table.dart';

/// Where the active company delivers, drawn on the map, exactly as
/// `GET /business/delivery/areas/` returns it.
///
/// An area is a **shape**, not a name: the zones of a delivery option are the
/// company's words ("Chacao"), which a person reads but nothing can measure an
/// address against. A shape is what decides whether a customer's point is
/// inside, with no map provider involved (the backend's `Geometry`).
///
/// Both maps come in one list: the areas every branch serves ([DeliveryArea.branch]
/// `null`) and each branch's own. [scope] says which of the two is in force;
/// the other is kept, so switching back finds the drawings where they were.
class DeliveryAreasModel {
  const DeliveryAreasModel({
    this.currency = "",
    this.scope = DeliveryScope.global,
    this.areas = const []
  });

  /// ISO 4217 code every fee and minimum is written in.
  final String currency;

  /// Which areas decide where the company delivers.
  final DeliveryScope scope;

  /// In the order the company arranged them, both maps.
  final List<DeliveryArea> areas;

  /// Takes the answer as an object (`{currency, scope, areas}`) or as the bare list.
  factory DeliveryAreasModel.fromJson(dynamic json) {
    final rows = json is Map ? json["areas"] : json;

    return DeliveryAreasModel(
      currency: json is Map ? _text(json["currency"]).toUpperCase() : "",
      scope: json is Map ? DeliveryScope.from(json["scope"]) : DeliveryScope.global,
      areas: [for (final row in catalogRows(rows)) ?DeliveryArea.from(row)]
    );
  }

  /// The areas of one map: the shared one when [branch] is `null`, else that
  /// branch's.
  List<DeliveryArea> of(String? branch) =>
    [for (final area in areas) if (area.branch == branch) area];

  /// The areas in force: the shared map under [DeliveryScope.global], under
  /// [DeliveryScope.branch] those of a branch still in [branches] (an archived
  /// branch's areas stop counting with it). The backend's `DeliveryAreas.inForce`.
  List<DeliveryArea> inForce(Iterable<String> branches) {
    if (scope == DeliveryScope.global) return of(null);

    final live = branches.toSet();

    return [for (final area in areas) if (area.branch != null && live.contains(area.branch)) area];
  }

  /// The active areas holding [point], cheapest first.
  ///
  /// It is what the probe on the map says, and only that: whether an order is
  /// taken is the backend's answer. Cheapest first because it is the rule the
  /// delivery apps follow where two areas overlap (the customer pays the
  /// lowest fee), and an area with no fee of its own is the option's price,
  /// which is not known here, so it goes last.
  List<DeliveryArea> holding(LatLng point) => areas
    .where((area) => area.active && area.contains(point))
    .toList()
    ..sort((a, b) => (a.fee ?? double.infinity).compareTo(b.fee ?? double.infinity));
}

/// Which drawn areas are in force, `companies.delivery_scope` in the backend.
enum DeliveryScope {
  /// One map every branch serves: an order leaves from the closest branch
  /// (the closest with the products, once stock is kept per branch).
  global,

  /// Each branch its own map: an order leaves from the branch whose area
  /// holds the customer.
  branch;

  /// Anything but `branch` is the default, as in the backend.
  static DeliveryScope from(dynamic code) =>
    code?.toString().trim().toLowerCase() == "branch" ? branch : global;

  /// Code that travels to the backend.
  String get value => name;
}

/// The branch an order to [point] would leave from, as the backend's
/// `Coverage.dispatcher` decides it: under [DeliveryScope.branch] the owner of
/// the cheapest area in force holding it; otherwise, or when no branch's area
/// holds it, the closest branch on the map in a straight line, among those
/// that take channel orders when there are any. `null` when no branch has a
/// point.
///
/// It is what the probe on the map shows; the backend's answer is the one an
/// order is decided with.
BusinessBranchModel? deliveringBranch(
  LatLng point, {
  required DeliveryScope scope,
  required List<DeliveryArea> inForce,
  required List<BusinessBranchModel> branches
}) {
  final placed = [
    for (final branch in branches)
      if (branch.latitude != null && branch.longitude != null) branch
  ];

  if (scope == DeliveryScope.branch) {
    final owner = DeliveryAreasModel(areas: inForce).holding(point).firstOrNull?.branch;

    for (final branch in placed) {
      if (branch.id == owner) return branch;
    }
  }

  final online = [for (final branch in placed) if (branch.online) branch];
  final pool = online.isEmpty ? placed : online;

  BusinessBranchModel? closest;
  var best = double.infinity;

  for (final branch in pool) {
    final distance = const Distance().distance(LatLng(branch.latitude!, branch.longitude!), point);

    if (distance < best) {
      best = distance;
      closest = branch;
    }
  }

  return closest;
}

/// How an area's shape is given.
///
/// There are two and not three: an area "15 minutes by motorcycle" is drawn
/// from the routing engine's answer and saved as the polygon the company
/// confirmed. The backend decides with geometry, never with a route (a route
/// changes with the engine and its data; a shape the company saw does not).
enum DeliveryAreaKind {
  /// A circle around a point, "5 km from the store".
  radius,

  /// Any shape, drawn point by point.
  polygon;

  static DeliveryAreaKind? from(dynamic code) =>
    switch (code?.toString().trim().toLowerCase()) {
      "radius" => radius,
      "polygon" => polygon,
      _ => null
    };

  /// Code that travels to the backend.
  String get value => name;
}

/// How the courier moves, for an area drawn by travel time. The codes are the
/// routing contract's (`TravelMode` in `/scorpius`).
enum DeliveryTravelMode {
  motorcycle,
  car,
  bicycle,
  foot;

  String get value => name;

  IconData get icon => switch (this) {
    motorcycle => CI.delivery,
    car => CI.delivery_square,
    bicycle => CI.delivery,
    foot => CI.user
  };

  String label(BuildContext context) => switch (this) {
    motorcycle => S.of(context).deliveries_area_mode_motorcycle,
    car => S.of(context).deliveries_area_mode_car,
    bicycle => S.of(context).deliveries_area_mode_bicycle,
    foot => S.of(context).deliveries_area_mode_foot
  };
}

/// One area the company delivers to.
class DeliveryArea {
  const DeliveryArea({
    required this.id,
    this.branch,
    required this.name,
    required this.kind,
    this.center,
    this.radius,
    this.points = const [],
    this.fee,
    this.minimum,
    this.active = true,
    this.position = 100
  });

  /// Public uuid: what an edit and a removal name it by.
  final String id;

  /// The branch that delivers to it; `null` is an area every branch serves.
  final String? branch;

  final String name;
  final DeliveryAreaKind kind;

  /// Middle of a [DeliveryAreaKind.radius] area. `null` for a polygon.
  final LatLng? center;

  /// Kilometres from [center] a radius area reaches.
  final double? radius;

  /// Outline of a [DeliveryAreaKind.polygon] area, open (the last point is
  /// not the first repeated). Empty for a radius.
  final List<LatLng> points;

  /// What delivering here costs the customer. `null` is "the price of the way
  /// it is delivered", which the delivery options already say.
  final double? fee;

  /// Order total below which the company does not deliver here.
  final double? minimum;

  /// A paused area is kept, drawn apart, and reaches nobody: a company that
  /// stops delivering somewhere for a week does not have to draw it again.
  final bool active;

  final int position;

  /// Whether [point] is inside.
  bool contains(LatLng point) => switch (kind) {
    DeliveryAreaKind.radius => center != null && radius != null &&
      const Distance().distance(center!, point) <= radius! * 1000,
    DeliveryAreaKind.polygon => ringContains(points, point)
  };

  /// Every point the area touches the edge of the map with, to fit it on
  /// screen: the outline, or the circle's four extremes.
  List<LatLng> get bounds {
    if (kind == DeliveryAreaKind.polygon) return points;

    final middle = center;
    final km = radius;

    if (middle == null || km == null) return const [];

    const distance = Distance();

    return [
      for (final bearing in const [0.0, 90.0, 180.0, 270.0])
        distance.offset(middle, km * 1000, bearing)
    ];
  }

  /// Surface in square kilometres. It is how two areas are compared at a
  /// glance ("12 km²" against "3 km²"), not a figure anything is charged by.
  double get squareKm => switch (kind) {
    DeliveryAreaKind.radius => radius == null ? 0 : math.pi * radius! * radius!,
    DeliveryAreaKind.polygon => ringSquareKm(points)
  };

  static DeliveryArea? from(Map<String, dynamic> row) {
    final id = _text(row["id"]);
    final kind = DeliveryAreaKind.from(row["kind"]);

    if (id.isEmpty || kind == null) return null;

    final latitude = _number(row["latitude"]);
    final longitude = _number(row["longitude"]);

    final branch = _text(row["branch"]);

    return DeliveryArea(
      id: id,
      branch: branch.isEmpty ? null : branch,
      name: _text(row["name"]),
      kind: kind,
      center: latitude == null || longitude == null
        ? null
        : LatLng(latitude, longitude),
      radius: _number(row["radius"]),
      points: readRing(row["polygon"]),
      fee: _number(row["fee"]),
      minimum: _number(row["minimum"]),
      active: row["active"] == null ||
        row["active"] == true ||
        row["active"] == 1 ||
        row["active"].toString() == "1" ||
        row["active"].toString().toLowerCase() == "true",
      position: _number(row["position"])?.round() ?? 100
    );
  }
}

/// An outline as the backend sends it: `[latitude, longitude]` pairs (the
/// shape `/scorpius` answers rings in) or `{latitude, longitude}` objects. A
/// closing point equal to the first is dropped, so every ring here is open.
List<LatLng> readRing(dynamic raw) {
  if (raw is! List) return const [];

  final ring = <LatLng>[];

  for (final entry in raw) {
    final latitude = _number(entry is List && entry.length >= 2
      ? entry[0]
      : entry is Map ? entry["latitude"] ?? entry["LATITUDE"] : null);
    final longitude = _number(entry is List && entry.length >= 2
      ? entry[1]
      : entry is Map ? entry["longitude"] ?? entry["LONGITUDE"] : null);

    if (latitude == null || longitude == null) continue;
    if (latitude.abs() > 90 || longitude.abs() > 180) continue;

    ring.add(LatLng(latitude, longitude));
  }

  if (ring.length > 1 && ring.first == ring.last) ring.removeLast();

  return ring;
}

/// Whether [point] lies inside an open [ring] (ray casting, even-odd): the
/// same arithmetic the backend decides with (`Geometry.contains`), so the
/// probe on the map and the backend's answer agree.
bool ringContains(List<LatLng> ring, LatLng point) {
  if (ring.length < 3) return false;

  var inside = false;

  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];

    if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
        point.longitude < (b.longitude - a.longitude) *
          (point.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude) {
      inside = !inside;
    }
  }

  return inside;
}

/// Surface of an open ring in square kilometres (shoelace on an
/// equirectangular projection around its middle). Precise enough for a city,
/// which is what an area is.
double ringSquareKm(List<LatLng> ring) {
  if (ring.length < 3) return 0;

  const kmPerDegree = 111.32;

  final middle = ring.map((point) => point.latitude).reduce((a, b) => a + b) / ring.length;
  final squeeze = math.cos(middle * math.pi / 180);

  var sum = 0.0;

  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].longitude * kmPerDegree * squeeze;
    final yi = ring[i].latitude * kmPerDegree;
    final xj = ring[j].longitude * kmPerDegree * squeeze;
    final yj = ring[j].latitude * kmPerDegree;

    sum += xj * yi - xi * yj;
  }

  return sum.abs() / 2;
}

/// Points one outline may have. The backend's own ceiling
/// (`DeliveryAreas.#maxPoints` in lyra), which it checks on the list as it
/// arrives: one point over and the whole area is refused.
const int maxRingPoints = 250;

/// Fewer points for the same outline (Douglas–Peucker), keeping every point
/// that bends it by more than [tolerance] degrees (≈ 55 m at the default),
/// and never more than [limit] of them.
///
/// A travel-time area comes back from the routing engine with hundreds of
/// points; the company edits it by dragging them, and nobody drags three
/// hundred handles.
///
/// [limit] is not a truncation: cutting the tail off a ring leaves a shape
/// open where it was cut. The tolerance is raised until the whole outline
/// fits, which loses the smallest bends first and keeps it closed.
List<LatLng> simplifyRing(
  List<LatLng> ring, {
  double tolerance = 0.0005,
  int? limit
}) {
  var simple = _simplifyRing(ring, tolerance);

  if (limit == null) return simple;

  // Each round drops the bends under twice the gap of the last one. It ends:
  // _simplifyRing gives back 4 points at most once the tolerance covers the
  // whole ring, and a limit under that is not an outline to begin with.
  for (var step = tolerance; simple.length > limit && limit >= 4; ) {
    step *= 2;
    simple = _simplifyRing(ring, step);
  }

  return simple;
}

List<LatLng> _simplifyRing(List<LatLng> ring, double tolerance) {
  if (ring.length <= 4) return ring;

  final keep = List<bool>.filled(ring.length, false)
    ..[0] = true
    ..[ring.length - 1] = true;
  final stack = <(int, int)>[(0, ring.length - 1)];

  while (stack.isNotEmpty) {
    final (from, to) = stack.removeLast();
    var farthest = -1;
    var distance = 0.0;

    for (var i = from + 1; i < to; i++) {
      final gap = _offLine(ring[i], ring[from], ring[to]);

      if (gap > distance) {
        distance = gap;
        farthest = i;
      }
    }

    if (farthest != -1 && distance > tolerance) {
      keep[farthest] = true;
      stack
        ..add((from, farthest))
        ..add((farthest, to));
    }
  }

  return [for (var i = 0; i < ring.length; i++) if (keep[i]) ring[i]];
}

/// Distance in degrees from [point] to the segment [a]–[b].
double _offLine(LatLng point, LatLng a, LatLng b) {
  final dx = b.longitude - a.longitude;
  final dy = b.latitude - a.latitude;
  final length = dx * dx + dy * dy;

  final t = length == 0
    ? 0.0
    : (((point.longitude - a.longitude) * dx + (point.latitude - a.latitude) * dy) / length)
        .clamp(0.0, 1.0);

  final x = a.longitude + t * dx - point.longitude;
  final y = a.latitude + t * dy - point.latitude;

  return math.sqrt(x * x + y * y);
}

String _text(dynamic value) => value?.toString().trim() ?? "";

/// DECIMAL columns reach the client as numbers or as strings, depending on the
/// database driver behind the endpoint.
double? _number(dynamic value) {
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString().trim() ?? "");
}
