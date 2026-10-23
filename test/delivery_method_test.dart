import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/button.dart';
import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/screens/home/sections/business/settings/profile_action.dart';
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
Future<MethodFlow> _pump(WidgetTester tester, _Source source, {List<int>? done, String? ownName}) async {
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

  testWidgets("a card opens its form: no reach to pick, and the time says what it counts", (tester) async {
    final flow = await _pump(tester, _Source(const BusinessDeliveryModel(currency: "USD")));

    flow.start();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("2 of 3"), findsOneWidget);
    // The kind was picked on the card: the form does not ask it again.
    expect(find.text("Who carries it"), findsNothing);
    // Every method is local: where it reaches is the areas on the map.
    expect(find.textContaining("How far it reaches"), findsNothing);
    expect(find.textContaining("Radius"), findsNothing);
    expect(find.textContaining("Time until it arrives"), findsOneWidget);
    expect(find.textContaining("From when the customer orders"), findsOneWidget);
  });

  testWidgets("a new method is local, turns delivery back on, and goes on to the areas", (tester) async {
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
    expect(source.edits, [deliveryFlagRequest(DeliveryFlag.delivers, true)]);

    expect(find.text("Where do you deliver?"), findsOneWidget);
    expect(find.text("3 of 3"), findsOneWidget);
    expect(find.text("the areas list"), findsOneWidget);

    // Pressed through the button: the "saved" flag floats over the panel's foot.
    tester.widget<Button>(find.widgetWithText(Button, "Done")).action();
    await tester.pumpAndSettle();

    expect(done, [1]);
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

  /// Opens the own delivery's form of a new method.
  Future<_Source> own(WidgetTester tester, {String? ownName}) async {
    final source = _Source(const BusinessDeliveryModel(delivers: true, currency: "USD"));
    final flow = await _pump(tester, source, ownName: ownName);

    flow.start();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();

    return source;
  }

  /// Turns the [index]th row of the prices (Monday first, holidays last) to a
  /// price, and types [amount] in it.
  Future<void> price(WidgetTester tester, int index, String amount) async {
    final paid = find.text("With price").at(index);

    await tester.ensureVisible(paid);
    await tester.tap(paid);
    await tester.pumpAndSettle();

    final fields = find.byWidgetPredicate((widget) => widget is Input && widget.placeholder.startsWith("In "));
    await tester.enterText(find.descendant(of: fields.last, matching: find.byType(EditableText)), amount);
    await tester.pumpAndSettle();
  }

  testWidgets("own delivery: named after where it is added, what it rides, and a price per day", (tester) async {
    await own(tester, ownName: "Sede Centro");

    expect(tester.takeException(), isNull);
    expect(find.text("Sede Centro"), findsOneWidget);
    expect(find.text("Motorcycle"), findsOneWidget);
    expect(find.text("Van or truck"), findsOneWidget);
    expect(find.text("Price per day"), findsOneWidget);
    expect(find.text("Monday"), findsOneWidget);
    expect(find.text("Sunday"), findsOneWidget);
    expect(find.text("Holidays"), findsOneWidget);
    // Seven days free and holidays as their weekday, until said otherwise.
    expect(find.text("Free"), findsNWidgets(8));
    expect(find.text("Same as that day"), findsOneWidget);
    // One price for every day is the rates' to say.
    expect(find.text("Price · optional"), findsNothing);
  });

  testWidgets("free on weekdays, 5 on weekends and holidays travels as the rates", (tester) async {
    final source = await own(tester);

    await tester.tap(find.text("Motorcycle"));
    await tester.pumpAndSettle();
    await price(tester, 5, "5");
    await price(tester, 6, "5");
    await price(tester, 7, "5,5");
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, hasLength(1));
    expect(source.created.single["VEHICLE"], "motorcycle");
    // Sunday first, as the backend counts them.
    expect(source.created.single["RATES"], {"DAYS": [5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0], "HOLIDAY": 5.5});
    expect(source.created.single.containsKey("FEE"), isFalse);
  });

  testWidgets("a day with a price and none written is not saved", (tester) async {
    final source = await own(tester);

    await price(tester, 0, "");
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, isEmpty);
  });

  test("an own delivery from before the rates opens with its one price every day", () {
    final draft = RatesDraft.of(const DeliveryOption(id: "a1", mode: DeliveryMode.own, fee: 3));
    addTearDown(draft.dispose);

    expect(draft.days.every((day) => day.charge == RateCharge.paid && day.price.value == "3"), isTrue);
    expect(draft.holiday.charge, RateCharge.same);
    expect(draft.read().rates?.request, {"DAYS": [3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0], "HOLIDAY": null});

    // A price emptied is a price forgotten, not a free day: Monday is named.
    draft.days[1].price.textController.text = "";
    expect(draft.read(), (rates: null, missing: 1, invalid: false));
    draft.days[1].price.textController.text = "1.500";
    expect(draft.read().invalid, isTrue);
  });

  test("the rates and the vehicle are read as the backend answers them", () {
    final option = DeliveryOption.from({
      "id": "a1",
      "mode": "own",
      "vehicle": "van",
      "rates": {"days": [5, 0, 0, 0, 0, 0, "5.50"], "holiday": null}
    })!;

    expect(option.vehicle, DeliveryVehicle.van);
    expect(option.rates?.days, [5, 0, 0, 0, 0, 0, 5.5]);
    expect(option.rates?.holiday, isNull);
    // An app or a carrier keeps neither.
    expect(createDeliveryOptionRequest(
      mode: DeliveryMode.platform,
      label: "App",
      vehicle: DeliveryVehicle.car,
      rates: option.rates
    ).keys, isNot(contains("RATES")));
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
