/// Write bodies of the kitchen (`cocina-frontend.md`): recipes, the 86, batches, lost dishes,
/// presentations, modifier groups and the reports' windows. Client keys in capitals.
library;

// SERVICES
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';

/// A quantity as it travels: a whole number as an integer (a product for sale only takes
/// those), anything else with its decimals (up to six on a supply; the backend rounds).
num kitchenQuantity(double value) => value == value.roundToDouble() ? value.round() : value;

/// One line of a recipe being written.
typedef RecipeLineDraft = ({String tableId, String productId, double qty, bool negotiable, double waste});

/// One option of a choice being written: what ONE pick of it takes.
typedef RecipeChoiceOptionDraft = ({String tableId, String productId, double qty, double waste});

/// A choice being written ([RecipeChoice]): [id] empty for a new one, [name] may be.
typedef RecipeChoiceDraft = ({String id, String name, int choose, List<RecipeChoiceOptionDraft> options});

/// `PUT /inventory/recipes`: creates or replaces [productId]'s recipe: a supply's preparation
/// (a made record's travels with the record, `editRecordRequest`).
Map<String, dynamic> saveRecipeRequest({
  required String tableId,
  required String productId,
  required RecipeMode mode,
  required List<RecipeLineDraft> lines,
  List<RecipeChoiceDraft> choices = const []
}) => {
  "TABLE_ID": tableId,
  "PRODUCT_ID": productId,
  "MODE": mode.name,
  "LINES": recipeLinesRequest(lines, choices)
};

/// Lines as a recipe takes them, and a made record's `CONSUMES` (the same shape). A choice
/// travels as one more line, with `OPTIONS` instead of a product (`cocina-frontend.md` §3); its
/// `ID` goes back so the open tickets that name it keep it.
List<Map<String, dynamic>> recipeLinesRequest(List<RecipeLineDraft> lines, [List<RecipeChoiceDraft> choices = const []]) => [
  for (final line in lines) {
    "TABLE_ID": line.tableId,
    "PRODUCT_ID": line.productId,
    "QUANTITY": kitchenQuantity(line.qty),
    if (line.negotiable) "NEGOTIABLE": true,
    if (line.waste > 0) "WASTE": kitchenQuantity(line.waste)
  },
  for (final choice in choices) {
    if (choice.id.isNotEmpty) "ID": choice.id,
    if (choice.name.trim().isNotEmpty) "NAME": choice.name.trim(),
    "QUANTITY": choice.choose,
    "OPTIONS": [
      for (final option in choice.options) {
        "TABLE_ID": option.tableId,
        "PRODUCT_ID": option.productId,
        "QUANTITY": kitchenQuantity(option.qty),
        if (option.waste > 0) "WASTE": kitchenQuantity(option.waste)
      }
    ]
  }
];

/// The choices of a saved recipe as they are written back (a copy keeps them).
List<RecipeChoiceDraft> recipeChoicesDraft(List<RecipeChoice> choices, {bool keepIds = true}) => [
  for (final choice in choices) (
    id: keepIds ? choice.id : "",
    name: choice.name,
    choose: choice.choose,
    options: [
      for (final option in choice.options)
        (tableId: option.tableId, productId: option.productId, qty: option.qty, waste: option.waste)
    ]
  )
];

/// The ways ONE unit can be chosen, every choice together: [choose] picks among n options is
/// C(choose + n − 1, n − 1). The backend refuses more than [kitchenMaxSplits].
int recipeSplits(Iterable<({int choose, int options})> choices) {
  var total = 1;

  for (final (:choose, :options) in choices) {
    var ways = 1;
    for (var i = 1; i < options; i++) {
      ways = ways * (choose + i) ~/ i;
    }
    total *= ways;
  }

  return total;
}

/// What the backend takes of choices (`Choices`): per recipe, per choice, and splits in all.
const int kitchenMaxChoices = 5;
const int kitchenMaxOptions = 10;
const int kitchenMaxChoose = 10;
const int kitchenMaxSplits = 200;

