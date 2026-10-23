import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show Grant, PermissionCatalog;
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_request.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipment_request.dart';
import 'package:app/services/shipments/shipments_service.dart';
import 'package:app/screens/home/sections/deliveries/shipments/shipment_list.dart';

/// The deliveries board of a branch (`envios-frontend.md`): rows read from the compressed list
/// with their nested carrier, window and destination; a state this app doesn't know is no row;
/// a write sends only what changed (empty takes it off); `shipment/changed` replaces a row,
/// drops one that left the view or the board, and places a new one in window order; the
/// branch's week is written whole with its services' rows; the list says what is going.
Map<String, dynamic> _row(String id, {String state = "unassigned", Map<String, dynamic>? window, String sale = "charged"}) => {
  "id": id,
  "ticket": "28AF-$id",
  "number": "A-00012$id",
  "state": state,
  "label": state == "unassigned" ? "Por asignar" : state,
  "attention": state == "unassigned",
  "sale": sale,
  "customer": "Ana",
  "contact": "+58 412",
  "chat": "chat-$id",
  "total": 40,
  "fee": 3.5,
  "cost": null,
  "currency": "USD",
  "window": window,
  "carrier": null,
  "destination": {"area": "Chacao", "place": null, "address": "Av. 1", "latitude": 10.5, "longitude": -66.9, "maps": "https://maps.example/?q=10.5,-66.9"},
  "note": null,
  "receiver": null,
  "history": [{"state": "unassigned", "label": "Por asignar", "at": "2026-10-13T12:00:00.000Z"}],
  "opened": "2026-10-13T12:00:00.000Z",
  "updated": "2026-10-13T12:00:00.000Z",
  "stored": false
};

Map<String, dynamic> _compressed(List<Map<String, dynamic>> rows) {
  final keys = rows.first.keys.toList();

  return {
    "total": rows.length,
    "shipments": {"keys": keys, "values": [for (final row in rows) [for (final key in keys) row[key]]]}
  };
}

