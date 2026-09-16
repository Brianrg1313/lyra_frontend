import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/screens/home/sections/business/location/_location.dart';

/// What the location tab draws: the written address, the map point, and the
/// rows the company has not filled in yet — which are drawn too, because the
/// empty row is what says a datum is missing and the panel is where it is
/// written.

/// The service with the read already answered (see the delivery tab's test).
class _Location extends BusinessLocationService {
  _Location({this.status = BusinessLocationStatus.ready, this.location});

  @override
  BusinessLocationStatus status;

  @override
  BusinessLocationModel? location;

  int asked = 0;

  @override
  Future<void> load({bool force = false}) async => asked++;
}

Widget _app(BusinessLocationService service) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessLocationService>.value(value: service),
      // The country is written by the catalog `/init` brings; with none it is
      // read as the code, which is what the row shows here.
      ChangeNotifierProvider<CountryCatalogService>.value(
        value: CountryCatalogService()
      )
    ],
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return const Scaffold(body: BusinessLocationTab());
    })
  )
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets("the tab asks for the location when it opens", (tester) async {
    final service = _Location(status: BusinessLocationStatus.idle);

    await tester.pumpWidget(_app(service));
    await tester.pump();

    expect(service.asked, 1);
  });

  testWidgets("the address and the point are read", (tester) async {
    await tester.pumpWidget(_app(_Location(
      location: const BusinessLocationModel(
        address: "Av. Francisco de Miranda, Torre Sol",
        city: "Caracas",
        country: "VE",
        latitude: 10.496112,
        longitude: -66.848503,
        maps: "https://maps.example/x"
      )
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Av. Francisco de Miranda, Torre Sol"), findsOneWidget);
    expect(find.text("Caracas"), findsOneWidget);
    expect(find.text("VE"), findsOneWidget);
    expect(find.text("10.496112, -66.848503"), findsOneWidget);
  });

  testWidgets("what is not set says so instead of hiding", (tester) async {
    await tester.pumpWidget(_app(_Location(
      location: const BusinessLocationModel(city: "Caracas")
    )));
    await tester.pumpAndSettle();

    // The address, the landmark, the region, the postal code, the country and
    // the point: everything the company has not said yet.
    expect(find.text("Not set"), findsNWidgets(6));
  });

  testWidgets("a read that failed offers to try again", (tester) async {
    await tester.pumpWidget(_app(_Location(
      status: BusinessLocationStatus.error
    )));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load the location"), findsOneWidget);
    expect(find.text("Try again"), findsOneWidget);
  });
}
