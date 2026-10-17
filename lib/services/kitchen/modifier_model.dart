import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_read.dart';

/// A product that offers a group, or an ingredient an option spends.
typedef ModifierProduct = ({String tableId, String productId});

/// What an option spends on top of the recipe, per unit, in the ingredient's own unit.
typedef ModifierLine = ({String tableId, String productId, double qty});

/// One choice of a group: «queso extra», «tres cuartos», «pan integral».
@immutable
class ModifierOption {
  const ModifierOption({
    this.id = "",
    required this.name,
    this.price = 0,
    this.lines = const [],
    this.remove = const [],
    this.paused = false,
    this.available
  });

  /// Sent back on every edit: open tickets name an option by it.
  final String id;
  final String name;

  /// Added to ONE unit of the product.
  final double price;
  final List<ModifierLine> lines;

  /// Recipe line ids it stops spending (white bread → whole wheat).
  final List<String> remove;
  final bool paused;

  /// Only in `modifiers/availability`: how many units the supplies give, `null` when it spends
  /// nothing, 0 when paused.
  final double? available;

  /// Whether it touches the recipe: it then only works on a product made to order.
  bool get spends => lines.isNotEmpty || remove.isNotEmpty;

  factory ModifierOption.fromJson(Map json) => ModifierOption(
    id: kitchenText(json["id"]),
    name: kitchenText(json["name"]),
    price: kitchenNum(json["price"]) ?? 0,
    lines: [
      for (final line in kitchenMaps(json["lines"]))
        if (kitchenText(line["productId"]).isNotEmpty) (
          tableId: kitchenText(line["tableId"]),
          productId: kitchenText(line["productId"]),
          qty: kitchenNum(line["qty"]) ?? 0
        )
    ],
    remove: kitchenTexts(json["remove"]),
    paused: kitchenBool(json["paused"]),
    available: kitchenNum(json["available"])
  );
}

/// A group of modifiers (`GET /inventory/modifiers`): what a customer chooses about a product.
/// `min: 1, max: 1` is «choose one» — the till can't charge without it.
@immutable
class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.name,
    this.min = 0,
    this.max,
    this.position = 0,
    this.products = const [],
    this.options = const []
  });

  final String id;
  final String name;
  final int min;

  /// `null` = as many as it has.
  final int? max;
  final int position;
  final List<ModifierProduct> products;
  final List<ModifierOption> options;

  /// Whether the product can't be sold without choosing from it (and Lyra can't sell it yet).
  bool get required => min > 0;

  factory ModifierGroup.fromJson(Map json) {
    final options = [for (final option in kitchenMaps(json["options"])) ModifierOption.fromJson(option)];
    final max = json["max"] == null ? null : kitchenInt(json["max"]);

    return ModifierGroup(
      id: kitchenText(json["id"]),
      name: kitchenText(json["name"]),
      min: kitchenInt(json["min"]),
      max: max,
      position: kitchenInt(json["position"]),
      products: [
        for (final product in kitchenMaps(json["products"]))
          if (kitchenText(product["productId"]).isNotEmpty)
            (tableId: kitchenText(product["tableId"]), productId: kitchenText(product["productId"]))
      ],
      options: options
    );
  }

  static ModifierGroup? read(dynamic data) =>
    data is Map && kitchenText(data["id"]).isNotEmpty ? ModifierGroup.fromJson(data) : null;

  /// The list, in the backend's order.
  static List<ModifierGroup> listFrom(dynamic data) => [
    for (final group in kitchenMaps(data))
      if (kitchenText(group["id"]).isNotEmpty) ModifierGroup.fromJson(group)
  ];
}
