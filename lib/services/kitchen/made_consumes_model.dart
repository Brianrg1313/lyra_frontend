import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_read.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';

/// What one record of a `made` table consumes and how many the branch can sell now, as
/// `POST /inventory/products/records/list` answers it beside the rows (`consumes`, by record id,
/// `cocina-frontend.md` §3): the recipe is part of the record, so the sheet reads it with it.
@immutable
class MadeConsumes {
  const MadeConsumes({required this.recipe, required this.availability});

  final Recipe recipe;

  /// [RecipeAvailability.available] is what can be sold now (a batch: its shelf, and
  /// [RecipeAvailability.capacity] how many more a batch would make). No limit nor short: the
  /// panel reads those (`recipes/availability`).
  final RecipeAvailability availability;

  /// The `consumes` object of a page of [tableId]; a record not in it consumes nothing known.
  static Map<String, MadeConsumes> mapFrom(dynamic data, {required String tableId}) {
    if (data is! Map) return const {};

    return {
      for (final MapEntry(:key, :value) in data.entries)
        if (value is Map) key.toString(): _read(key.toString(), tableId, value)
    };
  }

  static MadeConsumes _read(String id, String tableId, Map value) {
    final mode = RecipeMode.from(value["mode"]);
    final paused = kitchenBool(value["paused"]);

    return MadeConsumes(
      recipe: Recipe(
        productId: id,
        tableId: tableId,
        mode: mode,
        paused: paused,
        lines: [for (final line in kitchenMaps(value["lines"])) RecipeLine.fromJson(line)],
        choices: RecipeChoice.listFrom(value["choices"])
      ),
      availability: RecipeAvailability(
        productId: id,
        mode: mode,
        available: kitchenNum(value["available"]) ?? 0,
        capacity: kitchenNum(value["capacity"]),
        paused: paused
      )
    );
  }
}
