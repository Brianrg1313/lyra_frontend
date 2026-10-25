// SERVICES
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/toolkit/backend/api.dart';

/// Reads what the branch can make of the ids it is given (`POST /inventory/recipes/availability`):
/// a product with a recipe answers, one without is not in the map. Cloud only.
typedef RecipeMeasure = Future<Map<String, RecipeAvailability>> Function(List<String> ids);

/// The backend's [RecipeMeasure], up to 200 ids per call.
Future<Map<String, RecipeAvailability>> measureRecipes(List<String> ids) async {
  if (ids.isEmpty) return const {};

  final result = <String, RecipeAvailability>{};

  for (var start = 0; start < ids.length; start += 200) {
    final chunk = ids.sublist(start, (start + 200).clamp(0, ids.length));

    result.addAll(RecipeAvailability.mapFrom(await api.post(
      path: "/inventory/recipes/availability",
      version: "v1",
      data: {"PRODUCT_IDS": chunk}
    )));
  }

  return result;
}
