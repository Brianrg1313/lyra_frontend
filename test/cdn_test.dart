import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';

/// El bloque `cdn` de `/init`: las dos bases detras de las que se pone un id.
Map<String, dynamic> _payload() => {
  "media": "https://cdn.test/rigel/media",
  "assets": "https://cdn.test/rigel/assets"
};

/// El logo tal como lo describe el backend: un archivo, no una direccion.
Map<String, dynamic> _logo() => {
  "id": "f-1",
  "scope": "media",
  "mime": "image/webp",
  "width": 1024,
  "height": 1024,
  "variants": [128, 512]
};

void main() {
  // El servicio es un singleton, como los catalogos: se siembra antes de cada
  // prueba y se vacia despues.
  setUp(() => CdnService().seed(_payload()));
  tearDown(() => CdnService().clear());

  group('las bases', () {
    test('llegan en /init y se guardan tal cual', () {
      expect(CdnService().isReady, isTrue);
      expect(CdnService().media, "https://cdn.test/rigel/media");
      expect(CdnService().assets, "https://cdn.test/rigel/assets");
    });

    test('una base relativa se completa con el origen de la api', () {
      // Es lo que manda el backend cuando no hay CDN configurado: correcto para
      // una pagina servida desde su mismo host, inservible para esto.
      AppController.devMode = true;

      CdnService().seed({"media": "/rigel/media", "assets": "/rigel/assets"});

      expect(CdnService().media, "http://192.168.1.103/rigel/media");
    });

    test('la barra final no se arrastra a la direccion', () {
      CdnService().seed({
        "media": "https://cdn.test/media/",
        "assets": "https://cdn.test/assets/"
      });

      expect(CdnService().url(FileScope.media, "f-1"),
        "https://cdn.test/media/f-1");
    });

    test('lo que no se entiende deja lo que habia', () {
      // Un backend viejo o un despliegue a medias no puede dejar la app sin
      // poder bajar una imagen: lo que ya estaba sigue sirviendo.
      CdnService().seed(null);

      expect(CdnService().media, "https://cdn.test/rigel/media");
    });

    test('avisa al cambiar, que es lo que repinta lo que ya esta abierto', () {
      var notices = 0;
      final cdn = CdnService();

      void onChange() => notices++;

      cdn.addListener(onChange);
      addTearDown(() => cdn.removeListener(onChange));

      cdn.seed(_payload());

      expect(notices, 1);
    });
  });

  group('la direccion de un archivo', () {
    test('es la base y el id', () {
      expect(CdnService().url(FileScope.media, "f-1"),
        "https://cdn.test/rigel/media/f-1");
    });

    test('cada espacio tiene la suya', () {
      // Un id de una empresa pedido en el espacio de la plataforma es un 404:
      // no son dos carpetas del mismo lugar, son dos lugares.
      expect(CdnService().url(FileScope.assets, "f-1"),
        "https://cdn.test/rigel/assets/f-1");
    });

    test('una miniatura lleva el ancho detras del id', () {
      expect(CdnService().url(FileScope.media, "f-1", width: 128),
        "https://cdn.test/rigel/media/f-1@128");
    });

    test('sin base o sin id no hay direccion, y tampoco un error', () {
      expect(CdnService().url(FileScope.media, null), isEmpty);
      expect(CdnService().url(FileScope.media, "  "), isEmpty);

      CdnService().clear();

      expect(CdnService().url(FileScope.media, "f-1"), isEmpty);
      expect(CdnService().isReady, isFalse);
    });
  });

  group('el archivo elige su tamano', () {
    test('la mas chica que cubra el hueco', () {
      final logo = FileModel.from(_logo())!;

      // Un avatar de 44 se dibuja con la de 128 y no con la de un mega.
      expect(logo.sized(44), "https://cdn.test/rigel/media/f-1@128");
      expect(logo.sized(128), "https://cdn.test/rigel/media/f-1@128");

      // Pedir mas de lo que se renderizo trae la original: mas grande que el
      // hueco se ve bien, mas chica se ve borrosa.
      expect(logo.sized(200), "https://cdn.test/rigel/media/f-1@512");
      expect(logo.sized(4000), "https://cdn.test/rigel/media/f-1");
    });

    test('la miniatura es la mas chica que exista', () {
      expect(FileModel.from(_logo())!.thumbnail,
        "https://cdn.test/rigel/media/f-1@128");
    });

    test('un archivo sin miniaturas se baja entero', () {
      // Una imagen mas chica que el ancho de la miniatura se guarda sin
      // ninguna: pedirle una seria pedir algo que no esta.
      final small = FileModel.from({"id": "f-2", "variants": []})!;

      expect(small.thumbnail, "https://cdn.test/rigel/media/f-2");
      expect(small.sized(44), "https://cdn.test/rigel/media/f-2");
    });

    test('el archivo de la plataforma se baja de su base', () {
      final flag = FileModel.from({"id": "f-3", "scope": "assets"})!;

      expect(flag.url, "https://cdn.test/rigel/assets/f-3");
    });
  });

  group('el logo de una empresa', () {
    test('se arma con la base, no con lo que dijo la respuesta', () {
      // Es todo el punto: la empresa guarda un id y la direccion se arma al
      // mostrarla, asi que mudar las imagenes a otro dominio es una variable
      // del backend y no una migracion de todas las filas que las nombran.
      final profile = BusinessProfileModel.fromJson({
        "id": "b-1",
        "name": "Acme",
        "logo": _logo()
      });

      expect(profile.logo?.url, "https://cdn.test/rigel/media/f-1");

      CdnService().seed({
        "media": "https://otro.test/media",
        "assets": "https://otro.test/assets"
      });

      expect(profile.logo?.url, "https://otro.test/media/f-1");
    });
  });
}
