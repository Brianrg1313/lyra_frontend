import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/kitchen/kitchen_api.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// Status of one product's recipe: [none] is a product without one (`404 recipe_not_found`),
/// news and not an error.
enum RecipeStatus { loading, ready, none, error }

/// What a batch left: how much was made and lost, and the negotiable lines it went without.
typedef BatchResult = ({double made, double lost, List<String> skipped});

/// One product's recipe, what it makes now and how it is bought: the product's panel.
///
/// **Created per opened panel**, never cached: a recipe is read when looked at, and every write
/// answers the recipe, which replaces the one held (its lines named from the one before: a write
/// answers without names). Availability is read again after each write, since a recipe is what
/// it is measured from.
class RecipeService extends ChangeNotifier {
  RecipeService({required this.product, InventorySource? records}) : _source = records;

  final KitchenProduct product;
  final InventorySource? _source;

  InventorySource get _records => _source ?? Sources.inventory;

  RecipeStatus _status = RecipeStatus.loading;
  Recipe? _recipe;
  RecipeAvailability? _availability;
  List<Presentation> _presentations = const [];
  bool _presentationsRead = false;
  bool _disposed = false;

  RecipeStatus get status => _status;
  Recipe? get recipe => _recipe;
  RecipeAvailability? get availability => _availability;
  List<Presentation> get presentations => _presentations;

  /// Whether the presentations could be read: a dish made to order has none
  /// (`product_is_composite`), and a failure leaves the block out rather than empty.
  bool get presentationsRead => _presentationsRead;

  String get _path => "/inventory/recipes";

  /// [productId]'s recipe, or `null` when it has none or it can't be read: what a modifier's
  /// option names the lines of (`REMOVE`).
  static Future<Recipe?> fetch(String productId) async {
    try {
      return Recipe.read(await api.get(path: "/inventory/recipes/$productId", version: "v1"));
    } catch (error) {
      if (kDebugMode) print("recipe fetch failed: $error");
      return null;
    }
  }

  /// Reads the recipe, what it makes now and the presentations, side by side.
  Future<void> load() async {
    _status = RecipeStatus.loading;
    _notify();

    await Future.wait([_readRecipe(), _readAvailability(), _readPresentations()]);

    _notify();
  }

  Future<void> _readRecipe() async {
    try {
      _recipe = Recipe.read(await api.get(path: "$_path/${product.id}", version: "v1"));
      _status = _recipe == null ? RecipeStatus.error : RecipeStatus.ready;
    } catch (error) {
      if (KitchenApi.reason(error) == "recipe_not_found") {
        _recipe = null;
        _status = RecipeStatus.none;
        return;
      }

      if (kDebugMode) print("recipe read failed: $error");
      _status = RecipeStatus.error;
    }
  }

  Future<void> _readAvailability() async {
    try {
      final answer = RecipeAvailability.mapFrom(await api.post(
        path: "$_path/availability",
        version: "v1",
        data: {"PRODUCT_IDS": [product.id]}
      ));

      _availability = answer[product.id];
    } catch (error) {
      if (kDebugMode) print("recipe availability failed: $error");
      _availability = null;
    }
  }

  Future<void> _readPresentations() async {
    try {
      _presentations = Presentation.listFrom(await api.get(path: "/inventory/presentations/${product.id}", version: "v1"));
      _presentationsRead = true;
    } catch (error) {
      if (kDebugMode) print("presentations read failed: $error");
      _presentations = const [];
      _presentationsRead = false;
    }
  }

  /// Creates or replaces the recipe. [names] (product id → name) names the new lines.
  ///
  /// A made product's recipe is part of its record (`cocina-frontend.md` §3): it is written as
  /// the record's `CONSUMES` and `BATCH` (`PUT /inventory/products/records/manage`), which
  /// answers only the id, so the recipe is read again. A supply's preparation is
  /// `PUT /inventory/recipes`, which answers it.
  Future<bool> save(
    BuildContext context, {
    required RecipeMode mode,
    required List<RecipeLineDraft> lines,
    Map<String, String> names = const {}
  }) => _write(context, "saveRecipe", () async {
    if (product.made) {
      await _records.editRecord(editRecordRequest(
        tableId: product.tableId,
        id: product.id,
        consumes: lines,
        batch: mode == RecipeMode.batch
      ));

      final before = _recipe;
      await _readRecipe();
      _recipe = _recipe?.namedAfter(before, names);
      return;
    }

    final saved = Recipe.read(await api.put(
      path: _path,
      version: "v1",
      data: saveRecipeRequest(tableId: product.tableId, productId: product.id, mode: mode, lines: lines)
    ));

    if (saved != null) {
      _recipe = saved.namedAfter(_recipe, names);
      _status = RecipeStatus.ready;
    }
  });

