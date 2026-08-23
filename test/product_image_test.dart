import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/inventory/product_image.dart';

const String _kOne = "11111111-2222-3333-4444-555555555555";
const String _kTwo = "66666666-7777-8888-9999-000000000000";

/// Una foto tal como la devuelve el backend despues de subirla.
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

  group('lo que una celda tiene guardado', () {
    test('la lista de ids que escribe la api', () {
      final images = ProductImage.from([_kOne, _kTwo]);

      expect(images.length, 2);
      // La primera es la portada, y ese orden es el que manda: lo decide el
      // backend, no la pantalla.
      expect(images.first.id, _kOne);
      expect(images.first.isStored, isTrue);
    });

    test('un id suelto, de antes de que hubiera galerias', () {
      final images = ProductImage.from(_kOne);

      expect(images.length, 1);
      expect(images.single.id, _kOne);
    });

    test('una direccion que trajo una importacion', () {
      // No es un archivo nuestro: es una columna de la empresa. Se distingue
      // porque las dos cosas se borran distinto.
      final images = ProductImage.from("https://tienda.test/foto.jpg");

      expect(images.single.isStored, isFalse);
      expect(images.single.url, "https://tienda.test/foto.jpg");
    });

    test('una celda vacia no tiene fotos', () {
      expect(ProductImage.from(null), isEmpty);
      expect(ProductImage.from(""), isEmpty);
      expect(ProductImage.from(const []), isEmpty);
    });

    test('lo que no se puede dibujar se deja afuera', () {
      // Un resto de una importacion torcida no es una foto: la celda muestra lo
      // que se puede bajar.
      expect(ProductImage.from(["", "sin-forma-de-nada", _kOne]).length, 1);
    });
  });

  group('las direcciones', () {
    test('se arman con la base que reparte /init', () {
      // La columna guarda ids, no direcciones: una direccion guardada envejece
      // el dia que cambia el CDN.
      expect(
        ProductImage.from(_kOne).single.url,
        "https://cdn.test/rigel/media/$_kOne"
      );
    });

    test('la miniatura es la que renderizo el backend', () {
      expect(
        ProductImage.from(_kOne).single.thumbnail,
        "https://cdn.test/rigel/media/$_kOne@$kProductImageWidth"
      );
    });

    test('una foto externa no tiene miniatura', () {
      // No se la renderizo nadie: se baja tal como esta, que es lo unico que hay
      // de ella.
      final image = ProductImage.from("https://tienda.test/foto.jpg").single;

      expect(image.thumbnail, image.url);
    });

    test('sin base todavia no hay de donde bajarla', () {
      CdnService().clear();

      expect(ProductImage.from(_kOne).single.url, "");
    });
  });

  group('la galeria que contesta el backend', () {
    test('se guarda como la lista de ids, en orden', () {
      final images = ProductImage.fromResponse({
        "file": _file(_kTwo),
        "images": [_file(_kOne), _file(_kTwo)]
      });

      expect(ProductImage.valuesOf(images), [_kOne, _kTwo]);
    });

    test('una foto externa se guarda como su direccion', () {
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

    test('un producto que se quedo sin fotos deja la celda vacia', () {
      expect(ProductImage.fromResponse({"images": []}), isEmpty);
      expect(ProductImage.fromResponse(null), isEmpty);
    });
  });
}
