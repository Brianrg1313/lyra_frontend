import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';

/// El bloque `countries` de `/init`: la tabla columnar de `Response.parse`,
/// alfabetica por el nombre de cada pais en su propio idioma.
Map<String, dynamic> _payload() => {
  "keys": ["code", "name", "phone", "currency", "flag"],
  "values": [
    ["AR", "Argentina", "54", "ARS", "flag-ar"],
    ["CL", "Chile", "56", "CLP", null],
    ["VE", "Venezuela", "58", "VES", "flag-ve"]
  ]
};

void main() {
  // El catalogo es un singleton: se siembra antes de cada prueba y se vacia
  // despues, para que ninguna dependa de lo que dejo la anterior.
  setUp(() => CountryCatalogService().seed(_payload()));
  tearDown(() => CountryCatalogService().clear());

  test('lee la tabla columnar de /init', () {
    final catalog = CountryCatalogService();

    expect(catalog.isReady, isTrue);
    expect(catalog.total, 3);

    // El orden es el del backend: es el orden en que se ofrecen.
    expect(
      catalog.countries.map((country) => country.code),
      ["AR", "CL", "VE"]
    );
  });

  test('cada pais trae con que llenar lo que se deduce de el', () {
    final country = CountryCatalogService().byCode("VE")!;

    expect(country.name, "Venezuela");
    expect(country.phone, "58");
    expect(country.dial, "+58");
    expect(country.currency, "VES");
  });

  group('la bandera', () {
    // La bandera es un archivo de la plataforma: el catalogo trae su id y la
    // direccion se arma con la base que entrego `/init`.
    setUp(() => CdnService().seed({
      "media": "https://cdn.test/rigel/media",
      "assets": "https://cdn.test/rigel/assets"
    }));

    tearDown(() => CdnService().clear());

    test('se baja de donde estan las imagenes de la app', () {
      final country = CountryCatalogService().byCode("VE")!;

      expect(country.flag, "flag-ve");
      expect(country.flagUrl(), "https://cdn.test/rigel/assets/flag-ve");
      expect(country.flagUrl(32), "https://cdn.test/rigel/assets/flag-ve@32");
    });

    test('un pais sin bandera se ofrece igual', () {
      // Todavia no se subieron todas, y un pais sin icono se sigue eligiendo
      // por su nombre. Vacio se lee como "sin bandera".
      final country = CountryCatalogService().byCode("CL")!;

      expect(country.flag, isEmpty);
      expect(country.flagUrl(), isEmpty);
    });

    test('sin base no hay direccion, y tampoco un error', () {
      CdnService().clear();

      expect(CountryCatalogService().byCode("VE")!.flagUrl(), isEmpty);
    });
  });

  test('el codigo se busca como venga escrito', () {
    expect(CountryCatalogService().byCode("ve")?.name, "Venezuela");
    expect(CountryCatalogService().byCode(" ar ")?.name, "Argentina");
    expect(CountryCatalogService().byCode("US"), isNull);
    expect(CountryCatalogService().byCode(null), isNull);
  });

  test('un codigo que el catalogo no tiene se lee tal cual', () {
    // El pais es un dato de la empresa: esconderlo porque esta version no sabe
    // nombrarlo seria mostrar la ficha incompleta.
    expect(CountryCatalogService().nameOf("VE"), "Venezuela");
    expect(CountryCatalogService().nameOf("us"), "US");
    expect(CountryCatalogService().nameOf(null), "");
  });

  test('la moneda del pais se propone, no se impone', () {
    expect(CountryCatalogService().currencyOf("CL"), "CLP");
    expect(CountryCatalogService().currencyOf("US"), "");
  });

  group('el telefono se parte en codigo y numero', () {
    test('el codigo dice de que pais es', () {
      expect(CountryCatalogService().byPhone("+584121234567")?.code, "VE");
      expect(CountryCatalogService().byPhone("+541121234567")?.code, "AR");
    });

    test('gana el codigo mas largo que coincida', () {
      // `+1` es Estados Unidos y Canada, pero `+1868` no es ninguno de los dos:
      // sin la regla del mas largo, un telefono de Trinidad se leeria como
      // estadounidense.
      CountryCatalogService().seed({
        "keys": ["code", "name", "phone"],
        "values": [
          ["US", "United States", "1"],
          ["TT", "Trinidad and Tobago", "1868"]
        ]
      });

      expect(CountryCatalogService().byPhone("+18681234567")?.code, "TT");
      expect(CountryCatalogService().byPhone("+15551234567")?.code, "US");
    });

    test('lo guardado se carga en los dos campos', () {
      final phone = CountryCatalogService().splitPhone("+584121234567");

      expect(phone.dial, "58");
      expect(phone.number, "4121234567");
    });

    test('un telefono que no se reconoce queda entero en el numero', () {
      // Uno cargado sin codigo, o el de una region que se deshabilito: se
      // muestra como esta guardado en vez de atribuirselo a un pais que nadie
      // eligio.
      expect(CountryCatalogService().splitPhone("04121234567"),
        (dial: "", number: "04121234567"));

      expect(CountryCatalogService().splitPhone("+341234567"),
        (dial: "", number: "+341234567"));

      expect(CountryCatalogService().splitPhone(null),
        (dial: "", number: ""));
    });
  });

  test('lee tambien una lista de objetos', () {
    // Si el endpoint deja de comprimir, el parseo no se entera.
    CountryCatalogService().seed([
      {"code": "br", "name": "Brasil", "phone": "55", "currency": "brl"}
    ]);

    final country = CountryCatalogService().byCode("BR")!;

    expect(country.name, "Brasil");
    expect(country.currency, "BRL");
  });

  test('lo que no se entiende deja el catalogo vacio, no revienta', () {
    CountryCatalogService().seed(null);

    expect(CountryCatalogService().isReady, isFalse);
    expect(CountryCatalogService().countries, isEmpty);
  });

  test('un pais sin codigo no es una opcion', () {
    // El codigo es el dato que viaja: sin el no se puede guardar.
    CountryCatalogService().seed({
      "keys": ["code", "name"],
      "values": [
        ["", "Sin codigo"],
        ["VE", "Venezuela"]
      ]
    });

    expect(CountryCatalogService().total, 1);
  });

  test('una region habilitada aparece sin reiniciar la app', () {
    // Es todo el punto de que esto sea un catalogo y no un enumerado: llega una
    // fila nueva del backend y el catalogo avisa a quien lo este mirando.
    var notices = 0;
    final catalog = CountryCatalogService();

    void onChange() => notices++;

    catalog.addListener(onChange);
    addTearDown(() => catalog.removeListener(onChange));

    catalog.seed({
      "keys": ["code", "name"],
      "values": [
        ["AR", "Argentina"],
        ["CL", "Chile"],
        ["VE", "Venezuela"],
        ["UY", "Uruguay"]
      ]
    });

    expect(notices, 1);
    expect(catalog.byCode("UY")?.name, "Uruguay");
  });
}
