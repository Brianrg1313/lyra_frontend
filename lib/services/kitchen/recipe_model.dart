import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_read.dart';

/// How a product with a recipe is made (`cocina-frontend.md` §1).
enum RecipeMode {
  /// Made when ordered: no shelf of its own, what its supplies allow is measured on every read.
  order,

  /// Made ahead by the batch: a shelf of its own, filled by producing a batch.
  batch;

  static RecipeMode from(dynamic raw) => kitchenText(raw).toLowerCase() == "batch" ? batch : order;
}

/// One line of a recipe: how much of one ingredient ONE unit of the product takes.
@immutable
class RecipeLine {
  const RecipeLine({
    required this.id,
    required this.tableId,
    required this.productId,
    this.name = "",
    this.qty = 0,
    this.negotiable = false,
    this.waste = 0
  });

  /// What a sale names in `WITHOUT` and a modifier in `REMOVE`.
  final String id;
  final String tableId;
  final String productId;

  /// The ingredient's name; empty in the answer of a write (`PUT` sends none).
  final String name;

  /// In the ingredient's own unit, already rounded by the backend: shown as it comes.
  final double qty;

  /// Can be left out when the customer agrees (a garnish): never makes the product unavailable.
  final bool negotiable;

  /// Percent lost while making it (0 ≤ waste < 100), spent on top of [qty].
  final double waste;

  factory RecipeLine.fromJson(Map json) => RecipeLine(
    id: kitchenText(json["id"]),
    tableId: kitchenText(json["tableId"]),
    productId: kitchenText(json["productId"]),
    name: kitchenText(json["name"]),
    qty: kitchenNum(json["qty"]) ?? 0,
    negotiable: kitchenBool(json["negotiable"]),
    waste: kitchenNum(json["waste"]) ?? 0
  );

  RecipeLine named(String name) => RecipeLine(
    id: id,
    tableId: tableId,
    productId: productId,
    name: name,
    qty: qty,
    negotiable: negotiable,
    waste: waste
  );
}

/// A product's recipe (`GET /inventory/recipes/:PRODUCT_ID`): one per product.
@immutable
class Recipe {
  const Recipe({
    required this.productId,
    required this.tableId,
    this.mode = RecipeMode.order,
    this.paused = false,
    this.version = 0,
    this.updated,
    this.lines = const []
  });

  final String productId;
  final String tableId;
  final RecipeMode mode;

  /// The 86: reads 0 everywhere and its sale is refused, whatever it has left.
  final bool paused;
  final int version;
  final DateTime? updated;
  final List<RecipeLine> lines;

  List<RecipeLine> get negotiable => [for (final line in lines) if (line.negotiable) line];

  /// The answer of a read or a write, or `null` when it is not a recipe.
  static Recipe? read(dynamic data) {
    if (data is! Map || kitchenText(data["productId"]).isEmpty) return null;

    return Recipe(
      productId: kitchenText(data["productId"]),
      tableId: kitchenText(data["tableId"]),
      mode: RecipeMode.from(data["mode"]),
      paused: kitchenBool(data["paused"]),
      version: kitchenInt(data["version"]),
      updated: kitchenDate(data["updated"]),
      lines: [for (final line in kitchenMaps(data["lines"])) RecipeLine.fromJson(line)]
    );
  }

  /// The same recipe with its lines named from [before] and [names] (product id → name): a
  /// write answers without names.
  Recipe namedAfter(Recipe? before, [Map<String, String> names = const {}]) {
    final known = {
      ...names,
      for (final line in before?.lines ?? const <RecipeLine>[])
        if (line.name.isNotEmpty) line.productId: line.name
    };

    return Recipe(
      productId: productId,
      tableId: tableId,
      mode: mode,
      paused: paused,
      version: version,
      updated: updated,
      lines: [for (final line in lines) line.name.isEmpty ? line.named(known[line.productId] ?? "") : line]
    );
  }
}

/// A recipe that uses a product (`POST /inventory/recipes/uses`): what deleting it would break.
@immutable
class RecipeUse {
  const RecipeUse({required this.productId, this.tableId = "", this.mode = RecipeMode.order, this.name = ""});

  final String productId;
  final String tableId;
  final RecipeMode mode;
  final String name;

  static List<RecipeUse> listFrom(dynamic data) => [
    for (final use in kitchenMaps(data))
      if (kitchenText(use["productId"]).isNotEmpty) RecipeUse(
        productId: kitchenText(use["productId"]),
        tableId: kitchenText(use["tableId"]),
        mode: RecipeMode.from(use["mode"]),
        name: kitchenText(use["name"])
      )
  ];
}
