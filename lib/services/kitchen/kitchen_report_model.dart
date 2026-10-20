import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_read.dart';
import 'package:app/services/kitchen/recipe_model.dart';

/// What one dish or batch spent of a supply. Quantities in the supply's own unit.
@immutable
class ConsumptionDish {
  const ConsumptionDish({required this.productId, this.name = "", this.used = 0, this.waste = 0, this.spoiled = 0});

  final String productId;
  final String name;
  final double used;
  final double waste;
  final double spoiled;
}

/// What the branch spent of one supply according to the recipes (`POST /recipes/consumption`).
@immutable
class ConsumptionSupply {
  const ConsumptionSupply({
    required this.productId,
    this.tableId = "",
    this.name = "",
    this.used = 0,
    this.waste = 0,
    this.spoiled = 0,
    this.dishes = const []
  });

  final String productId;
  final String tableId;
  final String name;

  /// What went into dishes sold and batches made, failed sales already given back.
  final double used;

  /// The part of [used] the recipes expect to lose.
  final double waste;

  /// What went into lost dishes.
  final double spoiled;
  final List<ConsumptionDish> dishes;
}

/// A batch made in the window and what was lost of it.
typedef ConsumptionBatch = ({String productId, String name, double produced, double lost});

@immutable
class ConsumptionReport {
  const ConsumptionReport({this.supplies = const [], this.batches = const []});

  final List<ConsumptionSupply> supplies;
  final List<ConsumptionBatch> batches;

  bool get isEmpty => supplies.isEmpty && batches.isEmpty;

  static ConsumptionReport read(dynamic data) {
    if (data is! Map) return const ConsumptionReport();

    return ConsumptionReport(
      supplies: [
        for (final supply in kitchenMaps(data["supplies"])) ConsumptionSupply(
          productId: kitchenText(supply["productId"]),
          tableId: kitchenText(supply["tableId"]),
          name: kitchenText(supply["name"]),
          used: kitchenNum(supply["used"]) ?? 0,
          waste: kitchenNum(supply["waste"]) ?? 0,
          spoiled: kitchenNum(supply["spoiled"]) ?? 0,
          dishes: [
            for (final dish in kitchenMaps(supply["dishes"])) ConsumptionDish(
              productId: kitchenText(dish["productId"]),
              name: kitchenText(dish["name"]),
              used: kitchenNum(dish["used"]) ?? 0,
              waste: kitchenNum(dish["waste"]) ?? 0,
              spoiled: kitchenNum(dish["spoiled"]) ?? 0
            )
          ]
        )
      ],
      batches: [
        for (final batch in kitchenMaps(data["batches"])) (
          productId: kitchenText(batch["productId"]),
          name: kitchenText(batch["name"]),
          produced: kitchenNum(batch["produced"]) ?? 0,
          lost: kitchenNum(batch["lost"]) ?? 0
        )
      ]
    );
  }
}

/// What really left of a supply against what the recipes explain (`POST /recipes/variance`).
///
/// A positive [variance] is missing supply nobody recorded; a negative one, extra. Without a
/// count in the window ([counted] false) there is nothing to compare with and [variance] is 0:
/// never read it as «0 %».
@immutable
class VarianceRow {
  const VarianceRow({
    required this.productId,
    this.tableId = "",
    this.name = "",
    this.opening = 0,
    this.received = 0,
    this.sent = 0,
    this.closing = 0,
    this.actual = 0,
    this.theoretical = 0,
    this.sold = 0,
    this.lost = 0,
    this.variance = 0,
    this.percent,
    this.counted = false
  });

  final String productId;
  final String tableId;
  final String name;
  final double opening;
  final double received;
  final double sent;
  final double closing;
  final double actual;
  final double theoretical;
  final double sold;
  final double lost;
  final double variance;

  /// Over [theoretical], in %; `null` with no theoretical.
  final double? percent;
  final bool counted;

  static List<VarianceRow> listFrom(dynamic data) => [
    for (final row in kitchenMaps(data)) VarianceRow(
      productId: kitchenText(row["productId"]),
      tableId: kitchenText(row["tableId"]),
      name: kitchenText(row["name"]),
      opening: kitchenNum(row["opening"]) ?? 0,
      received: kitchenNum(row["received"]) ?? 0,
      sent: kitchenNum(row["sent"]) ?? 0,
      closing: kitchenNum(row["closing"]) ?? 0,
      actual: kitchenNum(row["actual"]) ?? 0,
      theoretical: kitchenNum(row["theoretical"]) ?? 0,
      sold: kitchenNum(row["sold"]) ?? 0,
      lost: kitchenNum(row["lost"]) ?? 0,
      variance: kitchenNum(row["variance"]) ?? 0,
      percent: kitchenNum(row["percent"]),
      counted: kitchenBool(row["counted"])
    )
  ];
}

