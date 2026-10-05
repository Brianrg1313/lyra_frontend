import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/sources/delivery_lan_source.dart';
import 'package:app/services/lan/lan_service.dart';

/// The deliveries release on the app's side: what the master answers (as `lyra_node` sends it,
/// `lyra_node/test/deliveries_test.dart`) reaches the models the cloud's rows do, and the screens'
/// bodies reach the master in its keys, with money in minor units and distances in metres.
void main() {
  late _Master master;
  late DeliveryLanSource source;

  setUp(() {
    master = _Master();
    source = DeliveryLanSource(master);
  });

  test('the settings: three-state flags, options with amounts and kilometres', () async {
    master.answers[Ops.deliveryGet.name] = {
      "delivers": null, "pickup": true, "notes": "Hasta las 6", "meeting": false, "currency": "USD",
      "options": [{
        "id": "o-1", "mode": "courier", "provider": "mrw", "providerName": "MRW", "icon": null, "label": null,
        "coverage": "local", "radius": 5000, "zones": [{"name": "Chacao", "fee": 150}, {"name": "Altamira", "fee": null}],
        "fee": 250, "freeFrom": 3000, "etaMin": 30, "etaMax": 60, "notes": null, "position": 1,
      }],
    };

    final settings = await source.delivery();
    final option = settings.options.single;

    expect((settings.delivers, settings.pickup, settings.notes, settings.currency), (null, true, "Hasta las 6", "USD"));
    expect((option.mode, option.provider, option.carrier, option.coverage), (DeliveryMode.courier, "mrw", "MRW", DeliveryCoverage.local));
    expect((option.radius, option.fee, option.freeFrom, option.etaMin, option.etaMax), (5.0, 2.5, 30.0, 30, 60));
    expect([for (final zone in option.zones) (zone.name, zone.fee)], [("Chacao", 1.5), ("Altamira", null)]);
  });

  test('a write in the master\'s keys: money in minor units, the radius in metres, null kept', () async {
    await source.editDelivery(deliveryFlagRequest(DeliveryFlag.pickup, null));
    await source.editDelivery(deliveryMeetingRequest(true));
    await source.createOption(createDeliveryOptionRequest(
      mode: DeliveryMode.own, label: "Motorizados", radius: 2.5, fee: 1.25,
      zones: const [DeliveryZone(name: "Chacao", fee: 0.5)], etaMin: 20
    ));
    await source.removeOption("o-1");

    expect([for (final (op, args) in master.calls) [op, args]], [
      ["delivery.set", {"pickup": null}],
      ["delivery.set", {"meeting": true}],
      ["delivery.options.create", {
        "mode": "own", "label": "Motorizados", "radius": 2500, "zones": [{"name": "Chacao", "fee": 50}],
        "fee": 125, "etaMin": 20,
      }],
      ["delivery.options.remove", {"id": "o-1"}],
    ]);
  });

  test('an edit sends what the form draws, emptied figures as null', () async {
    const from = DeliveryOption(id: "o-1", mode: DeliveryMode.courier, provider: "mrw", coverage: DeliveryCoverage.national);

    await source.updateOption(updateDeliveryOptionRequest(from: from, mode: DeliveryMode.courier, provider: "mrw", fee: 3));

    expect([master.calls.single.$1, master.calls.single.$2], ["delivery.options.edit", {
      "id": "o-1", "label": null, "fee": 300, "freeFrom": null, "etaMin": null, "etaMax": null, "notes": null,
    }]);
  });

  test('the areas: a circle in kilometres, an outline of pairs, amounts', () async {
    master.answers[Ops.deliveryAreasList.name] = {"currency": "USD", "areas": [
      {"id": "a-1", "name": "Centro", "kind": "radius", "latitude": 10.48, "longitude": -66.87, "radius": 3000,
        "polygon": [], "fee": 200, "minimum": null, "active": true, "position": 100},
      {"id": "a-2", "name": "Este", "kind": "polygon", "latitude": null, "longitude": null, "radius": null,
        "polygon": [[10.5, -66.9], [10.5, -66.8], [10.4, -66.8]], "fee": null, "minimum": 1000, "active": false,
        "position": 101},
    ]};

    final areas = await source.areas();
    final [circle, outline] = areas.areas;

    expect(areas.currency, "USD");
    expect((circle.kind, circle.center, circle.radius, circle.fee), (DeliveryAreaKind.radius, const LatLng(10.48, -66.87), 3.0, 2.0));
    expect((outline.kind, outline.points.length, outline.minimum, outline.active), (DeliveryAreaKind.polygon, 3, 10.0, false));
  });

  test('an area\'s write: the outline as pairs, the radius in metres, pausing alone', () async {
    await source.createArea(createDeliveryAreaRequest(name: "Este", kind: DeliveryAreaKind.polygon, minimum: 10,
      points: const [LatLng(10.5, -66.9), LatLng(10.5, -66.8), LatLng(10.4, -66.8)]));
    await source.createArea(createDeliveryAreaRequest(name: "Centro", kind: DeliveryAreaKind.radius,
      center: const LatLng(10.48, -66.87), radius: 3, fee: 2));
    await source.updateArea(deliveryAreaActiveRequest(
      const DeliveryArea(id: "a-1", name: "Centro", kind: DeliveryAreaKind.radius), false));

    expect([for (final (op, args) in master.calls) [op, args]], [
      ["delivery.areas.create", {"name": "Este", "kind": "polygon",
        "polygon": [[10.5, -66.9], [10.5, -66.8], [10.4, -66.8]], "minimum": 1000}],
      ["delivery.areas.create", {"name": "Centro", "kind": "radius", "latitude": 10.48, "longitude": -66.87,
        "radius": 3000, "fee": 200}],
      ["delivery.areas.edit", {"id": "a-1", "active": false}],
    ]);
  });
}

class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final List<(String, Map<String, Object?>)> calls = [];

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));

    return answers[op.name];
  }
}
