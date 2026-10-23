import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/screens/home/sections/business/settings/profile_action.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/methods/method_flow_panel.dart';
import 'package:app/screens/home/sections/deliveries/methods/method_list.dart';
import 'package:app/screens/home/sections/deliveries/methods/state/method_flow.dart';
import 'package:app/screens/home/sections/deliveries/methods/state/rates_draft.dart';

/// The delivery methods in the desk's panel: the Methods view (what the
/// company has, pickup) and the steps a new method takes there — who carries
/// it, its price and time, and where it delivers.
///
/// The one that must not drift is the middle state: "not set yet" is neither
/// yes nor no, and a panel that drew a blank as "No" would be showing the
/// opposite of what the backend answers.

/// A source that answers [answer] and keeps what was written to it.
class _Source implements DeliverySource {
  _Source(this.answer);

  BusinessDeliveryModel answer;

  final List<Map<String, dynamic>> edits = [];
  final List<Map<String, dynamic>> created = [];
  final List<Map<String, dynamic>> updated = [];

  @override
  Future<BusinessDeliveryModel> delivery() async => answer;

  @override
  Future<DeliveryCatalog> providers() async => const DeliveryCatalog(
    country: "VE",
    providers: [
      DeliveryProvider(code: "pedidos_ya", name: "PedidosYa", kind: DeliveryMode.platform),
      DeliveryProvider(code: "zoom", name: "Zoom", kind: DeliveryMode.courier)
    ]
  );

  @override
  Future<void> editDelivery(Map<String, dynamic> request) async => edits.add(request);

  @override
  Future<void> createOption(Map<String, dynamic> request) async => created.add(request);

  @override
  Future<void> updateOption(Map<String, dynamic> request) async => updated.add(request);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The panel's two states as the desk swaps them: the Methods view, or the
/// flow once started. [done] counts the flows ended on their last step.
Future<MethodFlow> _pump(WidgetTester tester, _Source source, {List<int>? done, String? ownName, AreaEditor? editor}) async {
  final service = BusinessDeliveryService(source: source);
  final flow = MethodFlow();

  addTearDown(flow.dispose);

  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: ChangeNotifierProvider<BusinessDeliveryService>.value(
      value: service,
      child: Builder(builder: (context) {
        AppSize.instance(context);

        return Scaffold(body: SizedBox(
          width: 420,
          child: ListenableBuilder(
            listenable: flow,
            builder: (context, _) => flow.isOpen
              ? MethodFlowPanel(
                  flow: flow,
                  areas: (context) => const Center(child: TextSmall("the areas list")),
                  ownName: ownName,
                  editor: editor,
                  reachFrom: editor == null ? null : _branchPoint,
                  reachBranch: editor == null ? null : "b1",
                  onDone: () {
                    done?.add(1);
                    flow.close();
                  }
                )
              : MethodList(onEdit: flow.edit)
          )
        ));
      })
    )
  ));

  await service.load();
  await service.loadCatalog();
  await tester.pumpAndSettle();

  return flow;
}

/// Where the reach of an own delivery is measured from in these tests.
const LatLng _branchPoint = LatLng(10.5, -66.9);

