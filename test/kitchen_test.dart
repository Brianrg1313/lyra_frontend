import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/movements/stock_changed_model.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

/// The supply chain's contract (`backend .../docs/guides/cocina-frontend.md`): recipes,
/// availability, modifiers, presentations and reports read as the backend answers them, the
/// write bodies carry its capital keys, and a `stock/changed` of a dish made to order moves
/// only what its supplies allow.
void main() {
  group("reads", () {
    test("a recipe reads its mode, 86 and lines with decimals; a write's answer is named from the one before", () {
      final recipe = Recipe.read({
        "productId": "p-1", "tableId": "t-1", "mode": "batch", "paused": true, "version": 3,
        "updated": "2026-10-16T12:00:00.000Z",
        "lines": [
          {"id": "l-1", "tableId": "s-1", "productId": "wax", "name": "Wax", "qty": 0.0333, "negotiable": false, "waste": 10},
          {"id": "l-2", "tableId": "s-1", "productId": "wick", "name": "Wick", "qty": "1", "negotiable": true, "waste": 0}
        ]
      })!;

      expect(recipe.mode, RecipeMode.batch);
      expect(recipe.paused, isTrue);
      expect(recipe.version, 3);
      expect(recipe.lines.first.qty, 0.0333);
      expect(recipe.lines.first.waste, 10);
      expect(recipe.negotiable.map((line) => line.id), ["l-2"]);

      final saved = Recipe.read({
        "productId": "p-1", "tableId": "t-1", "mode": "order",
        "lines": [
          {"id": "l-1", "tableId": "s-1", "productId": "wax", "qty": 0.04},
          {"id": "l-3", "tableId": "s-1", "productId": "dye", "qty": 0.001}
        ]
      })!.namedAfter(recipe, {"dye": "Dye"});

      expect(saved.mode, RecipeMode.order);
      expect(saved.lines.map((line) => line.name), ["Wax", "Dye"]);
      expect(Recipe.read({"lines": []}), isNull);
    });

    test("availability is by product: order counts what can be made, batch its shelf and what a batch could add", () {
      final made = RecipeAvailability.mapFrom([
        {"productId": "burger", "mode": "order", "available": 3, "paused": false,
         "limit": {"productId": "bacon", "name": "bacon", "available": 3},
         "short": [{"line": "l-9", "productId": "fries", "name": "Fries"}]},
        {"productId": "candle", "mode": "batch", "available": 12, "capacity": 200, "paused": false, "limit": null, "short": []},
        {"mode": "order"}
      ]);

      expect(made.keys, ["burger", "candle"]);
      expect(made["burger"]!.limit!.name, "bacon");
      expect(made["burger"]!.short.single.line, "l-9");
      expect(made["burger"]!.capacity, isNull);
      expect(made["candle"]!.mode, RecipeMode.batch);
      expect(made["candle"]!.capacity, 200);
    });

    test("a modifier group reads min, max (null = all), products and options with their extras and removals", () {
      final group = ModifierGroup.listFrom([
        {"id": "g-1", "name": "Doneness", "min": 1, "max": 1, "position": 0,
         "products": [{"tableId": "t-1", "productId": "burger"}],
         "options": [
           {"id": "o-1", "name": "Medium", "price": 0, "lines": [], "remove": [], "paused": false},
           {"id": "o-2", "name": "Whole wheat", "price": "1.5",
            "lines": [{"tableId": "s-1", "productId": "ww", "qty": 1, "scale": 1}], "remove": ["l-bread"], "paused": true}
         ]},
        {"id": "g-2", "name": "Extras", "min": 0, "max": null, "options": []}
      ]);

      expect(group.first.required, isTrue);
      expect(group.first.max, 1);
      expect(group.first.products.single.productId, "burger");
      expect(group.first.options.last.price, 1.5);
      expect(group.first.options.last.remove, ["l-bread"]);
      expect(group.first.options.last.spends, isTrue);
      expect(group.first.options.first.spends, isFalse);
      expect(group.last.max, isNull);
      expect(group.last.required, isFalse);
    });

    test("presentations read from the product's answer", () {
      final items = Presentation.listFrom({"productId": "p", "tableId": "t", "presentations": [{"id": "x", "name": "Sack", "qty": 25}]});

      expect(items.single.name, "Sack");
      expect(items.single.qty, 25);
    });

    test("reports: consumption by supply and dish, variance with its count, cost incomplete with a line without price", () {
      final consumption = ConsumptionReport.read({
        "supplies": [{"tableId": "s", "productId": "bacon", "name": "Bacon", "used": 0.4, "waste": 0.04, "spoiled": 0.1,
          "dishes": [{"productId": "burger", "name": "Burger", "used": 0.4, "waste": 0.04, "spoiled": 0.1}]}],
        "batches": [{"productId": "sauce", "name": "Sauce", "produced": 10, "lost": 1}]
      });

      expect(consumption.supplies.single.dishes.single.name, "Burger");
      expect(consumption.batches.single.lost, 1);

      final variance = VarianceRow.listFrom([
        {"productId": "bacon", "actual": 2, "theoretical": 1.5, "variance": 0.5, "percent": 33.3, "counted": true},
        {"productId": "wax", "variance": 0, "percent": null, "counted": false}
      ]);

      expect(variance.first.counted, isTrue);
      expect(variance.last.counted, isFalse);
      expect(variance.last.percent, isNull);

      final cost = DishCost.listFrom([
        {"productId": "burger", "name": "Burger", "mode": "order", "cost": 1.2, "complete": false,
         "lines": [{"productId": "bacon", "name": "Bacon", "qty": 0.22, "unitCost": null, "cost": null}]}
      ]);

      expect(cost.single.complete, isFalse);
      expect(cost.single.lines.single.unitCost, isNull);
    });

    test("a table reads its kind: supplies, made, else a catalog", () {
      expect(TableLiteModel.fromJson({"id": "t", "name": "Supplies", "kind": "supplies"}).supplies, isTrue);
      expect(TableLiteModel.fromJson({"id": "t", "name": "Burgers", "kind": "made"}).kind, TableKind.made);
      expect(TableLiteModel.fromJson({"id": "t", "name": "Burgers", "kind": "made"}).supplies, isFalse);
      expect(TableLiteModel.fromJson({"id": "t", "name": "Menu", "kind": "catalog"}).supplies, isFalse);
      expect(TableLiteModel.fromJson({"id": "t", "name": "Menu"}).supplies, isFalse);
    });
  });

  group("bodies", () {
    test("a recipe sends its mode and lines, whole numbers as integers, the optional flags only when set", () {
      expect(saveRecipeRequest(tableId: "t", productId: "p", mode: RecipeMode.order, lines: [
        (tableId: "s", productId: "bacon", qty: 0.2, negotiable: false, waste: 10),
        (tableId: "t", productId: "burger", qty: 1, negotiable: true, waste: 0)
      ]), {
        "TABLE_ID": "t", "PRODUCT_ID": "p", "MODE": "order",
        "LINES": [
          {"TABLE_ID": "s", "PRODUCT_ID": "bacon", "QUANTITY": 0.2, "WASTE": 10},
          {"TABLE_ID": "t", "PRODUCT_ID": "burger", "QUANTITY": 1, "NEGOTIABLE": true}
        ]
      });
    });

    test("a batch sends LOST and NOTE only when there is one; a lost dish its WITHOUT", () {
      expect(produceBatchRequest(tableId: "t", productId: "p", quantity: 100, lost: 5, note: " cracked "),
        {"TABLE_ID": "t", "PRODUCT_ID": "p", "QUANTITY": 100, "LOST": 5, "NOTE": "cracked"});
      expect(produceBatchRequest(tableId: "t", productId: "p", quantity: 2.5),
        {"TABLE_ID": "t", "PRODUCT_ID": "p", "QUANTITY": 2.5});
      expect(discardDishRequest(tableId: "t", productId: "p", quantity: 1, without: ["l-9"]),
        {"TABLE_ID": "t", "PRODUCT_ID": "p", "QUANTITY": 1, "WITHOUT": ["l-9"]});
      expect(pauseRecipeRequest(productId: "p", paused: true), {"PRODUCT_ID": "p", "PAUSED": true});
    });

    test("presentations keep the ids of the ones that exist", () {
      expect(savePresentationsRequest(tableId: "t", productId: "p", presentations: [
        (id: "x", name: " Sack ", qty: 25),
        (id: "", name: "Bag", qty: 0.5)
      ]), {
        "TABLE_ID": "t", "PRODUCT_ID": "p",
        "PRESENTATIONS": [{"ID": "x", "NAME": "Sack", "QUANTITY": 25}, {"NAME": "Bag", "QUANTITY": 0.5}]
      });
    });

    test("a modifier group sends its id, every option's id and MAX only when there is one", () {
      final body = saveModifierGroupRequest(
        id: "g-1",
        name: "Extras ",
        min: 0,
        products: [(tableId: "t", productId: "burger")],
        options: [
          const ModifierOption(id: "o-1", name: "Cheese", price: 1),
          const ModifierOption(name: "Bacon", price: 1.5, lines: [(tableId: "s", productId: "bacon", qty: 0.05)])
        ]
      );

      expect(body["ID"], "g-1");
      expect(body["NAME"], "Extras");
      expect(body.containsKey("MAX"), isFalse);
      expect(body["OPTIONS"], [
        {"ID": "o-1", "NAME": "Cheese", "PRICE": 1, "LINES": [], "REMOVE": [], "PAUSED": false},
        {"NAME": "Bacon", "PRICE": 1.5, "LINES": [{"TABLE_ID": "s", "PRODUCT_ID": "bacon", "QUANTITY": 0.05}], "REMOVE": [], "PAUSED": false}
      ]);
    });

    test("a report's window is whole days, either end open", () {
      final window = kitchenWindowRequest(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 15));

      expect(DateTime.parse(window["FROM"]).toLocal(), DateTime(2026, 10, 1));
      expect(DateTime.parse(window["TO"]).toLocal(), DateTime(2026, 10, 16).subtract(const Duration(milliseconds: 1)));
      expect(kitchenWindowRequest(), isEmpty);
    });

    test("a supplies or made table says its KIND; a catalog sends none", () {
      expect(createTableRequest(title: "Supplies", description: "", color: "0xFF000000", kind: TableKind.supplies)["KIND"], "supplies");
      expect(createTableRequest(title: "Menu", description: "", color: "0xFF000000", kind: TableKind.made)["KIND"], "made");
      expect(createTableRequest(title: "Menu", description: "", color: "0xFF000000").containsKey("KIND"), isFalse);
    });
  });

  group("live", () {
    test("stock/changed of a dish made to order moves only its availability; another one a supply's stock, decimals kept", () {
      final service = KitchenProductsService(listen: false)..seed(
        tables: const [TableLiteModel(id: "t", title: "Menu")],
        products: const [
          KitchenProduct(id: "burger", tableId: "t", name: "Burger"),
          KitchenProduct(id: "bacon", tableId: "t", name: "Bacon", stock: 2, supplies: true)
        ],
        availability: const {"burger": RecipeAvailability(productId: "burger", available: 3, limit: RecipeLimit(productId: "bacon", name: "bacon"))}
      );

      final composite = StockChangedModel.fromEvent({"productId": "burger", "composite": true, "onHand": null, "available": 2});
      expect(composite.composite, isTrue);

      service.receive(composite);
      expect(service.availabilityOf("burger")!.available, 2);
      expect(service.availabilityOf("burger")!.limit!.name, "bacon");

      service.receive(StockChangedModel.fromEvent({"productId": "bacon", "onHand": 1.75, "reserved": 0, "available": 1.75}));
      expect(service.products.last.stock, 1.75);

      service.dispose();
    });
  });
}
