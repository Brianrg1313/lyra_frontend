import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/inventory/product_image.dart';

const String _kOne = "11111111-2222-3333-4444-555555555555";
const String _kTwo = "66666666-7777-8888-9999-000000000000";

/// A photo as the backend returns it after uploading it.
Map<String, dynamic> _file(String id) => {
  "id": id,
  "scope": "media",
  "mime": "image/webp",
  "width": 1400,
  "height": 1400,
  "variants": [320]
};

void main() {
  setUp(() => CdnService().seed({
    "media": "https://cdn.test/rigel/media",
    "assets": "https://cdn.test/rigel/assets"
  }));

  tearDown(() => CdnService().clear());

  group('what a cell has stored', () {
    test('the list of ids the api writes', () {
      final images = ProductImage.from([_kOne, _kTwo]);

      expect(images.length, 2);
      // The first is the cover, and that order rules: the backend decides it,
      // not the screen.
      expect(images.first.id, _kOne);
      expect(images.first.isStored, isTrue);
    });

    test('a loose id, from before galleries existed', () {
      final images = ProductImage.from(_kOne);

      expect(images.length, 1);
      expect(images.single.id, _kOne);
    });

    test('an address an import brought', () {
      // Not a file of ours: a column of the company's. Told apart because the
      // two are deleted differently.
      final images = ProductImage.from("https://tienda.test/foto.jpg");

      expect(images.single.isStored, isFalse);
      expect(images.single.url, "https://tienda.test/foto.jpg");
    });

    test('a file name an import wrote waits for its file, and is kept', () {
      // The backend swaps it for the stored id when the file arrives (`Ingest`):
      // dropping it here would write the cell back without it.
      final images = ProductImage.from(["airforceone-white.png", _kOne]);

      expect(images.length, 2);
      expect(images.first.isPending, isTrue);
      expect(images.first.isStored, isFalse);
      expect(images.first.url, "");
      expect(ProductImage.valuesOf(images), ["airforceone-white.png", _kOne]);
    });

    test('an empty cell has no photos', () {
      expect(ProductImage.from(null), isEmpty);
      expect(ProductImage.from(""), isEmpty);
      expect(ProductImage.from(const []), isEmpty);
    });

    test('what cannot be drawn nor waited for is left out', () {
      // "sin foto" is what a company writes for none: not a photo, not a name.
      expect(ProductImage.from(["", "sin foto", "no-shape-at-all", _kOne]).length, 1);
    });
  });

  group('the addresses', () {
    test('are built with the base /init hands out', () {
      // The column stores ids, not addresses: a stored address ages the day
      // the CDN changes.
      expect(
        ProductImage.from(_kOne).single.url,
        "https://cdn.test/rigel/media/$_kOne"
      );
    });

    test('the thumbnail is the one the backend rendered', () {
      expect(
        ProductImage.from(_kOne).single.thumbnail,
        "https://cdn.test/rigel/media/$_kOne@$kProductImageWidth"
      );
    });

    test('an external photo has no thumbnail', () {
      // Nobody rendered one: it is downloaded as it is, which is all there is
      // of it.
      final image = ProductImage.from("https://tienda.test/foto.jpg").single;

      expect(image.thumbnail, image.url);
    });

    test('with no base yet there is nowhere to download it from', () {
      CdnService().clear();

      expect(ProductImage.from(_kOne).single.url, "");
    });
  });

  group('the gallery the backend answers', () {
    test('is kept as the list of ids, in order', () {
      final images = ProductImage.fromResponse({
        "file": _file(_kTwo),
        "images": [_file(_kOne), _file(_kTwo)]
      });

      expect(ProductImage.valuesOf(images), [_kOne, _kTwo]);
    });

    test('an external photo is kept as its address', () {
      final images = ProductImage.fromResponse({
        "images": [
          {"id": null, "scope": "external", "url": "https://tienda.test/foto.jpg"},
          _file(_kOne)
        ]
      });

      expect(
        ProductImage.valuesOf(images),
        ["https://tienda.test/foto.jpg", _kOne]
      );
    });

    test('a name still missing its file is kept as the name', () {
      final images = ProductImage.fromResponse({
        "images": [
          _file(_kOne),
          {"id": null, "scope": "missing", "name": "camión-rojo.jpg"}
        ]
      });

      expect(ProductImage.valuesOf(images), [_kOne, "camión-rojo.jpg"]);
      expect(images.last.isPending, isTrue);
    });

    test('a product left with no photos leaves the cell empty', () {
      expect(ProductImage.fromResponse({"images": []}), isEmpty);
      expect(ProductImage.fromResponse(null), isEmpty);
    });
  });
}
