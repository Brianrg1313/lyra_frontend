import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/toolkit/backend/api.dart';

/// What the till asks the kitchen while ringing a dish up (`cocina-frontend.md` §5–6): which
/// products offer modifiers, a product's groups with what is left of each option, and which of
/// its negotiable lines are short.
///
/// **Cloud only** (`pos.kitchen`): a master knows no recipes, so there it offers nothing and
/// the till rings products up as it always did. Reading the modifiers is for any member: the
/// till needs them whoever is at it.
///
/// Owned by the POS page, read once when it opens ([load]). A group created while the till is
/// open is still asked for when the backend refuses the line (`invalid_modifiers`).
class TillKitchenService extends ChangeNotifier {
  /// The products some group is offered on.
  Set<String> _offered = const {};

  /// Whether the till asks the kitchen anything here.
  static bool get shown => CapabilityService().shows("pos.kitchen");

  /// Whether ringing [productId] up asks for its modifiers first.
  bool offers(String productId) => _offered.contains(productId);

  /// Reads which products offer modifiers. A failed read offers none: the till still sells,
  /// and a required group is asked for when the backend refuses the line.
  Future<void> load() async {
    if (!shown) return;

    try {
      final groups = ModifierGroup.listFrom(await api.get(path: "/inventory/modifiers", version: "v1"));

      _offered = {
        for (final group in groups)
          if (group.options.isNotEmpty)
            for (final product in group.products) product.productId
      };
    } catch (error) {
      if (kDebugMode) print("tillModifiers failed: $error");
      return;
    }

    notifyListeners();
  }

  /// [productId]'s groups as the till draws them: each option with `available` at the
  /// header's branch (0 = greyed out). Empty when it offers none, or the read failed.
  Future<List<ModifierGroup>> groupsOf(String productId) async {
    try {
      final groups = ModifierGroup.listFrom(await api.post(
        path: "/inventory/modifiers/availability",
        version: "v1",
        data: {"PRODUCT_ID": productId}
      ));

      return [for (final group in groups) if (group.options.isNotEmpty) group];
    } catch (error) {
      if (kDebugMode) print("tillModifierGroups failed: $error");
      return const [];
    }
  }

  /// The negotiable lines of [productId] that are short today, which is what a
  /// `negotiable_short` refusal asks the customer about. Empty when nothing is, or the read
  /// failed.
  Future<List<RecipeShort>> shortOf(String productId) async {
    try {
      final read = RecipeAvailability.mapFrom(await api.post(
        path: "/inventory/recipes/availability",
        version: "v1",
        data: {"PRODUCT_IDS": [productId]}
      ));

      return read[productId]?.short ?? const [];
    } catch (error) {
      if (kDebugMode) print("tillShort failed: $error");
      return const [];
    }
  }

  @visibleForTesting
  void seed(Set<String> offered) {
    _offered = offered;
    notifyListeners();
  }
}
