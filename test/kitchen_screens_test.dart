import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:provider/provider.dart';

import 'package:app/generated/l10n.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/modifiers_service.dart';
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/kitchen/recipe_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/screens/home/sections/inventory/modifiers/_modifiers.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_list/supplies/_supplies.dart';
import 'package:app/screens/modals/kitchen/discard_dish/_discard_dish.dart';
import 'package:app/screens/modals/kitchen/modifier_group/_modifier_group.dart';
import 'package:app/screens/modals/kitchen/presentations/_presentations.dart';
import 'package:app/screens/modals/kitchen/produce_batch/_produce_batch.dart';
import 'package:app/screens/modals/kitchen/recipe/_recipe.dart';

/// The kitchen's screens draw what their services hold, at a desktop width, without
/// overflowing: a supply says what its recipe makes now and why («— because of the bacon»), a
/// paused one is sold out, one without a recipe offers to create it, a batch offers to produce,
/// a dish made to order to record a lost one, and a group says its rule. No test here reads the
/// network: every service is seeded.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Future<void> pump(WidgetTester tester, Widget child, {List<ChangeNotifierProvider> providers = const []}) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final body = Builder(builder: (context) {
      AppSize.instance(context);
      return Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child));
    });

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: providers.isEmpty ? body : MultiProvider(providers: providers, child: body)
    ));
    await tester.pumpAndSettle();
  }

  const burger = KitchenProduct(id: "burger", tableId: "menu", name: "Burger");
  const candle = KitchenProduct(id: "candle", tableId: "menu", name: "Candle");
  const salt = KitchenProduct(id: "salt", tableId: "menu", name: "Salt", stock: 3);

  testWidgets("a supplies table's list says what each product makes now, and why", (tester) async {
    const table = TableLiteModel(id: "menu", title: "Pantry", kind: TableKind.supplies);
    final service = KitchenProductsService(listen: false)..seed(
      table: table,
      products: const [burger, candle, salt],
      availability: const {
        "burger": RecipeAvailability(productId: "burger", available: 3, limit: RecipeLimit(productId: "bacon", name: "bacon")),
        "candle": RecipeAvailability(productId: "candle", mode: RecipeMode.batch, available: 12, capacity: 200, paused: true)
      }
    );
    addTearDown(service.dispose);

    await pump(
      tester,
      SuppliesSection(table: table, parts: const InventoryBarParts(selector: SizedBox(), controls: []), service: service),
      providers: [ChangeNotifierProvider<HomeService>.value(value: HomeService())]
    );

    expect(tester.takeException(), isNull);
    expect(find.text("3 left — because of the bacon"), findsOneWidget);
    expect(find.text("Sold out"), findsOneWidget);
    expect(find.textContaining("No recipe"), findsOneWidget);
  });

  testWidgets("a batch's panel offers to produce; one without a recipe to create it", (tester) async {
    final batch = RecipeService(product: candle)..seed(
      recipe: const Recipe(productId: "candle", tableId: "menu", mode: RecipeMode.batch, lines: [
        RecipeLine(id: "l-1", tableId: "s", productId: "wax", name: "Wax", qty: 0.0333, waste: 10),
        RecipeLine(id: "l-2", tableId: "s", productId: "dye", name: "Dye", qty: 0.001, negotiable: true)
      ]),
      availability: const RecipeAvailability(productId: "candle", mode: RecipeMode.batch, available: 12, capacity: 200,
        limit: RecipeLimit(productId: "wick", name: "wick")),
      presentations: const [Presentation(id: "p", name: "Sack", qty: 25)]
    );
    addTearDown(batch.dispose);

    await pump(tester, RecipePanel(product: candle, onChanged: () {}, service: batch));

    expect(tester.takeException(), isNull);
    expect(find.text("12 in stock · supplies for 200 more (wick)"), findsOneWidget);
    expect(find.text("Produce batch"), findsOneWidget);
    expect(find.text(S.current.kitchen_discard), findsNothing);
    expect(find.text("Sack"), findsOneWidget);

    await tester.tap(find.text("Edit recipe"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("Wax"), findsOneWidget);

    final none = RecipeService(product: salt)..seed();
    addTearDown(none.dispose);

    await pump(tester, RecipePanel(key: const ValueKey("salt"), product: salt, onChanged: () {}, service: none));

    expect(tester.takeException(), isNull);
    expect(find.text("Create recipe"), findsOneWidget);
  });

  testWidgets("a dish made to order offers to record a lost unit, not to produce", (tester) async {
    final dish = RecipeService(product: burger)..seed(
      recipe: const Recipe(productId: "burger", tableId: "menu", lines: [
        RecipeLine(id: "l-1", tableId: "s", productId: "bacon", name: "Bacon", qty: 0.2)
      ]),
      availability: const RecipeAvailability(productId: "burger", available: 3)
    );
    addTearDown(dish.dispose);

    await pump(tester, RecipePanel(product: burger, onChanged: () {}, service: dish));

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.kitchen_discard), findsOneWidget);
    expect(find.text("Produce batch"), findsNothing);
    expect(find.text("How it is bought"), findsNothing);
  });

  testWidgets("a group says its rule and folds its options", (tester) async {
    final modifiers = ModifiersService()..seed([
      const ModifierGroup(id: "g", name: "Doneness", min: 1, max: 1, options: [ModifierOption(id: "o", name: "Medium")]),
      ModifierGroup(id: "x", name: "Extras", options: [
        for (var i = 0; i < 7; i++) ModifierOption(id: "e-$i", name: "Extra $i", price: 1)
      ])
    ]);
    addTearDown(modifiers.dispose);

    await pump(tester, const ModifiersTab(), providers: [ChangeNotifierProvider<ModifiersService>.value(value: modifiers)]);
    expect(tester.takeException(), isNull);
    expect(find.text("Choose one"), findsOneWidget);
    expect(find.text("+2 more"), findsOneWidget);
  });

  testWidgets("the panels of a group, a batch, a lost dish and the presentations draw their fields", (tester) async {
    await pump(tester, const ModifierGroupModal(group: ModifierGroup(id: "g", name: "Extras", options: [
      ModifierOption(id: "o", name: "Cheese", price: 1, remove: ["l-1"])
    ])));
    expect(tester.takeException(), isNull);
    expect(find.text("Add option"), findsOneWidget);
    expect(find.text("Delete group"), findsOneWidget);

    await pump(tester, const ProduceBatchModal());
    expect(tester.takeException(), isNull);
    expect(find.text("Lost from the batch"), findsOneWidget);

    await pump(tester, const DiscardDishModal(recipe: Recipe(productId: "burger", tableId: "menu", lines: [
      RecipeLine(id: "l-9", tableId: "s", productId: "fries", name: "Fries", qty: 0.1, negotiable: true)
    ])));
    expect(tester.takeException(), isNull);
    expect(find.text("Fries"), findsOneWidget);

    await pump(tester, const PresentationsModal(presentations: [Presentation(id: "p", name: "Sack", qty: 25)], unit: "kg"));
    expect(tester.takeException(), isNull);
    expect(find.text("kg"), findsOneWidget);
  });
}
