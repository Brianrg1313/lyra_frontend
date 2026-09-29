import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/screens/home/sections/deliveries/settings/settings_body.dart';

/// What the delivery settings draw: the general answer with its three states, and
/// each way of delivering with the figures a customer asks about.
///
/// The one that must not drift is the middle state: "not set yet" is neither
/// yes nor no, and a page that drew a blank as "No" would be showing the
/// opposite of what the backend answers.

/// The service with the read already answered: the body only draws what is
/// loaded, and asking for it for real would hit the backend.
class _Delivery extends BusinessDeliveryService {
  _Delivery({this.status = BusinessDeliveryStatus.ready, this.delivery});

  @override
  BusinessDeliveryStatus status;

  @override
  BusinessDeliveryModel? delivery;

  /// How many times the answer was asked for.
  int asked = 0;

  @override
  Future<void> load({bool force = false}) async => asked++;
}

Widget _app(BusinessDeliveryService service) => MaterialApp(
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

      return const Scaffold(body: DeliverySettingsBody());
    })
  )
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

  testWidgets("the body asks for the answer when it opens", (tester) async {
    final service = _Delivery(status: BusinessDeliveryStatus.idle);

    await tester.pumpWidget(_app(service));
    // Without `pumpAndSettle`: while it is being asked for, the body shows the
    // loading indicator, which never stops animating.
    await tester.pump();

    expect(service.asked, 1);
  });

  testWidgets("an option is read by its name and its figures", (tester) async {
    await tester.pumpWidget(_app(_Delivery(
      delivery: const BusinessDeliveryModel(
        delivers: true,
        currency: "USD",
        options: [_riders]
      )
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The shop's own riders with no name of their own are called what they are.
    expect(find.text("Own riders"), findsOneWidget);
    expect(find.text("Free"), findsOneWidget);
    expect(find.text("30–60 min"), findsOneWidget);
    expect(find.text("Chacao"), findsOneWidget);
  });

  testWidgets("not having said is drawn as neither yes nor no", (tester) async {
    await tester.pumpWidget(_app(_Delivery(
      delivery: const BusinessDeliveryModel(currency: "USD")
    )));
    await tester.pumpAndSettle();

    // Both flags: whether it delivers and whether a customer can collect.
    expect(find.text("Not set yet"), findsNWidgets(2));
    expect(find.text("No"), findsNothing);
  });

  testWidgets("the delivery area is offered once, beside whether it delivers", (tester) async {
    await tester.pumpWidget(_app(_Delivery(
      delivery: const BusinessDeliveryModel(currency: "USD")
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Select delivery area"), findsOneWidget);
  });

  testWidgets("the areas are fixed until the company says otherwise", (tester) async {
    await tester.pumpWidget(_app(_Delivery(
      delivery: BusinessDeliveryModel.fromJson(const {"currency": "USD"})
    )));
    await tester.pumpAndSettle();

    // A missing `meeting` is off: meeting a customer halfway is a promise, and
    // it is never made on a blank.
    expect(find.text("Fixed"), findsOneWidget);
    expect(find.text("Flexible"), findsNothing);
  });

  testWidgets("flexible areas are drawn as such", (tester) async {
    await tester.pumpWidget(_app(_Delivery(
      delivery: BusinessDeliveryModel.fromJson(const {"currency": "USD", "meeting": true})
    )));
    await tester.pumpAndSettle();

    expect(find.text("Flexible"), findsOneWidget);
  });

  test("the meeting point travels as a two-state flag", () {
    expect(deliveryMeetingRequest(true), {"MEETING_POINT": true});
    expect(deliveryMeetingRequest(false), {"MEETING_POINT": false});
  });

  testWidgets("turned off, it still lists what it keeps", (tester) async {
    await tester.pumpWidget(_app(_Delivery(
      delivery: const BusinessDeliveryModel(
        delivers: false,
        currency: "USD",
        options: [_riders]
      )
    )));
    await tester.pumpAndSettle();

    expect(find.text("Own riders"), findsOneWidget);
    expect(
      find.textContaining("Delivery is turned off"),
      findsOneWidget
    );
  });
}