  /// Whether the recipe can be removed: a made product never goes without one
  /// (`409 recipe_required`); deleting it is deleting the record.
  bool get removable => !product.made;

  /// Deletes the recipe: the product has a shelf of its own again (almost always empty).
  Future<bool> remove(BuildContext context) => _write(context, "deleteRecipe", () async {
    await api.delete(path: _path, version: "v1", data: deleteRecipeRequest(tableId: product.tableId, productId: product.id));

    _recipe = null;
    _status = RecipeStatus.none;
  });

  /// The 86: [paused] reads 0 everywhere and refuses its sale.
  Future<bool> pause(BuildContext context, bool paused) => _write(context, "pauseRecipe", () async {
    final saved = Recipe.read(await api.put(
      path: "$_path/pause",
      version: "v1",
      data: pauseRecipeRequest(productId: product.id, paused: paused)
    ));

    if (saved != null) _recipe = saved.namedAfter(_recipe);
  });

  /// The recipes that use this product: what deleting it, or its recipe, would leave short.
  /// A failure answers `null`: the caller can't promise it is used nowhere.
  Future<List<RecipeUse>?> uses() async {
    try {
      return RecipeUse.listFrom(await api.post(path: "$_path/uses", version: "v1", data: {"PRODUCT_ID": product.id}));
    } catch (error) {
      if (kDebugMode) print("recipe uses failed: $error");
      return null;
    }
  }

  /// Produces a batch (`batch` recipes only). Answers what it made, or `null` when refused.
  Future<BatchResult?> produce(BuildContext context, {required double quantity, double lost = 0, String note = ""}) async {
    BatchResult? result;

    final done = await _write(context, "produceBatch", () async {
      final answer = await api.post(
        path: "$_path/produce",
        version: "v1",
        data: produceBatchRequest(tableId: product.tableId, productId: product.id, quantity: quantity, lost: lost, note: note)
      );

      result = _batch(answer);
    });

    return done ? result : null;
  }

  BatchResult _batch(dynamic answer) {
    final map = answer is Map ? answer : const {};
    final skipped = map["skipped"];
    final lines = {for (final line in _recipe?.lines ?? const <RecipeLine>[]) line.id: line};

    return (
      made: switch (map["made"]) { final num value => value.toDouble(), _ => 0.0 },
      lost: switch (map["lost"]) { final num value => value.toDouble(), _ => 0.0 },
      skipped: [
        if (skipped is List)
          // Line ids: named from the recipe.
          for (final id in skipped)
            if (id != null) lines[id.toString()]?.name ?? id.toString()
      ]
    );
  }

  /// Records [quantity] dishes made to order and lost; their supplies leave as spoiled.
  Future<bool> discard(BuildContext context, {required int quantity, List<String> without = const [], String note = ""}) =>
    _write(context, "discardDish", () => api.post(
      path: "$_path/discard",
      version: "v1",
      data: discardDishRequest(tableId: product.tableId, productId: product.id, quantity: quantity, without: without, note: note)
    ));

  /// Replaces how the product is bought.
  Future<bool> savePresentations(BuildContext context, List<PresentationDraft> presentations) =>
    _write(context, "savePresentations", () async {
      _presentations = Presentation.listFrom(await api.put(
        path: "/inventory/presentations",
        version: "v1",
        data: savePresentationsRequest(tableId: product.tableId, productId: product.id, presentations: presentations)
      ));
      _presentationsRead = true;
    }, measure: false);

  Future<bool> _write(BuildContext context, String name, Future<dynamic> Function() send, {bool measure = true}) async {
    try {
      await send();
    } catch (error) {
      if (context.mounted) KitchenApi.report(context, name, error);
      return false;
    }

    if (measure) await _readAvailability();
    _notify();

    return true;
  }

  /// Seeds the panel, for tests.
  @visibleForTesting
  void seed({Recipe? recipe, RecipeAvailability? availability, List<Presentation> presentations = const []}) {
    _recipe = recipe;
    _availability = availability;
    _presentations = presentations;
    _presentationsRead = true;
    _status = recipe == null ? RecipeStatus.none : RecipeStatus.ready;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
