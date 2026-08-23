import 'package:intl/intl.dart';

import 'catalog_table.dart';

/// Naturaleza de una moneda. La manda el backend y sirve para agrupar el
/// selector: el dinero de curso legal primero y las cripto despues, que es como
/// llegan ordenadas.
enum CurrencyKind {
  fiat,
  crypto;

  static CurrencyKind from(dynamic raw) =>
    raw?.toString().toLowerCase() == "crypto" ? crypto : fiat;

  String get value => name;
}

/// Una moneda en la que se puede escribir un precio, tal como la lista `/init`.
///
/// La lista es del backend (`lyra_admin`.`currencies`, solo las habilitadas) y
/// no de esta app: **como se escribe un importe tampoco esta escrito aca**.
/// Cada moneda llega sabiendo lo que hace falta para escribir uno como lo
/// escribe quien lo cobra:
///
/// - El [symbol] y de que lado va ([leading]): `$22.23` pero `22.23€`.
/// - Si va pegado al importe o separado ([space]): `Bs. 22,23`.
/// - Con cuantos [decimals] se muestra: casi todas con dos, pero el peso
///   chileno y el guarani no tienen fraccion y `1.500,00` ahi no significa
///   nada, y una cripto puede tener ocho.
/// - Con que puntuacion se agrupa ([locale]): `1.234,56` o `1,234.56`. Es de la
///   **moneda** y no del idioma de la app a proposito: un precio es de quien lo
///   cobra, no de quien lo mira, y una lista de precios venezolana escrita
///   `Bs. 1,234.50` porque la app esta en ingles no es una cifra que su cliente
///   reconozca.
///
/// Asi, habilitar una moneda —o corregirle el simbolo a una— es una fila en el
/// backend y no una version nueva de la app.
class CurrencyModel {
  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    this.leading = true,
    this.space = false,
    this.decimals = 2,
    this.locale = "",
    this.kind = CurrencyKind.fiat
  });

  /// Codigo ISO 4217 en las de curso legal, el ticker en las cripto (`USDT`).
  /// En mayusculas: es el valor que viaja al backend.
  final String code;

  /// Nombre de la moneda, tal como llega.
  final String name;

  /// Lo que se dibuja en lugar del codigo (`$`, `€`, `Bs.`, `₿`).
  final String symbol;

  /// Si el simbolo va delante del importe.
  final bool leading;

  /// Si un espacio separa el simbolo del importe.
  final bool space;

  /// Cuantos decimales tiene la moneda de verdad: 0 en el peso chileno, 8 en
  /// bitcoin.
  final int decimals;

  /// Tag BCP-47 con el que se agrupa el importe (`es-VE` da `1.234,50`). Vacio
  /// si el catalogo no lo trae, y ahi se puntua con el idioma de la app.
  ///
  /// Es un tag y no un par de caracteres porque agrupar es un patron y no un
  /// separador: `es-VE` corta cada tres digitos y `hi-IN` escribe `12,34,567`,
  /// y no hay dos caracteres que digan esa diferencia.
  final String locale;

  final CurrencyKind kind;

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    final code = json["code"]?.toString().trim().toUpperCase() ?? "";
    final symbol = json["symbol"]?.toString().trim() ?? "";

    return CurrencyModel(
      code: code,
      name: json["name"]?.toString().trim() ?? "",
      // Sin simbolo se escribe con el codigo: un importe pelado en una columna
      // de precios no se lee como precio.
      symbol: symbol.isEmpty ? code : symbol,
      leading: json["position"]?.toString().toLowerCase() != "right",
      space: json["space"] == true || json["space"] == 1,
      decimals: _decimals(json["decimals"]),
      locale: json["locale"]?.toString().trim() ?? "",
      kind: CurrencyKind.from(json["type"])
    );
  }

  /// Las monedas del catalogo, en el orden que las manda el backend (las de
  /// curso legal primero, cada grupo alfabetico). Las que llegan sin codigo se
  /// descartan: es el dato que viaja.
  static List<CurrencyModel> fromResponse(dynamic data) {
    final currencies = <CurrencyModel>[];

    for (final row in catalogRows(data)) {
      final currency = CurrencyModel.fromJson(row);
      if (currency.code.isNotEmpty) currencies.add(currency);
    }

    return currencies;
  }

  /// Una moneda que no esta en el catalogo, escrita con lo unico que se sabe de
  /// ella: su codigo.
  ///
  /// Es para lo guardado que el catalogo no explica —una empresa que factura en
  /// una moneda que se deshabilito, o una pantalla que se pinto antes de que el
  /// catalogo llegara—. Se muestra el codigo tal cual en vez de caer en otra
  /// moneda: pintar `$` sobre un importe en bolivares es mentir sobre el dato.
  factory CurrencyModel.unknown(String code) {
    final value = code.trim().toUpperCase();

    return CurrencyModel(
      code: value,
      name: value,
      symbol: value,
      // Con espacio porque el simbolo es el codigo: `USD 22.23` se lee,
      // `USD22.23` no.
      space: true
    );
  }

  static int _decimals(dynamic raw) {
    final value = raw is num ? raw.toInt() : int.tryParse("$raw");
    if (value == null || value < 0) return 2;

    // Un tope defensivo: [NumberFormat] no acepta cualquier cantidad y el dato
    // sale de una tabla que se edita a mano.
    return value > 8 ? 8 : value;
  }

  /// El espacio que separa el simbolo del importe: `" "` o nada. Lo usa quien
  /// pinta el simbolo aparte y necesita el hueco del lado correcto.
  String get gap => space ? " " : "";

  bool get isCrypto => kind == CurrencyKind.crypto;

  /// Un formateador por puntuacion y cantidad de decimales, creado la primera
  /// vez que se lo pide y compartido desde ahi.
  ///
  /// Importa: una planilla de stock pinta miles de celdas de precio y cada
  /// [NumberFormat] nuevo se lee la tabla de simbolos de su locale. Son unos
  /// pocos objetos en toda la vida de la app.
  static final Map<String, NumberFormat> _formats = {};

  /// Con que se puntua: el tag de la moneda, y el idioma de la app cuando la
  /// moneda no trae ninguno (una fila vieja del catalogo, o una moneda armada a
  /// mano con [CurrencyModel.unknown]).
  String get _tag => locale.isEmpty ? Intl.getCurrentLocale() : locale;

  NumberFormat get _format => _formats["${_tag}_$decimals"] ??= _build();

  /// [NumberFormat] no conoce todos los tags: los que no estan en su tabla caen
  /// al idioma solo (`es-VE` → `es`), que es lo que se busca, pero uno que no
  /// sea un tag —el catalogo se edita a mano— lanza. Ahi se puntua con el
  /// idioma de la app: un precio mal agrupado se lee, una excepcion en medio de
  /// una planilla no.
  NumberFormat _build() {
    try {
      return NumberFormat.decimalPatternDigits(
        locale: _tag,
        decimalDigits: decimals
      );
    } catch (_) {
      return NumberFormat.decimalPatternDigits(
        locale: Intl.getCurrentLocale(),
        decimalDigits: decimals
      );
    }
  }

  /// El importe con la puntuacion y los decimales de esta moneda (`22.23`,
  /// `1,500.00`), o `null` si [raw] no se puede leer como numero.
  ///
  /// Ese `null` es el que decide que se ve: lo que no es un importe se muestra
  /// tal como se guardo y sin simbolo, en vez de desaparecer de la celda o
  /// mostrarse como cero.
  String? amount(String raw) {
    final value = parse(raw);
    return value == null ? null : _format.format(value);
  }

  /// El importe ya escrito entero, simbolo incluido. Es para donde no se puede
  /// pintar el simbolo aparte (un tooltip, un texto de una linea); la celda de
  /// la planilla usa [amount] y [symbol] por separado, que los muestra con
  /// distinto color.
  String? label(String raw) {
    final text = amount(raw);
    return text == null ? null : write(text);
  }

  /// Le pone el simbolo a un importe ya escrito, del lado y con el espacio que
  /// correspondan.
  String write(String amount) =>
    leading ? "$symbol$gap$amount" : "$amount$gap$symbol";

  /// Lee un importe escrito de cualquiera de las dos maneras.
  ///
  /// Los precios llegan de dos lados y no coinciden: el backend los manda con
  /// punto decimal (`22.23`) y quien los carga los escribe como los escribe su
  /// moneda (`22,23`, y a veces con separador de miles). Se toma como separador
  /// decimal **el ultimo** de los dos que aparezca y el otro como de miles, que
  /// es lo unico que distingue `1.234,56` de `1,234.56` sin preguntarle a nadie.
  static double? parse(String raw) {
    final text = raw.replaceAll(RegExp(r"\s"), "");
    if (text.isEmpty) return null;

    final decimal = text.lastIndexOf(",") > text.lastIndexOf(".") ? "," : ".";
    final group = decimal == "," ? "." : ",";

    return double.tryParse(
      text.replaceAll(group, "").replaceAll(decimal, ".")
    );
  }

  /// La igualdad es por valor y no por identidad porque asi se la lee: las
  /// celdas de precio se suscriben a la moneda de la empresa activa
  /// (`context.select`), que compara lo que devuelve con lo anterior para
  /// decidir si repintar. Comparadas por identidad, releer el catalogo
  /// repintaria toda la planilla aunque la moneda sea la misma.
  @override
  bool operator ==(Object other) =>
    other is CurrencyModel &&
    other.code == code &&
    other.symbol == symbol &&
    other.leading == leading &&
    other.space == space &&
    other.decimals == decimals &&
    other.locale == locale;

  @override
  int get hashCode =>
    Object.hash(code, symbol, leading, space, decimals, locale);

  @override
  String toString() => "CurrencyModel($code)";
}
