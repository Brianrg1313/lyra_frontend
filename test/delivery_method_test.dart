import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/screens/modals/deliveries/delivery_method/_delivery_method.dart';

/// What the delivery methods panel draws and writes: the three kinds of
/// service to pick from, what the company already has, and the form a card
/// opens with what holds for every delivery under it.
///
/// The one that must not drift is the middle state: "not set yet" is neither
/// yes nor no, and a panel that drew a blank as "No" would be showing the
/// opposite of what the backend answers.

/// A source that answers [answer] and keeps what was written to it.
class _Source implements DeliverySource {
  _Source(this.answer);

  BusinessDeliveryModel answer;

  /// How many times the answer was asked for.
  int asked = 0;

  final List<Map<String, dynamic>> edits = [];
  final List<Map<String, dynamic>> created = [];

  @override
  Future<BusinessDeliveryModel> delivery() async {
    asked++;
    return answer;
  }

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(DeliverySource source) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: SizedBox(
      width: 480,
      child: DeliveryMethodModal(onArea: () {}, source: source)
    ));
  })
);

/// One way of delivering, with every figure the row can draw.
const DeliveryOption _riders = DeliveryOption(
  id: "a1",
  mode: DeliveryMode.own,
  coverage: DeliveryCoverage.local,
  fee: 0,
  etaMin: 30,
  etaMax: 60,
  zones: [DeliveryZone(name: "Chacao")]
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets("the panel asks for the answer when it opens", (tester) async {
    final source = _Source(const BusinessDeliveryModel(currency: "USD"));

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();

    expect(source.asked, 1);
  });

  testWidgets("it asks how the company delivers, with the country's carriers", (tester) async {
    await tester.pumpWidget(_app(_Source(const BusinessDeliveryModel(currency: "USD"))));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Your own deliveries"), findsOneWidget);
    expect(find.text("Delivery apps"), findsOneWidget);
    expect(find.text("Parcel services"), findsOneWidget);
    expect(find.text("PedidosYa"), findsOneWidget);
    expect(find.text("Zoom"), findsOneWidget);
  });

  testWidgets("a method is read by its name and its figures", (tester) async {
    await tester.pumpWidget(_app(_Source(const BusinessDeliveryModel(
      delivers: true,
      currency: "USD",
      options: [_riders]
    ))));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The shop's own riders with no name of their own are called what they are.
    expect(find.text("Own riders"), findsOneWidget);
    expect(find.text("Free"), findsOneWidget);
    expect(find.text("30–60 min"), findsOneWidget);
    expect(find.text("Chacao"), findsOneWidget);
  });

  testWidgets("pickup not said is drawn as neither yes nor no", (tester) async {
    await tester.pumpWidget(_app(_Source(const BusinessDeliveryModel(currency: "USD"))));
    await tester.pumpAndSettle();

    expect(find.text("Not set yet"), findsOneWidget);
    expect(find.text("No"), findsNothing);
  });

  testWidgets("a card opens its form, with the areas fixed until the company says otherwise", (tester) async {
    await tester.pumpWidget(_app(_Source(
      BusinessDeliveryModel.fromJson(const {"currency": "USD"})
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The kind was picked on the card: the form does not ask it again.
    expect(find.text("Who carries it"), findsNothing);
    expect(find.text("For all your deliveries"), findsOneWidget);
    expect(find.text("Draw on the map"), findsOneWidget);
    // A missing `meeting` is off: meeting a customer halfway is a promise, and
    // it is never made on a blank.
    final fixed = tester.widget<AnimatedContainer>(find.ancestor(
      of: find.text("Fixed"),
      matching: find.byType(AnimatedContainer)
    ).first);
    final border = (fixed.decoration as BoxDecoration).border as Border;
    expect(border.top.color, ThemeColor.light.primary);
  });

  testWidgets("a new method turns delivery back on, and the panel goes back to the list", (tester) async {
    final source = _Source(const BusinessDeliveryModel(delivers: false, currency: "USD"));

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Your own deliveries"));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Save"));
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    expect(source.created, hasLength(1));
    expect(source.created.single["MODE"], "own");
    expect(source.edits, [deliveryFlagRequest(DeliveryFlag.delivers, true)]);
    expect(find.text("How do you deliver?"), findsOneWidget);
  });

  test("the meeting point travels as a two-state flag", () {
    expect(deliveryMeetingRequest(true), {"MEETING_POINT": true});
    expect(deliveryMeetingRequest(false), {"MEETING_POINT": false});
  });

  testWidgets("turned off, it still lists what it keeps, faded, and pickup is not", (tester) async {
    await tester.pumpWidget(_app(_Source(const BusinessDeliveryModel(
      delivers: false,
      pickup: true,
      currency: "USD",
      options: [_riders]
    ))));
    await tester.pumpAndSettle();

    double opacity(Finder finder) => tester
      .widgetList<AnimatedOpacity>(find.ancestor(of: finder, matching: find.byType(AnimatedOpacity)))
      .fold(1.0, (value, widget) => value * widget.opacity);

    expect(find.textContaining("Delivery is turned off"), findsOneWidget);
    expect(find.text("Turn on"), findsOneWidget);
    expect(opacity(find.text("Own riders")), lessThan(1));
    expect(opacity(find.text("Pickup at the business")), 1);
  });
}
