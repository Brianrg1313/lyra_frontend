// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/toolkit/backend/api.dart';

/// What a made product's form reads and writes besides its record (`cocina-frontend.md` §6, §9):
/// the modifier groups it offers, and what making it costs as it is written. Cloud only, `api`
/// direct like the rest of the kitchen; a seam for tests.
class MadeKitchenApi {
  const MadeKitchenApi();

  static const String _modifiers = "/inventory/modifiers";

  /// Every group of the company, in order: which ones a product offers is in their `products`.
  Future<List<ModifierGroup>> groups() async =>
    ModifierGroup.listFrom(await api.get(path: _modifiers, version: "v1"));

  /// Creates or replaces a group, from `saveModifierGroupRequest`.
  Future<void> saveGroup(Map<String, dynamic> body) => api.put(path: _modifiers, version: "v1", data: body);

  /// What making one of a recipe being written costs, and what each line adds: nothing is saved
  /// (`POST /recipes/cost` with `TABLE_ID` and `LINES`, `cocina-frontend.md` §9). Refused like a
  /// save would be (`invalid_recipe_lines`, `unit_unrelated`).
  Future<DishCost?> draftCost({
    required String tableId,
    required RecipeMode mode,
    required List<RecipeLineDraft> lines,
    List<RecipeChoiceDraft> choices = const []
  }) async {
    final answer = await api.post(path: "/inventory/recipes/cost", version: "v1", data: {
      "TABLE_ID": tableId,
      "MODE": mode.name,
      "LINES": recipeLinesRequest(lines, choices)
    });

    return DishCost.listFrom(answer).firstOrNull;
  }
}
