import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_read.dart';

/// How a product is bought (`GET /inventory/presentations/:PRODUCT_ID`): «Saco» = 25 kg.
/// [qty] is what ONE holds, in the product's own unit.
@immutable
class Presentation {
  const Presentation({this.id = "", required this.name, required this.qty});

  /// Empty on one not saved yet. Sent back on a save, so the movements that name it keep it.
  final String id;
  final String name;
  final double qty;

  /// `{ productId, tableId, presentations: [{ id, name, qty }] }`, or the bare list.
  static List<Presentation> listFrom(dynamic data) => [
    for (final item in kitchenMaps(data is Map ? data["presentations"] : data))
      Presentation(id: kitchenText(item["id"]), name: kitchenText(item["name"]), qty: kitchenNum(item["qty"]) ?? 0)
  ];
}