/// One way of delivering, with every figure the row can draw.
const DeliveryOption _riders = DeliveryOption(
  id: "a1",
  mode: DeliveryMode.own,
  coverage: DeliveryCoverage.local,
  fee: 0,
  etaMin: 30,
  etaMax: 60,
  radius: 5,
  zones: [DeliveryZone(name: "Chacao")]
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets("a method is read by its name and its figures", (tester) async {
    await _pump(tester, _Source(const BusinessDeliveryModel(
      delivers: true,
      currency: "USD",
      options: [_riders]
    )));

    expect(tester.takeException(), isNull);
    // The shop's own riders with no name of their own are called what they are.
    expect(find.text("Own riders"), findsOneWidget);
    expect(find.text("Free"), findsOneWidget);
    expect(find.text("30–60 min"), findsOneWidget);
  });

  testWidgets("pickup not said is drawn as neither yes nor no", (tester) async {
    await _pump(tester, _Source(const BusinessDeliveryModel(currency: "USD")));

    expect(find.text("Not set yet"), findsOneWidget);
    expect(find.text("No"), findsNothing);
  });

  testWidgets("a new method starts with who carries it, and nothing else on screen", (tester) async {
    final flow = await _pump(tester, _Source(const BusinessDeliveryModel(currency: "USD")));

    flow.start();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("How do you deliver?"), findsOneWidget);
    expect(find.text("1 of 3"), findsOneWidget);
    expect(find.text("Your own deliveries"), findsOneWidget);
    expect(find.text("Delivery apps"), findsOneWidget);
    expect(find.text("Parcel services"), findsOneWidget);
    expect(find.text("PedidosYa"), findsOneWidget);
    expect(find.text("Zoom"), findsOneWidget);
    // What the company has is the Methods view's, not this step's.
    expect(find.text("Pickup at the business"), findsNothing);
  });

  testWidgets("a card opens its form: no fixed time for the company's own riders, it is measured", (tester) async {
    final flow = await _pump(tester, _Source(const BusinessDeliveryModel(currency: "USD")));

    flow.start();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Kind and form: how far they go is in the form, so there is no areas step.
    expect(find.text("2 of 2"), findsOneWidget);
    // The kind was picked on the card: the form does not ask it again.
    expect(find.text("Who carries it"), findsNothing);
    expect(find.textContaining("Time until it arrives"), findsNothing);
    expect(find.text("Arrival time"), findsOneWidget);
    expect(find.textContaining("Calculated for each order"), findsOneWidget);
  });

  testWidgets("a new own delivery is local, turns delivery back on, and is done: no areas step", (tester) async {
    final source = _Source(const BusinessDeliveryModel(delivers: false, currency: "USD"));
    final done = <int>[];
    final flow = await _pump(tester, source, done: done);

    flow.start();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, hasLength(1));
    expect(source.created.single["MODE"], "own");
    // Said, not left to the mode's default (a courier's would be national).
    expect(source.created.single["COVERAGE"], "local");
    expect(source.created.single.containsKey("RADIUS"), isFalse);
    // Measured per order: no time is kept.
    expect(source.created.single.containsKey("ETA_MIN"), isFalse);
    expect(source.edits, [deliveryFlagRequest(DeliveryFlag.delivers, true)]);

    expect(flow.isOpen, isFalse);
    expect(find.text("the areas list"), findsNothing);
  });

  test("an app or a carrier still goes on to the areas once saved", () {
    final flow = MethodFlow();
    addTearDown(flow.dispose);

    flow.start();
    flow.pick(DeliveryMode.platform);
    expect(flow.steps, 3);
    flow.saved();
    expect(flow.step, MethodStep.areas);

    flow.start();
    flow.pick(DeliveryMode.own);
    expect(flow.steps, 2);
    flow.saved();
    expect(flow.isOpen, isFalse);
  });

  testWidgets("an edit is one step, and erases the radius and zones the areas replace", (tester) async {
    final source = _Source(const BusinessDeliveryModel(delivers: true, currency: "USD", options: [_riders]));
    await _pump(tester, source);

    await tester.tap(find.byWidgetPredicate((widget) => widget is ProfileAction && widget.message == "Edit"));
    await tester.pumpAndSettle();

    expect(find.textContaining(" of 3"), findsNothing);

    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.updated, hasLength(1));
    expect(source.updated.single["RADIUS"], isNull);
    expect(source.updated.single["ZONES"], isEmpty);
    expect(source.created, isEmpty);
    // Back on the list, not on to the areas.
    expect(find.text("Where do you deliver?"), findsNothing);
  });

  /// Opens the own delivery's form of a new method; with [editor], its reach
  /// is shaped on that map from [_branchPoint].
  Future<_Source> own(WidgetTester tester, {String? ownName, AreaEditor? editor}) async {
    final source = _Source(const BusinessDeliveryModel(delivers: true, currency: "USD"));
    final flow = await _pump(tester, source, ownName: ownName, editor: editor);

    flow.start();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();

    return source;
  }

  /// Turns the [index]th row of the prices (Monday to Friday, the weekend,
  /// holidays) to a price, and types [amount] in it.
  Future<void> price(WidgetTester tester, int index, String amount) async {
    final paid = find.text("Price").at(index);

    await tester.ensureVisible(paid);
    await tester.tap(paid);
    await tester.pumpAndSettle();

    final fields = find.byWidgetPredicate((widget) => widget is Input && widget.placeholder.startsWith("In "));
    await tester.enterText(find.descendant(of: fields.last, matching: find.byType(EditableText)), amount);
    await tester.pumpAndSettle();
  }

  testWidgets("own delivery: named after where it is added, what it rides, and a price per run of days", (tester) async {
    await own(tester, ownName: "Sede Centro");

    expect(tester.takeException(), isNull);
    expect(find.text("Sede Centro"), findsOneWidget);
    expect(find.text("Motorcycle"), findsOneWidget);
    expect(find.text("Van or truck"), findsOneWidget);
    expect(find.text("Price per day"), findsOneWidget);
    // Weekdays and the weekend, not seven rows.
    expect(find.text("Monday to Friday"), findsOneWidget);
    expect(find.text("Saturday and Sunday"), findsOneWidget);
    expect(find.text("Monday"), findsNothing);
    expect(find.text("Holidays"), findsOneWidget);
    // Free until said otherwise, and holidays as usual.
    expect(find.text("Free"), findsNWidgets(3));
    expect(find.text("As usual"), findsOneWidget);
    // One price for every day is the rates' to say.
    expect(find.text("Price · optional"), findsNothing);
  });

  testWidgets("free on weekdays, 5 on weekends and holidays travels as the rates", (tester) async {
    final source = await own(tester);

    await tester.tap(find.text("Motorcycle"));
    await tester.pumpAndSettle();
    await price(tester, 1, "5");
    await price(tester, 2, "5,5");
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, hasLength(1));
    expect(source.created.single["VEHICLE"], "motorcycle");
    // Sunday first, as the backend counts them.
    expect(source.created.single["RATES"], {"DAYS": [5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0], "HOLIDAY": 5.5});
    expect(source.created.single.containsKey("FEE"), isFalse);
  });

  testWidgets("an own delivery takes a minimum order, and the card says it", (tester) async {
    final source = await own(tester);

    final field = find.byWidgetPredicate((widget) => widget is Input && widget.placeholder == "Order total below which you don't deliver");
    await tester.ensureVisible(field);
    await tester.enterText(find.descendant(of: field, matching: find.byType(EditableText)), "20");
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created.single["MINIMUM"], 20.0);
  });

  testWidgets("a method with a minimum order shows it", (tester) async {
    await _pump(tester, _Source(const BusinessDeliveryModel(
      delivers: true,
      currency: "USD",
      options: [DeliveryOption(id: "a2", mode: DeliveryMode.own, fee: 2, minimum: 15)]
    )));

    expect(tester.takeException(), isNull);
    expect(find.textContaining("Min. order"), findsOneWidget);
  });

  testWidgets("a run with a price and none written is not saved", (tester) async {
    final source = await own(tester);

    await price(tester, 0, "");
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, isEmpty);
  });

  testWidgets("how far they go is shaped on the map and saved with the method", (tester) async {
    final editor = AreaEditor(map: MapController());
    addTearDown(editor.dispose);

    final source = await own(tester, editor: editor);

    expect(tester.takeException(), isNull);
    expect(editor.reach, isTrue);
    expect(find.text("How far they go"), findsOneWidget);
    expect(find.text("Road distance"), findsOneWidget);

    // A circle around the branch opens it; 5 km picked.
    await tester.ensureVisible(find.text("5 km"));
    await tester.tap(find.text("5 km"));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created.single["REACH"], {"KIND": "radius", "VALUE": 5.0, "BRANCH": "b1"});
  });

  testWidgets("a travel time not measured yet is not saved", (tester) async {
    final editor = AreaEditor(map: MapController());
    addTearDown(editor.dispose);

    final source = await own(tester, editor: editor);

    await tester.ensureVisible(find.text("Travel time"));
    await tester.tap(find.text("Travel time"));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, isEmpty);
    expect(find.text("Measure it on the map first, or pick another way."), findsWidgets);
  });

  testWidgets("a way left and picked again keeps its figure's field alive", (tester) async {
    final editor = AreaEditor(map: MapController());
    addTearDown(editor.dispose);

    await own(tester, editor: editor);

    for (final way in ["Travel time", "Road distance", "Around", "Travel time", "Around"]) {
      await tester.ensureVisible(find.text(way));
      await tester.tap(find.text(way));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.ensureVisible(find.text("5 km"));
    await tester.tap(find.text("5 km"));
    await tester.pumpAndSettle();

    expect(editor.radius, 5.0);
  });

  testWidgets("a price hidden by Free can be asked for again", (tester) async {
    final source = await own(tester);

    await price(tester, 0, "4");

    final free = find.text("Free").at(0);
    await tester.ensureVisible(free);
    await tester.tap(free);
    await tester.pumpAndSettle();
    await price(tester, 0, "4");

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created.single["RATES"], {"DAYS": [0.0, 4.0, 4.0, 4.0, 4.0, 4.0, 0.0], "HOLIDAY": null});
  });

  test("an own delivery from before the rates opens with its one price every day", () {
    final draft = RatesDraft.of(const DeliveryOption(id: "a1", mode: DeliveryMode.own, fee: 3));
    addTearDown(draft.dispose);

    expect([for (final group in draft.groups) group.weekdays], RatesDraft.standard);
    expect(draft.groups.every((group) => group.draft.charge == RateCharge.paid && group.draft.price.value == "3"), isTrue);
    expect(draft.holiday.charge, RateCharge.same);
    expect(draft.read().rates?.request, {"DAYS": [3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0], "HOLIDAY": null});

    // A price emptied is a price forgotten, not a free day: its days are named.
    draft.groups.first.draft.price.textController.text = "";
    expect(draft.read().rates, isNull);
    expect(draft.read().missing, [1, 2, 3, 4, 5]);
    expect(draft.read().invalid, isFalse);
    draft.groups.first.draft.price.textController.text = "1.500";
    expect(draft.read().invalid, isTrue);
  });

  test("the runs split where the hours change, and where a saved price already differs", () {
    // Sunday closed, Saturday short: three runs and not the weekend whole.
    const week = ["", "9:00–18:00", "9:00–18:00", "9:00–18:00", "9:00–18:00", "9:00–18:00", "9:00–13:00"];
    expect(RatesDraft.spans(week), [[1, 2, 3, 4, 5], [6], [0]]);
    // The same hours every day are still weekdays and weekend.
    expect(RatesDraft.spans(List.filled(7, "9:00–18:00")), RatesDraft.standard);

    final draft = RatesDraft.of(const DeliveryOption(
      id: "a1",
      mode: DeliveryMode.own,
      rates: DeliveryRates(days: [5, 0, 0, 0, 0, 2, 5])
    ));
    addTearDown(draft.dispose);

    expect([for (final group in draft.groups) group.weekdays], [[1, 2, 3, 4], [5], [6, 0]]);

    draft.regroup(RatesDraft.spans(week));
    expect([for (final group in draft.groups) group.weekdays], [[1, 2, 3, 4], [5], [6], [0]]);
    expect(draft.read().rates?.days, [5.0, 0.0, 0.0, 0.0, 0.0, 2.0, 5.0]);
  });

  test("the rates, the vehicle and the reach are read as the backend answers them", () {
    final option = DeliveryOption.from({
      "id": "a1",
      "mode": "own",
      "vehicle": "van",
      "rates": {"days": [5, 0, 0, 0, 0, 0, "5.50"], "holiday": null},
      "reach": {"kind": "road", "value": "15.0", "branch": "b1", "polygon": [[10.5, -66.9], [10.6, -66.9], [10.6, -66.8]]}
    })!;

    expect(option.vehicle, DeliveryVehicle.van);
    expect(option.vehicle?.travel, DeliveryTravelMode.car);
    expect(option.rates?.days, [5, 0, 0, 0, 0, 0, 5.5]);
    expect(option.rates?.holiday, isNull);
    expect(option.reach?.kind, DeliveryReachKind.road);
    expect(option.reach?.value, 15);
    expect(option.reach?.points, hasLength(3));
    expect(option.reach?.request, {
      "KIND": "road",
      "VALUE": 15.0,
      "BRANCH": "b1",
      "POLYGON": [[10.5, -66.9], [10.6, -66.9], [10.6, -66.8]]
    });
    // An app or a carrier keeps none of them.
    expect(createDeliveryOptionRequest(
      mode: DeliveryMode.platform,
      label: "App",
      vehicle: DeliveryVehicle.car,
      rates: option.rates,
      reach: option.reach
    ).keys, isNot(anyOf(contains("RATES"), contains("REACH"))));
  });

  test("the meeting point travels as a two-state flag", () {
    expect(deliveryMeetingRequest(true), {"MEETING_POINT": true});
    expect(deliveryMeetingRequest(false), {"MEETING_POINT": false});
  });

  testWidgets("turned off, it still lists what it keeps, faded, and pickup is not", (tester) async {
    await _pump(tester, _Source(const BusinessDeliveryModel(
      delivers: false,
      pickup: true,
      currency: "USD",
      options: [_riders]
    )));

    double opacity(Finder finder) => tester
      .widgetList<AnimatedOpacity>(find.ancestor(of: finder, matching: find.byType(AnimatedOpacity)))
      .fold(1.0, (value, widget) => value * widget.opacity);

    expect(find.textContaining("Delivery is turned off"), findsOneWidget);
    expect(find.text("Turn on"), findsOneWidget);
    expect(opacity(find.text("Own riders")), lessThan(1));
    expect(opacity(find.text("Pickup at the business")), 1);
  });
}
