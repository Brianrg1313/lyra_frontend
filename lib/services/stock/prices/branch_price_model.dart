// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// A product's own price at one branch (`sedes-frontend.md` §6), a row of
/// `POST /inventory/products/prices`. A branch with no row sells at the catalog's price.
///
/// - [price] null is the catalog's price.
/// - [inheritsDiscount] true is the product's own offer (its `DISCOUNT` cell).
/// - [inheritsDiscount] false with [discount] null is no offer at that branch.
class BranchPrice {
  const BranchPrice({
    required this.productId,
    required this.branchId,
    this.branch = "",
    this.price,
    this.discount,
    this.inheritsDiscount = true,
    this.updated
  });

  final String productId;
  final String branchId;

  /// The branch's name, as the backend joined it.
  final String branch;

  final double? price;

  /// A percentage.
  final double? discount;

  final bool inheritsDiscount;
  final DateTime? updated;

  static BranchPrice? from(dynamic row) {
    if (row is! Map) return null;

    final product = _text(row["product_id"]);
    final branch = _text(row["branch_id"]);
    if (product.isEmpty || branch.isEmpty) return null;

    return BranchPrice(
      productId: product,
      branchId: branch,
      branch: _text(row["branch"]),
      price: _number(row["price"]),
      discount: _number(row["discount"]),
      inheritsDiscount: row["inherits_discount"] == true || row["inherits_discount"] == 1,
      updated: row["updated"] == null ? null : DateTime.tryParse(row["updated"].toString())?.toLocal()
    );
  }

  /// The rows of an answer, compressed (`{keys, values}`) or not.
  static List<BranchPrice> listFrom(dynamic data) => [
    for (final row in data is List ? data : catalogRows(data is Map && data["prices"] != null ? data["prices"] : data))
      ?BranchPrice.from(row)
  ];
}

/// `PUT /inventory/products/prices`: [productId]'s price at the header's branch. At least one of
/// the two travels; a [discount] of `0` (or [clearDiscount]) takes the branch's offer off.
Map<String, dynamic> setBranchPriceRequest({
  required String productId,
  String tableId = "",
  double? price,
  double? discount,
  bool clearDiscount = false
}) => {
  "PRODUCT_ID": productId,
  if (tableId.isNotEmpty) "TABLE_ID": tableId,
  "PRICE": ?price,
  if (clearDiscount) "DISCOUNT": null else "DISCOUNT": ?discount
};

/// `DELETE /inventory/products/prices`: the header's branch goes back to the catalog's price.
Map<String, dynamic> removeBranchPriceRequest(String productId) => {"PRODUCT_ID": productId};

String _text(dynamic value) => value?.toString().trim() ?? "";

double? _number(dynamic value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text.trim()),
  _ => null
};
