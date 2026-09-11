import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/pos/pos_product_model.dart';

/// Pins the contract of `POST /pos/catalog/`: the page the register's grid is
/// drawn from.
///
/// It is worth pinning because none of it is visible from the widget. The
/// products travel **compressed** —one list of keys and one row of values per
/// product— so a column that moves is a name shown as a price; the page carries
/// **no total**, so what ends the infinite scroll is `more` and nothing else;
/// and three of the fields are legitimately absent on tables that never had
/// that column, where reading a missing price as zero is a product the counter
/// gives away.
///
/// One page of the endpoint, written the way it answers it.
dynamic _page({
  String cursor = "68e2b1c0f0a1b2c3d4e5f601",
  bool more = true,
  List<List<dynamic>> products = const []
}) => {
  "table": "1f4d9e2a-3b5c-4d6e-8f70-a1b2c3d4e5f6",
  "size": 40,
  "cursor": more ? cursor : null,
  "more": more,
  "data": {
    "keys": const [
      "id", "name", "sku", "barcode",
      "price", "stock", "reserved", "image", "categories"
    ],
    "values": products
  }
};

void main() {
  test('a page decodes the nine columns a product travels as', () {
    final page = PosCatalogPage.fromResponse(_page(products: [
      [
        "68e2b1c0f0a1b2c3d4e5f601",
        "Running shoe",
        "SKU-01",
        "7791234567890",
        1250.5,
        7,
        2,
        {
          "id": "9a8b7c6d-5e4f-4a3b-9c8d-7e6f5a4b3c2d",
          "scope": "media",
          "url": "/rigel/media/9a8b7c6d"
        },
        ["Shoes", "Sport"]
      ]
    ]));

    expect(page.table, "1f4d9e2a-3b5c-4d6e-8f70-a1b2c3d4e5f6");
    expect(page.size, 40);
    expect(page.products, hasLength(1));

    final product = page.products.first;

    expect(product.id, "68e2b1c0f0a1b2c3d4e5f601");
    expect(product.name, "Running shoe");
    expect(product.sku, "SKU-01");
    expect(product.barcode, "7791234567890");
    expect(product.price, 1250.5);
    expect(product.stock, 7);
    expect(product.reserved, 2);
    expect(product.categories, ["Shoes", "Sport"]);

    // The cover comes already resolved by the backend, so what is kept is the
    // file id: the address is built with the base `/init` hands out, and one
    // stored per product would age the day the CDN changes.
    expect(product.image?.isStored, isTrue);
    expect(product.image?.id, "9a8b7c6d-5e4f-4a3b-9c8d-7e6f5a4b3c2d");
  });

  test('an address left by an import is read as an external picture', () {
    final page = PosCatalogPage.fromResponse(_page(products: [
      [
        "68e2b1c0f0a1b2c3d4e5f602", "Boot", null, null, 900, 1, 0,
        {"id": null, "scope": "external", "url": "https://shop.test/boot.png"},
        const []
      ]
    ]));

    final image = page.products.first.image;

    // It is not one of our files: it cannot be asked for by id nor deleted from
    // the backend, and it has no thumbnail either.
    expect(image?.isStored, isFalse);
    expect(image?.address, "https://shop.test/boot.png");
  });

  test('a product with no price keeps it null, and null is not zero', () {
    final page = PosCatalogPage.fromResponse(_page(products: [
      ["68e2b1c0f0a1b2c3d4e5f603", "No price", null, null, null, 3, 0, null, null],
      ["68e2b1c0f0a1b2c3d4e5f604", "Empty cell", null, null, "", 3, 0, null, null],
      ["68e2b1c0f0a1b2c3d4e5f605", "Free", null, null, 0, 3, 0, null, null]
    ]));

    // The table has no price column, or the row has nothing in it. Either way
    // the number has to be asked for before the sale is rung up, which is what
    // null says and what a zero would hide: a zero is a product given away.
    expect(page.products[0].price, isNull);
    expect(page.products[1].price, isNull);
    expect(page.products[2].price, 0);
  });

  test('what a product is called falls back to its codes', () {
    final page = PosCatalogPage.fromResponse(_page(products: [
      ["68e2b1c0f0a1b2c3d4e5f606", "Named", "SKU-06", "779", null, 0, 0, null, null],
      ["68e2b1c0f0a1b2c3d4e5f607", null, "SKU-07", "780", null, 0, 0, null, null],
      ["68e2b1c0f0a1b2c3d4e5f608", null, null, "781", null, 0, 0, null, null],
      ["68e2b1c0f0a1b2c3d4e5f609", null, null, null, null, 0, 0, null, null]
    ]));

    // A table holding nothing textual sends no name, and the row then travels
    // with its code: it is still findable, which an invented name is not.
    expect(page.products[0].label, "Named");
    expect(page.products[1].label, "SKU-07");
    expect(page.products[2].label, "781");
    expect(page.products[3].label, "");
  });

  test('a product the ledger never heard of reads zero and says so', () {
    final page = PosCatalogPage.fromResponse(_page(products: [
      ["68e2b1c0f0a1b2c3d4e5f60a", "Sold out", null, null, 10, 0, 0, null, null]
    ]));

    // Zero is what it has, not a missing figure: the product stays in the grid
    // —it can still be ordered— and is drawn as empty instead of hidden.
    expect(page.products.first.stock, 0);
    expect(page.products.first.isSoldOut, isTrue);
  });

  test('the last page carries no cursor, which is what ends the scroll', () {
    final full = PosCatalogPage.fromResponse(_page(products: [
      ["68e2b1c0f0a1b2c3d4e5f60b", "One", null, null, 1, 1, 0, null, null]
    ]));

    // There is no total to compare against —counting the whole filter is the
    // most expensive query on this path— so `more` and the cursor are the only
    // things that say whether to keep asking.
    expect(full.more, isTrue);
    expect(full.cursor, "68e2b1c0f0a1b2c3d4e5f601");

    final last = PosCatalogPage.fromResponse(_page(more: false, products: [
      ["68e2b1c0f0a1b2c3d4e5f60c", "Two", null, null, 1, 1, 0, null, null]
    ]));

    expect(last.more, isFalse);
    expect(last.cursor, isEmpty);
  });

  test('a filter the table cannot answer is an empty page, not a failure', () {
    // A code on a catalog with no code column, a category on one that
    // classifies nothing: the backend answers a page shaped like any other so
    // the grid's scroll ends instead of erroring.
    final page = PosCatalogPage.fromResponse(_page(more: false));

    expect(page.products, isEmpty);
    expect(page.more, isFalse);
    expect(page.table, isNotEmpty);
  });

  test('a body that was not understood decodes to nothing, and does not throw', () {
    // The service treats this as the failed read it is; what must not happen is
    // an exception in the middle of a page, which takes the whole grid with it.
    expect(PosCatalogPage.fromResponse(null).products, isEmpty);
    expect(PosCatalogPage.fromResponse("nope").products, isEmpty);
    expect(PosCatalogPage.fromResponse(const {"data": []}).products, isEmpty);
    expect(
      PosCatalogPage.fromResponse(const {"data": {"keys": [], "values": null}})
        .products,
      isEmpty
    );
  });

  test('a row shorter than the keys keeps the columns it does bring', () {
    // The keys are the contract and the row is read against them by position,
    // so a truncated row loses its tail and never shifts a price into a name.
    final page = PosCatalogPage.fromResponse(_page(products: [
      ["68e2b1c0f0a1b2c3d4e5f60d", "Half a row", "SKU-0d"]
    ]));

    final product = page.products.first;

    expect(product.name, "Half a row");
    expect(product.sku, "SKU-0d");
    expect(product.barcode, isEmpty);
    expect(product.price, isNull);
    expect(product.stock, 0);
    expect(product.categories, isEmpty);
  });
}
