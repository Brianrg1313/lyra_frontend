import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/coverage_block.dart';

/// Where the company delivers, in the desk's panel: one shared map or one per
/// branch, switched there. Per branch, a branch with no areas delivers nowhere,
/// which the panel must not hide.
void main() {
  setUpAll(() {
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Future<(_Deliveries, DeliveryAreasService)> pump(WidgetTester tester, String scope) async {
    final deliveries = _Deliveries(scope);
    final areas = DeliveryAreasService(source: deliveries);
    final branches = BusinessBranchesService(source: _Business());

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<DeliveryAreasService>.value(value: areas),
          ChangeNotifierProvider<BusinessBranchesService>.value(value: branches),
          ChangeNotifierProvider<BranchesFocus>(create: (_) => BranchesFocus())
        ],
        child: Builder(builder: (context) {
          AppSize.instance(context);

          return const Scaffold(body: SingleChildScrollView(child: CoverageBlock()));
        })
      )
    ));

    await areas.load();
    await branches.load();
    await tester.pumpAndSettle();

    return (deliveries, areas);
  }

  testWidgets("shared: one row for the map every branch serves, with its count", (tester) async {
    await pump(tester, "global");

    expect(tester.takeException(), isNull);
    expect(find.text("Every branch"), findsOneWidget);
    expect(find.text("1 area, shared by every branch"), findsOneWidget);
    expect(find.text("Centro"), findsNothing);
  });

  testWidgets("per branch: one row per branch, the one with no areas said so", (tester) async {
    await pump(tester, "branch");

    expect(tester.takeException(), isNull);
    expect(find.text("Centro"), findsOneWidget);
    expect(find.text("2 areas"), findsOneWidget);
    expect(find.text("No areas · Not on the map"), findsOneWidget);
  });

  testWidgets("the switch writes the other scope and the panel follows it", (tester) async {
    final (deliveries, _) = await pump(tester, "global");

    await tester.tap(find.text("Per branch"));
    await tester.pumpAndSettle();

    expect(deliveries.writes, [{"DELIVERY_SCOPE": "branch"}]);
    expect(find.text("Centro"), findsOneWidget);
  });
}

class _Deliveries implements DeliverySource {
  _Deliveries(this.scope);

  String scope;
  final List<Map<String, dynamic>> writes = [];

  @override
  Future<DeliveryAreasModel> areas() async => DeliveryAreasModel.fromJson({
    "currency": "USD",
    "scope": scope,
    "areas": [
      {"id": "s", "name": "Todas", "kind": "radius", "latitude": 10.5, "longitude": -66.9, "radius": 5},
      {"id": "c1", "branch": "b-centro", "name": "Centro 1", "kind": "radius", "latitude": 10.5, "longitude": -66.9, "radius": 2},
      {"id": "c2", "branch": "b-centro", "name": "Centro 2", "kind": "radius", "latitude": 10.5, "longitude": -66.9, "radius": 3}
    ]
  });

  @override
  Future<void> editDelivery(Map<String, dynamic> request) async {
    writes.add(request);
    scope = request["DELIVERY_SCOPE"] as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Business implements BusinessSource {
  @override
  Future<List<BusinessBranchModel>> branches() async => [
    BusinessBranchModel.from({"id": "b-centro", "name": "Centro", "main": true, "latitude": 10.5, "longitude": -66.9})!,
    BusinessBranchModel.from({"id": "b-almacen", "name": "Almacén", "storefront": false})!
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