/// `DELETE /inventory/recipes`: the product goes back to a shelf of its own.
Map<String, dynamic> deleteRecipeRequest({required String tableId, required String productId}) =>
  {"TABLE_ID": tableId, "PRODUCT_ID": productId};

/// `PUT /inventory/recipes/pause`: the 86, on or off.
Map<String, dynamic> pauseRecipeRequest({required String productId, required bool paused}) =>
  {"PRODUCT_ID": productId, "PAUSED": paused};

/// `POST /inventory/recipes/produce`: a batch of [quantity], [lost] of which went wrong (the
/// shelf rises by the rest; the supplies of all of it are spent).
Map<String, dynamic> produceBatchRequest({
  required String tableId,
  required String productId,
  required double quantity,
  double lost = 0,
  String note = ""
}) => {
  "TABLE_ID": tableId,
  "PRODUCT_ID": productId,
  "QUANTITY": kitchenQuantity(quantity),
  if (lost > 0) "LOST": kitchenQuantity(lost),
  if (note.trim().isNotEmpty) "NOTE": note.trim()
};

/// `POST /inventory/recipes/discard`: dishes made to order and lost (burned, dropped); their
/// supplies leave as spoiled. [without]: negotiable lines they went without.
Map<String, dynamic> discardDishRequest({
  required String tableId,
  required String productId,
  required int quantity,
  List<String> without = const [],
  String note = ""
}) => {
  "TABLE_ID": tableId,
  "PRODUCT_ID": productId,
  "QUANTITY": quantity,
  if (without.isNotEmpty) "WITHOUT": without,
  if (note.trim().isNotEmpty) "NOTE": note.trim()
};

/// One presentation being written: [id] empty for a new one.
typedef PresentationDraft = ({String id, String name, double qty});

/// `PUT /inventory/presentations`: replaces them all (`[]` removes every one). The ids of the
/// existing ones travel so they are kept.
Map<String, dynamic> savePresentationsRequest({
  required String tableId,
  required String productId,
  required List<PresentationDraft> presentations
}) => {
  "TABLE_ID": tableId,
  "PRODUCT_ID": productId,
  "PRESENTATIONS": [
    for (final item in presentations) {
      if (item.id.isNotEmpty) "ID": item.id,
      "NAME": item.name.trim(),
      "QUANTITY": kitchenQuantity(item.qty)
    }
  ]
};

/// `PUT /inventory/modifiers`: creates a group, or replaces [id]'s. Each option sends back its
/// id when it has one: open tickets name options by it.
Map<String, dynamic> saveModifierGroupRequest({
  String id = "",
  required String name,
  required int min,
  int? max,
  int? position,
  required List<ModifierProduct> products,
  required List<ModifierOption> options
}) => {
  if (id.isNotEmpty) "ID": id,
  "NAME": name.trim(),
  "MIN": min,
  "MAX": ?max,
  "POSITION": ?position,
  "PRODUCTS": [
    for (final product in products) {"TABLE_ID": product.tableId, "PRODUCT_ID": product.productId}
  ],
  "OPTIONS": [
    for (final option in options) {
      if (option.id.isNotEmpty) "ID": option.id,
      "NAME": option.name.trim(),
      "PRICE": kitchenQuantity(option.price),
      "LINES": [
        for (final line in option.lines)
          {"TABLE_ID": line.tableId, "PRODUCT_ID": line.productId, "QUANTITY": kitchenQuantity(line.qty)}
      ],
      "REMOVE": option.remove,
      "PAUSED": option.paused
    }
  ]
};

/// `DELETE /inventory/modifiers`.
Map<String, dynamic> deleteModifierGroupRequest({required String id}) => {"ID": id};

/// The window of a report: whole days, [from]'s start to [to]'s end, in ISO 8601. Either one
/// may be left open.
Map<String, dynamic> kitchenWindowRequest({DateTime? from, DateTime? to}) => {
  if (from != null) "FROM": DateTime(from.year, from.month, from.day).toUtc().toIso8601String(),
  if (to != null) "TO": DateTime(to.year, to.month, to.day + 1).subtract(const Duration(milliseconds: 1)).toUtc().toIso8601String()
};
