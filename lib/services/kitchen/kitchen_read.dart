/// Readers of the kitchen's answers (`/inventory/recipes`, `/inventory/modifiers`,
/// `/inventory/presentations`). Quantities are numbers in each product's own unit, with up to
/// six decimals on a supply, so they are read as `double`; MySQL-backed figures arrive as text
/// often enough that both are taken.
library;

double? kitchenNum(dynamic raw) => switch (raw) {
  final num value => value.toDouble(),
  final String text => double.tryParse(text.trim()),
  _ => null
};

int kitchenInt(dynamic raw, [int fallback = 0]) => switch (raw) {
  final num value => value.toInt(),
  final String text => int.tryParse(text.trim()) ?? fallback,
  _ => fallback
};

String kitchenText(dynamic raw) => raw?.toString().trim() ?? "";

bool kitchenBool(dynamic raw) => raw == true || raw == 1 || raw == "1" || raw == "true";

DateTime? kitchenDate(dynamic raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

List<Map> kitchenMaps(dynamic raw) => raw is List ? [for (final item in raw) if (item is Map) item] : const [];

List<String> kitchenTexts(dynamic raw) => raw is List
  ? [for (final item in raw) if (kitchenText(item).isNotEmpty) kitchenText(item)]
  : const [];
