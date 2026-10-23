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
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/deliveries_panel.dart';
import 'package:app/screens/home/sections/deliveries/methods/state/method_flow.dart';

/// Where the company delivers, edited in the desk's panel: one shared map or
/// one per branch, switched there; the areas of the branch picked (every
/// branch's for "All branches") under "Add area", what the search matches, and
/// what happens outside them.
void main() {
  setUpAll(() {
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Future<(_Deliveries, List<AreaMethod>, AreaEditor)> pump(
    WidgetTester tester,
    String scope, {
    String? branch,
    String query = ""
  }) async {
    final deliveries = _Deliveries(scope);
    final added = <AreaMethod>[];
    final map = MapController();
    final editor = AreaEditor(map: map);

    addTearDown(() {
      editor.dispose();
      map.dispose();
    });

    final areas = DeliveryAreasService(source: deliveries);
    final branches = BusinessBranchesService(source: _Business());
    final delivery = BusinessDeliveryService(source: deliveries);
    final flow = MethodFlow();

    final filters = FormController();
    final search = InputController.search(form: filters);
    final branchPicker = InputController.select(form: filters, key: "BRANCH", initial: branch ?? DeliveriesPanel.allBranches);

    addTearDown(flow.dispose);
    addTearDown(filters.dispose);

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
          ChangeNotifierProvider<BusinessDeliveryService>.value(value: delivery),
          ChangeNotifierProvider<BranchesFocus>(create: (_) => BranchesFocus())
        ],
        child: ListenableBuilder(listenable: Listenable.merge([areas, editor]), builder: (context, _) {
          AppSize.instance(context);

          return Scaffold(body: DeliveriesPanel(
            editor: editor,
            branch: branch,
            origin: () => const LatLng(10.5, -66.9),
            onBranch: (_) {},
            search: search,
            branchPicker: branchPicker,
            query: query,
            onAdd: added.add,
            view: DeliveriesView.areas,
            onView: (_) {},
            onShipment: (_) {},
            flow: flow,
            shipments: false
          ));
        })
      )
    ));

    await areas.load();
    await branches.load();
    await delivery.load();
    await tester.pumpAndSettle();

    return (deliveries, added, editor);
  }

  testWidgets("under the areas, what happens outside them, saved on tap", (tester) async {
    final (deliveries, _, _) = await pump(tester, "global");

    expect(find.text("Outside your areas"), findsOneWidget);

    await tester.ensureVisible(find.text("Flexible"));
    await tester.tap(find.text("Flexible"));
    await tester.pumpAndSettle();

    expect(deliveries.writes, [{"MEETING_POINT": true}]);
  });

  testWidgets("shared: the map every branch serves, no branch to pick", (tester) async {
    await pump(tester, "global");

    expect(tester.takeException(), isNull);
    expect(find.text("Todas"), findsOneWidget);
    expect(find.text("Centro 1"), findsNothing);
    expect(find.text("Search areas"), findsOneWidget);
  });

  testWidgets("per branch: the branch picked's areas only", (tester) async {
    await pump(tester, "branch", branch: "b-centro");

    expect(tester.takeException(), isNull);
    expect(find.text("Centro 1"), findsOneWidget);
    expect(find.text("Centro 2"), findsOneWidget);
    expect(find.text("Todas"), findsNothing);
    expect(find.text("Add area"), findsOneWidget);
  });

  testWidgets("per branch, all branches: every branch's areas, and no map to add one to", (tester) async {
    await pump(tester, "branch");

    expect(find.text("Centro 1"), findsOneWidget);
    expect(find.text("Todas"), findsNothing);
    expect(find.text("Add area"), findsNothing);
    expect(find.text("Pick a branch above to add an area to its map."), findsOneWidget);
  });

  testWidgets("the search keeps the areas whose name holds it", (tester) async {
    await pump(tester, "branch", branch: "b-centro", query: "2");

    expect(find.text("Centro 1"), findsNothing);
    expect(find.text("Centro 2"), findsOneWidget);
  });

  testWidgets("a search that leaves nothing says so, not that there are no areas", (tester) async {
    await pump(tester, "global", query: "zzz");

    expect(find.text("Nothing matches your search."), findsOneWidget);
    expect(find.text("No areas yet"), findsNothing);
  });

  testWidgets("the switch writes the other scope and the panel follows it", (tester) async {
    final (deliveries, _, _) = await pump(tester, "global");

    await tester.tap(find.text("Per branch"));
    await tester.pumpAndSettle();

    expect(deliveries.writes, [{"DELIVERY_SCOPE": "branch"}]);
    expect(find.text("Centro 1"), findsOneWidget);
  });

  testWidgets("\"Add area\" sits above the areas and starts the method picked", (tester) async {
    final (_, added, _) = await pump(tester, "global");

    expect(
      tester.getTopLeft(find.text("Add area")).dy,
      lessThan(tester.getTopLeft(find.text("Todas")).dy)
    );

    await tester.tap(find.text("Add area"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Radius around your business"));
    await tester.pumpAndSettle();

    expect(added, [AreaMethod.radius]);
  });

  testWidgets("shaping: the panel reads the shape live, and Save stays in reach", (tester) async {
    final (_, _, editor) = await pump(tester, "global");

    editor.start(AreaMethod.radius, const LatLng(10.5, -66.9));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("New area"), findsOneWidget);
    expect(find.text("28.27 km²"), findsOneWidget);
    expect(find.text("Within 3 km"), findsOneWidget);
    expect(find.text("Add area"), findsNothing);
    expect(find.text("Save"), findsOneWidget);

    editor.setRadius(1);
    await tester.pumpAndSettle();

    expect(find.text("3.14 km²"), findsOneWidget);

    editor.start(AreaMethod.draw, const LatLng(10.5, -66.9));
    await tester.pumpAndSettle();

    expect(find.text("0 km²"), findsOneWidget);
    expect(find.text("0 points · 3 at least"), findsOneWidget);
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
  Future<BusinessDeliveryModel> delivery() async => const BusinessDeliveryModel(currency: "USD");

  @override
  Future<void> editDelivery(Map<String, dynamic> request) async {
    writes.add(request);
    scope = request["DELIVERY_SCOPE"] as String? ?? scope;
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
