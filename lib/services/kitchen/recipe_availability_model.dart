import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_read.dart';
import 'package:app/services/kitchen/recipe_model.dart';

/// What runs out first: "3 left, because of the bacon".
@immutable
class RecipeLimit {
  const RecipeLimit({required this.productId, this.name = "", this.available = 0});

  final String productId;
  final String name;
  final double available;
}

/// A negotiable line there is not enough for: what the till asks the customer about.
@immutable
class RecipeShort {
  const RecipeShort({required this.line, required this.productId, this.name = ""});

  /// The recipe line's id, what goes in `WITHOUT`.
  final String line;
  final String productId;
  final String name;
}

/// What the branch can make of a product right now (`POST /inventory/recipes/availability`).
///
/// - [RecipeMode.order]: [available] is how many can be made now; [capacity] is `null`.
/// - [RecipeMode.batch]: [available] is what is on its shelf, [capacity] how many more a batch
///   could make with today's supplies.
@immutable
class RecipeAvailability {
  const RecipeAvailability({
    required this.productId,
    this.mode = RecipeMode.order,
    this.available = 0,
    this.capacity,
    this.paused = false,
    this.limit,
    this.short = const []
  });

  final String productId;
  final RecipeMode mode;
  final double available;
  final double? capacity;
  final bool paused;
  final RecipeLimit? limit;
  final List<RecipeShort> short;

  /// The same, with what a `stock/changed` (`composite: true`) says is left.
  RecipeAvailability withAvailable(double value) => RecipeAvailability(
    productId: productId,
    mode: mode,
    available: value,
    capacity: capacity,
    paused: paused,
    limit: limit,
    short: short
  );

  /// The answer by product id. A product with no recipe is not in it.
  static Map<String, RecipeAvailability> mapFrom(dynamic data) => {
    for (final entry in kitchenMaps(data))
      if (kitchenText(entry["productId"]).isNotEmpty) kitchenText(entry["productId"]): RecipeAvailability(
        productId: kitchenText(entry["productId"]),
        mode: RecipeMode.from(entry["mode"]),
        available: kitchenNum(entry["available"]) ?? 0,
        capacity: kitchenNum(entry["capacity"]),
        paused: kitchenBool(entry["paused"]),
        limit: _limit(entry["limit"]),
        short: [
          for (final line in kitchenMaps(entry["short"]))
            if (kitchenText(line["line"]).isNotEmpty) RecipeShort(
              line: kitchenText(line["line"]),
              productId: kitchenText(line["productId"]),
              name: kitchenText(line["name"])
            )
        ]
      )
  };

  static RecipeLimit? _limit(dynamic raw) {
    if (raw is! Map || kitchenText(raw["productId"]).isEmpty) return null;

    return RecipeLimit(
      productId: kitchenText(raw["productId"]),
      name: kitchenText(raw["name"]),
      available: kitchenNum(raw["available"]) ?? 0
    );
  }
}
