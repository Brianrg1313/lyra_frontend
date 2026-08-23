import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_model.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';

/// El bloque `currencies` de `/init`, tal como lo arma el backend: la tabla
/// columnar de `Response.parse`, las de curso legal primero y cada grupo
/// alfabetico.
Map<String, dynamic> _payload() => {
  "keys": [
    "code", "name", "symbol", "position", "locale", "space", "decimals", "type"
  ],
  "values": [
    ["CLP", "Peso chileno", r"$", "left", "es-CL", false, 0, "fiat"],
    ["EUR", "Euro", "€", "right", "de-DE", true, 2, "fiat"],
    ["USD", "US Dollar", r"$", "left", "en-US", false, 2, "fiat"],
    ["VES", "Bolivar", "Bs.", "right", "es-VE", true, 2, "fiat"],
    ["BTC", "Bitcoin", "₿", "left", "en-US", false, 8, "crypto"]
  ]
};

CurrencyModel _byCode(String code) =>
  CurrencyCatalogService().byCode(code)!;

void main() {
  // El catalogo es un singleton: se siembra antes de cada prueba y se vacia
  // despues, para que ninguna dependa de lo que dejo la anterior.
  setUp(() => CurrencyCatalogService().seed(_payload()));
  tearDown(() => CurrencyCatalogService().clear());

  group('lectura del catalogo', () {
    test('lee la tabla columnar de /init', () {
      final catalog = CurrencyCatalogService();

      expect(catalog.isReady, isTrue);
      expect(catalog.total, 5);

      // El orden es el del backend: es el orden en que se ofrecen.
      expect(
        catalog.currencies.map((currency) => currency.code),
        ["CLP", "EUR", "USD", "VES", "BTC"]
      );
    });

    test('lee tambien una lista de objetos', () {
      // Si el endpoint deja de comprimir, el parseo no se entera.
      CurrencyCatalogService().seed([
        {"code": "usd", "name": "US Dollar", "symbol": r"$", "decimals": 2}
      ]);

      expect(CurrencyCatalogService().byCode("USD")?.name, "US Dollar");
    });

    test('las columnas se leen por nombre y no por posicion', () {
      // El backend puede reordenarlas o agregar una sin romper la app.
      CurrencyCatalogService().seed({
        "keys": ["symbol", "type", "code", "name"],
        "values": [
          ["Bs.", "fiat", "VES", "Bolivar"]
        ]
      });

      final currency = _byCode("VES");

      expect(currency.symbol, "Bs.");
      expect(currency.name, "Bolivar");
    });

    test('lo que no se entiende deja el catalogo vacio, no revienta', () {
      CurrencyCatalogService().seed("no");

      expect(CurrencyCatalogService().isReady, isFalse);
      expect(CurrencyCatalogService().currencies, isEmpty);
    });

    test('una moneda sin codigo no es una opcion', () {
      // El codigo es el dato que viaja: sin el no se puede guardar.
      CurrencyCatalogService().seed({
        "keys": ["code", "name"],
        "values": [
          ["", "Sin codigo"],
          ["USD", "US Dollar"]
        ]
      });

      expect(CurrencyCatalogService().total, 1);
    });

    test('las cripto se pueden dejar afuera', () {
      expect(
        CurrencyCatalogService().fiat.map((currency) => currency.code),
        ["CLP", "EUR", "USD", "VES"]
      );

      expect(_byCode("BTC").isCrypto, isTrue);
    });

    test('el codigo se busca como venga escrito', () {
      expect(CurrencyCatalogService().byCode("usd")?.code, "USD");
      expect(CurrencyCatalogService().byCode(" eur ")?.code, "EUR");
      expect(CurrencyCatalogService().byCode("XYZ"), isNull);
      expect(CurrencyCatalogService().byCode(null), isNull);
    });
  });

  group('con que moneda se escribe un importe', () {
    test('con la del catalogo cuando esta', () {
      expect(CurrencyCatalogService().resolve("VES").symbol, "Bs.");
    });

    test('sin moneda declarada, con la de la app', () {
      expect(CurrencyCatalogService().resolve(null).code, "USD");
      expect(CurrencyCatalogService().resolve("").code, "USD");
    });

    test('una moneda que no esta en el catalogo se escribe con su codigo', () {
      // Lo importante es que no cae en otra: pintar "$" sobre un importe en
      // una moneda que la app no conoce es mentir sobre el dato.
      final currency = CurrencyCatalogService().resolve("XYZ");

      expect(currency.code, "XYZ");
      expect(currency.symbol, "XYZ");
      expect(currency.label("22.23"), "XYZ 22.23");
    });

    test('sin catalogo todavia se escribe igual', () {
      CurrencyCatalogService().clear();

      expect(CurrencyCatalogService().resolve("VES").code, "VES");
      expect(CurrencyCatalogService().resolve(null).code, "USD");
    });

    test('sin dolar en el catalogo, la primera de curso legal', () {
      CurrencyCatalogService().seed({
        "keys": ["code", "name", "symbol", "type"],
        "values": [
          ["BTC", "Bitcoin", "₿", "crypto"],
          ["VES", "Bolivar", "Bs.", "fiat"]
        ]
      });

      expect(CurrencyCatalogService().fallback.code, "VES");
    });
  });

  group('escritura del importe', () {
    test('el simbolo va del lado y con el espacio que dice el backend', () {
      expect(_byCode("USD").label("22.23"), r"$22.23");
      expect(_byCode("EUR").label("22.23"), "22,23 €");
      expect(_byCode("VES").label("22.23"), "22,23 Bs.");
    });

    test('cada moneda se escribe con los decimales que tiene', () {
      expect(_byCode("USD").amount("22.5"), "22.50");
      expect(_byCode("USD").amount("1234.5"), "1,234.50");

      // Un peso chileno no tiene centavos: "1.500,00" ahi no significa nada.
      expect(_byCode("CLP").amount("1500"), "1.500");

      expect(_byCode("BTC").amount("0.5"), "0.50000000");
    });

    test('cada moneda se agrupa como se agrupa en su pais', () {
      // Y no como se agrupa en el idioma de la app: un precio es de quien lo
      // cobra. Los dos importes son el mismo numero.
      expect(_byCode("USD").amount("1234.5"), "1,234.50");
      expect(_byCode("VES").amount("1234.5"), "1.234,50");
    });

    test('un locale que no esta en la tabla cae al idioma solo', () {
      // `es-VE` no tiene tabla propia: se puntua con la de `es`, que es lo que
      // se buscaba. Lo que no puede pasar es que lance en medio de una
      // planilla.
      CurrencyCatalogService().seed({
        "keys": ["code", "name", "symbol", "locale"],
        "values": [
          ["VES", "Bolivar", "Bs.", "es-VE"],
          ["XXX", "Rara", "X", "no-es-un-locale"]
        ]
      });

      expect(_byCode("VES").amount("1234.5"), "1.234,50");
      expect(_byCode("XXX").amount("1234.5"), isNotNull);
    });

    test('sin locale se puntua con el idioma de la app', () {
      // Una fila vieja del catalogo, o una moneda armada con lo poco que se
      // sabe de ella: se escribe igual, con la puntuacion de la pantalla.
      expect(CurrencyModel.unknown("XYZ").amount("1234.5"), "1,234.50");
    });

    test('un simbolo que no vino se reemplaza por el codigo', () {
      // Un numero pelado en una columna de precios no se lee como precio.
      CurrencyCatalogService().seed({
        "keys": ["code", "name"],
        "values": [
          ["XAF", "Franco CFA"]
        ]
      });

      expect(_byCode("XAF").symbol, "XAF");
    });

    test('lo que no es un importe no se inventa', () {
      // Devolver null es lo que le dice a la celda que muestre el dato crudo en
      // vez de un cero o una celda vacia.
      final usd = _byCode("USD");

      expect(usd.amount(""), isNull);
      expect(usd.amount("   "), isNull);
      expect(usd.amount("consultar"), isNull);
      expect(usd.label("consultar"), isNull);
    });
  });

  group('lectura del importe guardado', () {
    test('lee tanto el punto del backend como la coma de quien lo escribe', () {
      expect(CurrencyModel.parse("22.23"), 22.23);
      expect(CurrencyModel.parse("22,23"), 22.23);
      expect(CurrencyModel.parse(" 22,23 "), 22.23);
    });

    test('el separador decimal es el ultimo de los dos', () {
      // Es lo unico que distingue las dos formas de escribir mil doscientos
      // treinta y cuatro con cincuenta y seis sin preguntarle a nadie.
      expect(CurrencyModel.parse("1.234,56"), 1234.56);
      expect(CurrencyModel.parse("1,234.56"), 1234.56);
    });

    test('un importe escrito con coma se muestra en su moneda', () {
      // El borrador de una fila trae lo que se acaba de teclear, no lo que
      // devolvio el backend: la celda tiene que poder leerlo igual.
      expect(_byCode("USD").label("22,23"), r"$22.23");
    });
  });

  group('la moneda como valor', () {
    test('dos lecturas de la misma moneda son iguales', () {
      // De esto depende que releer el catalogo no repinte toda una planilla de
      // precios: las celdas se suscriben con `context.select`, que compara.
      final before = CurrencyCatalogService().resolve("USD");

      CurrencyCatalogService().seed(_payload());

      expect(CurrencyCatalogService().resolve("USD"), before);
    });

    test('una puntuacion corregida si es otra moneda', () {
      // Lo mismo que el simbolo: si el backend corrige el locale de una moneda,
      // las celdas que la muestran tienen que repintarse.
      final before = CurrencyCatalogService().resolve("VES");

      CurrencyCatalogService().seed({
        "keys": ["code", "name", "symbol", "position", "space", "locale"],
        "values": [
          ["VES", "Bolivar", "Bs.", "right", true, "en-US"]
        ]
      });

      expect(CurrencyCatalogService().resolve("VES"), isNot(before));
    });

    test('un simbolo corregido si es otra moneda', () {
      final before = CurrencyCatalogService().resolve("VES");

      CurrencyCatalogService().seed({
        "keys": ["code", "name", "symbol", "position", "space"],
        "values": [
          ["VES", "Bolivar", "Bs", "right", true]
        ]
      });

      expect(CurrencyCatalogService().resolve("VES"), isNot(before));
    });
  });

  group('la moneda de la empresa', () {
    test('la empresa arrastra el codigo, no la moneda resuelta', () {
      // Guardar el codigo es lo que deja que una correccion del catalogo llegue
      // a los precios ya pintados sin reiniciar la app.
      final business = BusinessModel.fromJson({
        "id": "1",
        "name": "Lyra",
        "currency": "eur"
      });

      expect(business.currency, "EUR");
      expect(business.toJson()["currency"], "EUR");
      expect(business.copyWith(name: "Otra").currency, "EUR");
    });

    test('la empresa que no declara moneda no inventa una', () {
      expect(BusinessModel.fromJson({"id": "1", "name": "Lyra"}).currency, "");
      expect(const BusinessModel(id: "1", name: "Lyra").currency, "");

      // Quien tenga que escribir un precio suyo le pide una al catalogo.
      expect(CurrencyCatalogService().resolve("").code, "USD");
    });
  });
}