/// One ingredient of a dish's cost. [unitCost] and [cost] are `null` for a supply with no price:
/// no cost column with a figure, no purchase with a cost in the window. [source] says where
/// [unitCost] came from: `column` (its table's cost column), `purchases` (the average paid),
/// `recipe` (a batch preparation, costed by its own recipe).
typedef DishCostLine = ({String productId, String name, double qty, double? unitCost, double? cost, String? source});

/// What ONE pick of a choice's option costs; [cost] `null` when nothing in it has a price.
typedef DishCostOption = ({String productId, String name, double? cost, bool complete});

/// What each option of one of the dish's choices costs, in the recipe's order.
typedef DishCostChoice = ({String id, String name, int choose, List<DishCostOption> options});

/// What making a dish costs from what each supply costs (`POST /recipes/cost`), and what its
/// price leaves. Modifiers are not in it.
///
/// A dish with choices costs something different on each sale: [cost], [lines] and [losing] are
/// those of the dearest pick (a price that covers only the cheap one loses with every customer
/// who takes the other), [range] the cheapest and the dearest, [choices] each option's.
@immutable
class DishCost {
  const DishCost({
    required this.productId,
    this.tableId = "",
    this.name = "",
    this.mode = RecipeMode.order,
    this.cost = 0,
    this.complete = true,
    this.price,
    this.profit,
    this.margin,
    this.losing = false,
    this.lines = const [],
    this.range,
    this.choices = const []
  });

  final String productId;
  final String tableId;
  final String name;
  final RecipeMode mode;

  /// The sum of the lines with a price: with [complete] false, a floor.
  final double cost;
  final bool complete;

  /// The product's price (its `price` column less its `discount`), what it leaves and that as a
  /// percent of the price; `null` with no price, and on a draft costed without one.
  final double? price;
  final double? profit;
  final double? margin;

  /// Whether it sells below what it costs.
  final bool losing;
  final List<DishCostLine> lines;

  /// With choices, the cheapest and the dearest pick; `null` when every sale costs the same.
  final ({double min, double max})? range;
  final List<DishCostChoice> choices;

  /// The line of [productId], when it was costed.
  DishCostLine? lineOf(String productId) => lines.where((line) => line.productId == productId).firstOrNull;

  /// What one pick of [productId] costs in the [index]th choice (a new choice has no id yet).
  DishCostOption? optionOf(int index, String productId) => index < choices.length
    ? choices[index].options.where((option) => option.productId == productId).firstOrNull
    : null;

  static List<DishCost> listFrom(dynamic data) => [
    for (final dish in kitchenMaps(data)) DishCost.fromJson(dish)
  ];

  /// `records/list` `costs` of a made table's page, by record id: the totals, without lines.
  static Map<String, DishCost> mapFrom(dynamic data) {
    if (data is! Map) return const {};

    return {
      for (final MapEntry(:key, :value) in data.entries)
        if (value is Map) key.toString(): DishCost.fromJson({...value, "productId": key.toString()})
    };
  }

  factory DishCost.fromJson(Map dish) => DishCost(
    productId: kitchenText(dish["productId"]),
    tableId: kitchenText(dish["tableId"]),
    name: kitchenText(dish["name"]),
    mode: RecipeMode.from(dish["mode"]),
    cost: kitchenNum(dish["cost"]) ?? 0,
    complete: dish["complete"] != false,
    price: kitchenNum(dish["price"]),
    profit: kitchenNum(dish["profit"]),
    margin: kitchenNum(dish["margin"]),
    losing: kitchenBool(dish["losing"]),
    lines: [
      for (final line in kitchenMaps(dish["lines"])) (
        productId: kitchenText(line["productId"]),
        name: kitchenText(line["name"]),
        qty: kitchenNum(line["qty"]) ?? 0,
        unitCost: kitchenNum(line["unitCost"]),
        cost: kitchenNum(line["cost"]),
        source: line["source"] is String ? line["source"] as String : null
      )
    ],
    range: _range(dish["range"]),
    choices: [
      for (final choice in kitchenMaps(dish["choices"])) (
        id: kitchenText(choice["id"]),
        name: kitchenText(choice["name"]),
        choose: kitchenInt(choice["choose"]),
        options: [
          for (final option in kitchenMaps(choice["options"])) (
            productId: kitchenText(option["productId"]),
            name: kitchenText(option["name"]),
            cost: kitchenNum(option["cost"]),
            complete: option["complete"] != false
          )
        ]
      )
    ]
  );

  static ({double min, double max})? _range(dynamic raw) {
    if (raw is! Map) return null;

    final min = kitchenNum(raw["min"]);
    final max = kitchenNum(raw["max"]);

    return min == null || max == null ? null : (min: min, max: max);
  }
}
