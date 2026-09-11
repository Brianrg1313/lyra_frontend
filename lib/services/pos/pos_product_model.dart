// SERVICES
import 'package:app/services/inventory/product_image.dart';

/// One product as the register draws it, from `POST /pos/catalog/`.
///
/// It is not a row of a table: the backend resolves the company's columns by
/// **type** and answers with a product —a name, a code, a price, a picture and
/// what is left of it—, which is the only shape a counter can draw. That is why
/// this model has fixed fields and not a map of columns like the sheet or the
/// stock summary do: which column holds the price is decided once, on the
/// backend, and the same one the ticket is rung up with.
///
/// Almost everything is nullable and none of the nulls collapse into a default:
/// a table can have no code column, no picture column or no price column, and a
/// product without a price is a product the checkout has to be **asked** for,
/// not one that costs zero.
class PosProduct {
  const PosProduct({
    required this.id,
    this.name = "",
    this.sku = "",
    this.barcode = "",
    this.price,
    this.stock = 0,
    this.reserved = 0,
    this.image,
    this.categories = const []
  });

  /// Identifier of the record, which is what a sale is rung up with.
  final String id;

  /// What the product is called. Empty on a table holding nothing textual: the
  /// backend sends null there and the tile falls back to the code.
  final String name;

  /// The company's own code, empty when the table has no `sku` column.
  final String sku;

  /// The code printed on the product, empty when there is no `barcode` column.
  final String barcode;

  /// What it sells for, or null when the table has no price column or the row
  /// has nothing in it. **Null is not zero**: zero is free and null is a price
  /// that has to be asked for.
  final double? price;

  /// Units left to sell, from the inventory ledger and not from the stock
  /// column mirrored into the record. A product the ledger has never been told
  /// about reads 0, which is what it has.
  final int stock;

  /// Units held for someone. Not shown next to the stock —it is a different
  /// question— but it travels because it is the other half of the balance.
  final int reserved;

  /// Cover picture, already resolved by the backend, or null without one.
  final ProductImage? image;

  /// Every label the product's `categories` columns hold. It is what the strip
  /// filters by, and it is kept so a tile can say which ones it carries.
  final List<String> categories;

  /// What to write on the tile: the name, and the code when the table holds no
  /// name column. Empty only when the product has neither, which is a row the
  /// tile announces as unnamed rather than drawing a blank.
  String get label => name.isNotEmpty
    ? name
    : sku.isNotEmpty
      ? sku
      : barcode;

  /// Whether there is anything left to sell. Zero is a real answer —the shelf
  /// is empty— and it is drawn as such instead of hiding the product: it is
  /// still in the catalog and can still be ordered.
  bool get isSoldOut => stock <= 0;

  /// The same product with the balance the ledger just announced.
  ///
  /// It exists because the grid is told about stock twice: once by the page it
  /// was read in, and from then on by `stock/changed` every time anybody moves
  /// those units — another till putting them on a ticket, a bot reserving them,
  /// a restock. Everything else about the product is left exactly as it was
  /// read: the notice is about a balance and says nothing about a name or a
  /// price.
  PosProduct withBalance({required int stock, required int reserved}) => PosProduct(
    id: id,
    name: name,
    sku: sku,
    barcode: barcode,
    price: price,
    stock: stock,
    reserved: reserved,
    image: image,
    categories: categories
  );

  /// Reads one row of the compressed page, given the keys it travels with.
  factory PosProduct.fromEntry(Map<String, dynamic> entry) => PosProduct(
    id: (entry["id"] ?? "").toString(),
    name: _text(entry["name"]),
    sku: _text(entry["sku"]),
    barcode: _text(entry["barcode"]),
    price: _price(entry["price"]),
    stock: _int(entry["stock"]) ?? 0,
    reserved: _int(entry["reserved"]) ?? 0,
    image: _cover(entry["image"]),
    categories: _categories(entry["categories"])
  );

  /// The cover as the backend already resolved it (`{ id, scope, url }` for one
  /// of ours, `{ id: null, url }` for the address an import left), which is why
  /// it is not read with [ProductImage.from]: that one expects what the cell
  /// stores, and this never reaches the client.
  static ProductImage? _cover(dynamic raw) {
    if (raw == null) return null;

    final images = ProductImage.from(
      raw is Map ? (raw["id"] ?? raw["url"] ?? raw["URL"]) : raw
    );

    return images.isEmpty ? null : images.first;
  }

  static List<String> _categories(dynamic raw) => raw is List
    ? [
        for (final label in raw)
          if (label != null && label.toString().isNotEmpty) label.toString()
      ]
    : const [];

  static String _text(dynamic raw) => raw?.toString() ?? "";

  /// The price as the number it is, or null when the row carries none. The
  /// empty cases are checked before parsing and not after, for the same reason
  /// the backend checks them: an empty price read as zero is a product the
  /// counter gives away.
  static double? _price(dynamic raw) => switch (raw) {
    final num value => value.toDouble(),
    final String text when text.trim().isNotEmpty => double.tryParse(text),
    _ => null
  };

  static int? _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };
}

/// A page of the catalog: the products of one batch and where the next one
/// starts.
///
/// **It pages by cursor and brings no total.** The grid loads as it is scrolled,
/// so the backend answers the id of the last product of the page and whether
/// there is another one behind it; counting the whole filter would be the most
/// expensive query on this path and an infinite scroll has no use for the
/// number. Whoever paginates is `PosCatalogService`.
class PosCatalogPage {
  const PosCatalogPage({
    this.table = "",
    this.size = 0,
    this.cursor = "",
    this.more = false,
    this.products = const []
  });

  /// The catalog that was read. **It is not asked for**: the backend answers
  /// for the company's main table (`tables`.`primary`, the one the checkout
  /// sells from) and says which one it was.
  final String table;

  final int size;

  /// Where the next page starts, empty when this was the last one. The backend
  /// only sends it while there is more to load.
  final String cursor;

  /// Whether there is another page behind this one.
  final bool more;

  final List<PosProduct> products;

  /// Decodes `{ table, size, cursor, more, data }`, with the products
  /// compressed in `{ keys, values }` —`keys` being the field names, so they
  /// are not repeated on every product.
  factory PosCatalogPage.fromResponse(dynamic data) {
    if (data is! Map) return const PosCatalogPage();

    return PosCatalogPage(
      table: (data["table"] ?? data["TABLE"] ?? "").toString(),
      size: _int(data["size"] ?? data["SIZE"]) ?? 0,
      cursor: (data["cursor"] ?? data["CURSOR"] ?? "").toString(),
      more: data["more"] == true || data["MORE"] == true,
      products: _products(data["data"] ?? data["DATA"])
    );
  }

  static List<PosProduct> _products(dynamic raw) {
    if (raw is! Map) return const [];

    final keys = raw["keys"] ?? raw["KEYS"];
    final values = raw["values"] ?? raw["VALUES"];

    if (keys is! List || values is! List) return const [];

    return [
      for (final row in values)
        if (row is List)
          PosProduct.fromEntry({
            for (int i = 0; i < keys.length && i < row.length; i++)
              keys[i].toString(): row[i]
          })
    ];
  }

  static int? _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };
}
