import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_list.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_probe.dart';

/// Delivery areas: how they are read, whether a point is inside, what travels
/// to the backend, how a shape is made, and what the list draws.
///
/// The one that must not drift is "inside": the probe on the map uses the same
/// ray casting as the backend (`Geometry.contains`), and a probe that answered
/// differently would tell the company it delivers where it does not.

/// A square around Chacao, ~2 km a side.
const List<LatLng> _square = [
  LatLng(10.49, -66.86),
  LatLng(10.49, -66.84),
  LatLng(10.51, -66.84),
  LatLng(10.51, -66.86)
];

const LatLng _inside = LatLng(10.50, -66.85);
const LatLng _outside = LatLng(10.53, -66.85);

DeliveryArea _polygon({String id = "p", double? fee, bool active = true}) => DeliveryArea(
  id: id,
  name: "Chacao",
  kind: DeliveryAreaKind.polygon,
  points: _square,
  fee: fee,
  active: active
);

void main() {
  group("reading", () {
    test("rings come as pairs or as objects, and are kept open", () {
      final model = DeliveryAreasModel.fromJson({
        "currency": "usd",
        "areas": [
          {
            "id": "a",
            "name": "Chacao",
            "kind": "polygon",
            "polygon": [[10.49, -66.86], [10.49, -66.84], [10.51, -66.84], [10.49, -66.86]],
            "fee": "2.50",
            "active": 1
          },
          {
            "id": "b",
            "name": "Around",
            "kind": "radius",
            "latitude": "10.5",
            "longitude": -66.85,
            "radius": 3,
            "polygon": [{"latitude": 1, "longitude": 2}]
          },
          {"id": "", "kind": "polygon"},
          {"id": "c", "kind": "hexagon"}
        ]
      });

      expect(model.currency, "USD");
      expect(model.areas.map((area) => area.id), ["a", "b"]);
      expect(model.areas.first.points.length, 3);
      expect(model.areas.first.fee, 2.5);
      expect(model.areas.last.center, const LatLng(10.5, -66.85));
      expect(model.areas.last.active, isTrue);
    });

    test("the columnar answer is read by column name, not by position", () {
      // How the endpoint actually answers: `Response.parse` compresses the rows
      // into keys and values, and may reorder or add a column.
      final model = DeliveryAreasModel.fromJson({
        "currency": "usd",
        "areas": {
          "keys": ["kind", "id", "name", "polygon", "latitude", "longitude", "radius",
                   "fee", "minimum", "active", "position"],
          "values": [
            ["polygon", "a", "Zona sur", [[10.49, -66.86], [10.49, -66.84], [10.51, -66.84]],
             null, null, null, 4, 20, true, 110],
            ["radius", "b", "Cerca de la tienda", [], 10.4806, -66.9036, 5, null, null, false, 100]
          ]
        }
      });

      expect(model.areas.map((area) => area.name), ["Zona sur", "Cerca de la tienda"]);
      expect(model.areas.first.points, hasLength(3));
      expect(model.areas.first.minimum, 20);
      expect(model.areas.last.kind, DeliveryAreaKind.radius);
      expect(model.areas.last.radius, 5);
      expect(model.areas.last.fee, isNull);
      expect(model.areas.last.active, isFalse);
    });
  });

  group("inside", () {
    test("a polygon holds what is within its outline", () {
      expect(_polygon().contains(_inside), isTrue);
      expect(_polygon().contains(_outside), isFalse);
    });

    test("a radius holds what is within its kilometres", () {
      const area = DeliveryArea(
        id: "r",
        name: "Around",
        kind: DeliveryAreaKind.radius,
        center: _inside,
        radius: 2
      );

      // ~1.1 km north, and ~3.3 km north.
      expect(area.contains(const LatLng(10.51, -66.85)), isTrue);
      expect(area.contains(_outside), isFalse);
    });

    test("a paused area holds nobody, and the cheapest holding comes first", () {
      final model = DeliveryAreasModel(areas: [
        _polygon(id: "free-for-all"),
        _polygon(id: "paused", fee: 0, active: false),
        _polygon(id: "cheap", fee: 1),
        _polygon(id: "dear", fee: 3)
      ]);

      expect(
        model.holding(_inside).map((area) => area.id),
        ["cheap", "dear", "free-for-all"]
      );
      expect(model.holding(_outside), isEmpty);
    });

    test("a simplified outline keeps its corners", () {
      final dense = [
        for (var i = 0; i <= 20; i++) LatLng(10.49, -66.86 + i * 0.001),
        const LatLng(10.51, -66.84),
        const LatLng(10.51, -66.86)
      ];

      final simple = simplifyRing(dense);

      expect(simple.length, lessThan(dense.length));
      expect(simple, containsAll(_square));
      expect(ringSquareKm(simple), closeTo(ringSquareKm(_square), 0.01));
    });

    test("an outline is simplified until it fits, never cut short", () {
      // What a travel-time area comes back as: a crinkly ring of hundreds of
      // points. One over the backend's 250 and the whole area is refused.
      final crinkly = [
        for (var i = 0; i < 900; i++)
          LatLng(
            10.5 + 0.05 * math.sin(i * math.pi / 450) + (i.isEven ? 0.0006 : 0),
            -66.9 + 0.05 * math.cos(i * math.pi / 450)
          )
      ];

      final simple = simplifyRing(crinkly, limit: maxRingPoints);

      expect(simple.length, lessThanOrEqualTo(maxRingPoints));
      expect(simple.length, greaterThan(3));

      // Cutting the tail off would leave the ring open where it was cut: the
      // last point must still be the one that closes it.
      expect(simple.last, crinkly.last);
      expect(ringSquareKm(simple), closeTo(ringSquareKm(crinkly), 0.5));
    });
  });

  group("maps per branch", () {
    const north = "b-north";
    const south = "b-south";

    final model = DeliveryAreasModel.fromJson({
      "currency": "USD",
      "scope": "branch",
      "areas": [
        {"id": "all", "branch": null, "name": "Todas", "kind": "polygon", "polygon": [[10.49, -66.86], [10.49, -66.84], [10.51, -66.84]]},
        {"id": "n", "branch": north, "name": "Norte", "kind": "radius", "latitude": 10.5, "longitude": -66.85, "radius": 3, "fee": 5},
        {"id": "s", "branch": south, "name": "Sur", "kind": "radius", "latitude": 10.5, "longitude": -66.85, "radius": 3, "fee": 2},
        {"id": "gone", "branch": "b-archived", "name": "Vieja", "kind": "radius", "latitude": 10.5, "longitude": -66.85, "radius": 3}
      ]
    });

    BusinessBranchModel branch(String id, double latitude, double longitude, {bool online = true}) =>
      BusinessBranchModel.from({
        "id": id, "name": id, "main": false, "storefront": true, "online": online,
        "latitude": latitude, "longitude": longitude
      })!;

    test("each area names its map; the scope says which are in force, and an archived branch's drop out", () {
      expect(model.scope, DeliveryScope.branch);
      expect(model.of(null).map((area) => area.id), ["all"]);
      expect(model.of(north).map((area) => area.id), ["n"]);
      expect(model.inForce([north, south]).map((area) => area.id), ["n", "s"]);

      final shared = DeliveryAreasModel(scope: DeliveryScope.global, areas: model.areas);
      expect(shared.inForce([north, south]).map((area) => area.id), ["all"]);

      // Anything but "branch" is the shared map, as in the backend.
      expect(DeliveryAreasModel.fromJson({"scope": "city", "areas": []}).scope, DeliveryScope.global);
    });

    test("per branch, the owner of the cheapest area holding the point delivers; shared, the closest online branch", () {
      final branches = [
        branch(north, 10.60, -66.85),
        branch(south, 10.40, -66.85),
        branch("b-warehouse", 10.505, -66.85, online: false)
      ];
      final inForce = model.inForce([north, south]);

      expect(deliveringBranch(_inside, scope: DeliveryScope.branch, inForce: inForce, branches: branches)?.id, south);

      // Shared: the warehouse is closest but takes no channel orders.
      expect(deliveringBranch(const LatLng(10.58, -66.85), scope: DeliveryScope.global, inForce: const [], branches: branches)?.id, north);
      expect(deliveringBranch(_inside, scope: DeliveryScope.global, inForce: const [], branches: const []), isNull);
    });
  });

  group("requests", () {
    test("a new area names its branch only when it has one, and the scope travels as a setting", () {
      final shared = createDeliveryAreaRequest(name: "Todas", kind: DeliveryAreaKind.polygon, points: _square);
      final mine = createDeliveryAreaRequest(branch: "b-1", name: "Norte", kind: DeliveryAreaKind.polygon, points: _square);

      expect(shared.containsKey("BRANCH"), isFalse);
      expect(mine["BRANCH"], "b-1");
      expect(deliveryScopeRequest(DeliveryScope.branch), {"DELIVERY_SCOPE": "branch"});
    });

    test("a radius sends its middle and kilometres, and no outline", () {
      final body = createDeliveryAreaRequest(
        name: " Around ",
        kind: DeliveryAreaKind.radius,
        center: const LatLng(10.1234567, -66.1234564),
        radius: 3,
        points: _square
      );

      expect(body, {
        "NAME": "Around",
        "KIND": "radius",
        "LATITUDE": 10.123457,
        "LONGITUDE": -66.123456,
        "RADIUS": 3.0
      });
    });

    test("a polygon sends its outline, and an edit erases an emptied fee", () {
      final body = updateDeliveryAreaRequest(
        from: _polygon(fee: 2),
        name: "Chacao",
        kind: DeliveryAreaKind.polygon,
        points: _square
      );

      expect(body["ID"], "p");
      expect(body["POLYGON"], hasLength(4));
      expect((body["POLYGON"] as List).first, {"LATITUDE": 10.49, "LONGITUDE": -66.86});
      expect(body.containsKey("FEE"), isTrue);
      expect(body["FEE"], isNull);
      expect(body.containsKey("RADIUS"), isFalse);
    });
  });

  group("editor", () {
    test("a drawing is made point by point and undone as it was made", () {
      final editor = AreaEditor(map: MapController());

      editor.start(AreaMethod.draw, _inside);

      for (final point in _square.take(3)) {
        editor.tap(point);
      }

      expect(editor.hasShape, isTrue);

      editor.insertPoint(0, _inside);
      expect(editor.points[1], _inside);

      editor.undo();
      editor.undo();
      expect(editor.points.length, 2);
      expect(editor.hasShape, isFalse);
    });

    test("a radius moves its middle with a tap, and looking probes", () {
      final editor = AreaEditor(map: MapController());

      editor.start(AreaMethod.radius, _inside);
      editor.tap(_outside);

      expect(editor.center, _outside);
      expect(editor.points, isEmpty);

      editor.close();
      editor.tap(_inside);

      expect(editor.probe, _inside);
    });
  });

  group("list", () {
    setUpAll(() {
      ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
      ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
    });

    Widget app(DeliveryAreasModel areas, {LatLng? probe}) => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(builder: (context) {
        AppSize.instance(context);

        return Scaffold(body: AreaList(
          areas: areas.areas,
          colorOf: (_) => const Color(0xFF000000),
          currency: areas.currency,
          probe: probe == null ? null : AreaProbe(
            holding: areas.holding(probe),
            currency: areas.currency,
            colorOf: (_) => const Color(0xFF000000),
            from: "Sede Centro",
            onClear: () {}
          ),
          onFocus: (_) {},
          onEdit: (_) {},
          onToggle: (_) {},
          onRemove: (_) {}
        ));
      })
    );

    testWidgets("no areas says how to add one", (tester) async {
      await tester.pumpWidget(app(const DeliveryAreasModel()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("No areas yet"), findsOneWidget);
    });

    testWidgets("each area is read by its name, its shape and its figures", (tester) async {
      await tester.pumpWidget(app(DeliveryAreasModel(currency: "USD", areas: [
        _polygon(active: false),
        const DeliveryArea(
          id: "r",
          name: "Around",
          kind: DeliveryAreaKind.radius,
          center: _inside,
          radius: 3,
          fee: 0
        )
      ])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Chacao"), findsOneWidget);
      expect(find.text("Paused"), findsOneWidget);
      expect(find.text("Price of the delivery option"), findsOneWidget);
      expect(find.text("Free"), findsOneWidget);
      expect(find.textContaining("Within 3 km"), findsOneWidget);
    });

    testWidgets("a probed point says which areas reach it", (tester) async {
      await tester.pumpWidget(app(
        DeliveryAreasModel(areas: [_polygon()]),
        probe: _outside
      ));
      await tester.pumpAndSettle();

      expect(find.text("Outside your areas"), findsOneWidget);

      await tester.pumpWidget(app(
        DeliveryAreasModel(areas: [_polygon()]),
        probe: _inside
      ));
      await tester.pumpAndSettle();

      expect(find.text("Inside your areas"), findsOneWidget);
      expect(find.text("Leaves from Sede Centro"), findsOneWidget);
    });
  });
}