void main() {
  group("Shipment", () {
    test("reads the compressed board with its nested parts, and drops an unknown state", () {
      final rows = Shipment.list(_compressed([
        _row("1", window: {"from": "2026-10-14T13:00:00.000Z", "to": "2026-10-14T15:00:00.000Z"}, sale: "open"),
        _row("2", state: "teleported")
      ]));

      expect(rows, hasLength(1));

      final shipment = rows.single;
      expect(shipment.state, ShipmentState.unassigned);
      expect(shipment.name, "A-000121");
      expect(shipment.charged, isFalse);
      expect(shipment.attention, isTrue);
      expect(shipment.fee, 3.5);
      expect(shipment.cost, isNull);
      expect(shipment.window!.from, DateTime.utc(2026, 10, 14, 13).toLocal());
      expect(shipment.destination.hasPoint, isTrue);
      expect(shipment.destination.area, "Chacao");
      expect(shipment.history.single.state, ShipmentState.unassigned);
      expect(shipment.stored, isFalse);
    });

    test("en_route is a state, and a carrier reads as a rider or a provider", () {
      final row = Shipment.read({
        ..._row("3", state: "en_route"),
        "carrier": {"mode": "platform", "employment": null, "provider": "yummy", "reference": "Y-9", "name": "Yummy"}
      })!;

      expect(row.state, ShipmentState.enRoute);
      expect(row.carrier!.isRider, isFalse);
      expect(CarrierChoice.of(row.carrier), const CarrierChoice.provider("yummy", reference: "Y-9"));
    });

    test("an event with state null names the shipment that left the board", () {
      expect(Shipment.leftBoard({"id": "9", "state": null}), "9");
      expect(Shipment.leftBoard(_row("9")), isNull);
    });

    test("the states' catalog says where each may go", () {
      final catalog = ShipmentStateInfo.catalog({"states": {
        "keys": ["state", "name", "attention", "next"],
        "values": [["delivered", "Entregado", false, ["en_route"]], ["lost", "?", false, []]]
      }});

      expect(catalog.keys, [ShipmentState.delivered]);
      expect(catalog[ShipmentState.delivered]!.next, [ShipmentState.enRoute]);
    });
  });

  group("requests", () {
    final shipment = Shipment.read(_row("1"))!;

    test("nothing changed is no request", () {
      expect(editShipmentRequest(shipment, carrier: const CarrierChoice.none(), note: "", receiver: ""), isNull);
    });

    test("a rider, a window and a cost travel; only they do", () {
      final from = DateTime.utc(2026, 10, 14, 13);
      final body = editShipmentRequest(
        shipment,
        carrier: const CarrierChoice.rider("77"),
        window: ShipmentWindow(from: from, to: from.add(const Duration(hours: 2))),
        cost: 2.5,
        note: ""
      )!;

      expect(body, {
        "ID": "1",
        "EMPLOYMENT": "77",
        "FROM": "2026-10-14T13:00:00.000Z",
        "TO": "2026-10-14T15:00:00.000Z",
        "COST": 2.5
      });
    });

    test("taking the carrier, the window and the cost off sends them empty", () {
      final assigned = Shipment.read({
        ..._row("1", state: "assigned", window: {"from": "2026-10-14T13:00:00.000Z", "to": "2026-10-14T15:00:00.000Z"}),
        "carrier": {"mode": "own", "employment": "77", "name": "Luis"},
        "cost": 4
      })!;

      expect(editShipmentRequest(assigned, carrier: const CarrierChoice.none(), clearWindow: true, clearCost: true), {
        "ID": "1",
        "EMPLOYMENT": "",
        "FROM": "",
        "TO": "",
        "COST": ""
      });
    });

    test("a provider travels with its reference", () {
      expect(editShipmentRequest(shipment, carrier: const CarrierChoice.provider("yummy", reference: " Y-9 ")), {
        "ID": "1",
        "PROVIDER": "yummy",
        "REFERENCE": "Y-9"
      });
    });

    test("an address travels with the point it keeps", () {
      expect(editShipmentRequest(shipment, address: "Calle 2"), {
        "ID": "1",
        "ADDRESS": "Calle 2",
        "LATITUDE": 10.5,
        "LONGITUDE": -66.9
      });
    });

    test("a move names the state's code", () {
      expect(shipmentStateRequest(shipment, ShipmentState.enRoute), {"ID": "1", "STATE": "en_route"});
    });

    test("settings send only what changed; no limit is empty", () {
      expect(
        shippingSettingsRequest(const ShippingSettings(capacity: 4), const ShippingSettings(span: 60)),
        {"SPAN": 60, "CAPACITY": ""}
      );
    });
  });

  group("the board", () {
    ShipmentsService seeded() => ShipmentsService()..seed([
      Shipment.read(_row("1", window: {"from": "2026-10-14T13:00:00.000Z", "to": "2026-10-14T15:00:00.000Z"}))!,
      Shipment.read(_row("2"))!
    ]);

    test("an event replaces its row", () {
      final service = seeded();

      service.receiveEvent({..._row("2", state: "assigned"), "carrier": {"mode": "own", "employment": "77"}});

      expect(service.byId("2")!.state, ShipmentState.assigned);
      service.dispose();
    });

    test("delivered leaves the going view; state null leaves the board", () {
      final service = seeded();

      service.receiveEvent(_row("1", state: "delivered"));
      expect(service.byId("1"), isNull);

      service.receiveEvent({"id": "2", "state": null});
      expect(service.shipments, isEmpty);
      expect(service.status, ShipmentsStatus.empty);
      service.dispose();
    });

    test("a new one with a window goes before those with none, in window order", () {
      final service = seeded();

      service.receiveEvent(_row("3", window: {"from": "2026-10-14T10:00:00.000Z", "to": "2026-10-14T11:00:00.000Z"}));

      expect([for (final row in service.shipments) row.id], ["3", "1", "2"]);
      service.dispose();
    });

    test("what the person may do is their grant's", () {
      final service = ShipmentsService()..seed(const [], grant: Grant(
        sections: PermissionCatalog.fromKeys(["shipments", "shipments.dispatch", "appointments", "appointments.configure"])
      ));

      expect(service.canDispatch, isTrue);
      expect(service.canConfigure, isFalse);
      expect(service.canSchedule, isTrue);
      service.dispose();
    });
  });

  group("opening hours", () {
    test("a time of day reads as minutes; 24:00 closes the day", () {
      expect(OpeningStretch.minutes("09:30"), 570);
      expect(OpeningStretch.minutes("930"), 570);
      expect(OpeningStretch.minutes("24:00"), 1440);
      expect(OpeningStretch.minutes("24:30"), isNull);
      expect(OpeningStretch.minutes("9:75"), isNull);
      expect(OpeningStretch.clock(570), "09:30");
    });

    test("the week is written whole, its services' rows kept", () {
      expect(setWeekRequest(
        "b1",
        const [OpeningStretch(weekday: 1, opens: 540, closes: 1080)],
        kept: const [OpeningStretch(weekday: 6, opens: 540, closes: 720, service: "s1")]
      ), {
        "BRANCH": "b1",
        "HOURS": [
          {"WEEKDAY": 1, "OPENS": 540, "CLOSES": 1080},
          {"WEEKDAY": 6, "OPENS": 540, "CLOSES": 720, "SERVICE": "s1"}
        ]
      });
    });

    test("a day closed everywhere names no branch", () {
      expect(closeDayRequest("2026-12-25", reason: "Navidad"), {"DAY": "2026-12-25", "REASON": "Navidad"});
      expect(reopenDayRequest(const ClosedDay(day: "2026-12-25", branch: "b1")), {"DAY": "2026-12-25", "BRANCH": "b1"});
    });
  });

  group("the list", () {
    setUpAll(() {
      ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
      ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
    });

    Future<void> pump(WidgetTester tester, ShipmentsService service) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: ChangeNotifierProvider<ShipmentsService>.value(
          value: service,
          child: Builder(builder: (context) {
            AppSize.instance(context);

            return Scaffold(body: ShipmentList(onOpen: (_) {}));
          })
        )
      ));
      await tester.pump();
    }

    testWidgets("draws each shipment", (tester) async {
      final service = ShipmentsService()..seed([Shipment.read(_row("1"))!, Shipment.read(_row("2", sale: "open"))!]);

      await pump(tester, service);

      expect(find.text("A-000121"), findsOneWidget);
      expect(find.text("A-000122"), findsOneWidget);
      expect(find.text(S.current.shipments_going_count(2)), findsNothing);
      expect(find.textContaining(S.current.shipments_collect), findsOneWidget);
      service.dispose();
    });

    testWidgets("an empty board says where deliveries come from", (tester) async {
      final service = ShipmentsService()..seed(const []);

      await pump(tester, service);

      expect(find.text(S.current.shipments_empty), findsOneWidget);
      service.dispose();
    });
  });
}
