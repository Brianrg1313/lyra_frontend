// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/toolkit/api.dart';

/// What a made product's form reads and writes besides its record (`cocina-frontend.md` §6, §9):
/// the modifier groups it offers, and what making it costs. Cloud only, `api` direct like the
/// rest of the kitchen; a seam for tests.
class MadeKitchenApi {
  const MadeKitchenApi();

  static const String _modifiers = "/inventory/modifiers";

  /// Every group of the company, in order: which ones a product offers is in their `products`.
  Future<List<ModifierGroup>> groups() async =>
    ModifierGroup.listFrom(await api.get(path: _modifiers, version: "v1"));

  /// Creates or replaces a group, from `saveModifierGroupRequest`.
  Future<void> saveGroup(Map<String, dynamic> body) => api.put(path: _modifiers, version: "v1", data: body);

  /// What making [productId] costs at the average price paid for its supplies; `null` when it
  /// has no recipe to cost.
  Future<DishCost?> cost(String productId) async {
    final answer = await api.post(path: "/inventory/recipes/cost", version: "v1", data: {"PRODUCT_IDS": [productId]});

    return DishCost.listFrom(answer).where((dish) => dish.productId == productId).firstOrNull;
  }
}
