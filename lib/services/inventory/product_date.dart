import 'package:flutter/services.dart';

// PACKAGES
import 'package:intl/intl.dart';

/// Una fecha de una celda de la planilla: lo que se guardo, entendido.
///
/// Existe porque una columna de fechas recibe fechas escritas de cualquier
/// manera. Nadie tipea `2026-02-12` en una planilla: tipea `12/2/26`, o pega una
/// columna de un Excel, o importa un CSV que trae otra cosa. Aca se reconocen
/// todas y se escriben de una sola forma (ver [stored]), asi que la tabla
/// converge a una fecha de verdad sin obligar a nadie a escribir en el formato
/// del backend.
///
/// **El dia es el dia.** No se convierte de zona horaria en ningun momento: la
/// fecha de vencimiento de un producto es un dia del calendario, no un instante,
/// y pasar `2026-02-12T00:00:00Z` a hora local lo correria al 11 en media
/// America. Lo que se lee es lo que se guardo.
///
/// El orden de los numeros se resuelve por como estan escritos y no por el
/// idioma:
///
/// - Si el primero tiene cuatro cifras, es el ano (`2026-02-12`, `2026/02/12`).
/// - Si no, es el dia (`12-02-2026`, `12/02/26`), que es como se escribe una
///   fecha en casi todo el mundo.
/// - Y si con eso el mes pasa de doce pero el dia no, estaban al reves
///   (`02/26/2026`): se dan vuelta en vez de perder la fecha.
///
/// Un ano de dos cifras se completa en el siglo mas cercano (`26` es 2026, `98`
/// es 1998), que es lo que hace cualquier planilla.
class ProductDate {
  const ProductDate._(this.at, {required this.hasTime});

  /// La fecha entendida.
  final DateTime at;

  /// Si lo guardado traia hora, y no solo un dia.
  ///
  /// Se recuerda porque **no es lo mismo no tener hora que tenerla en cero**:
  /// una fecha de vencimiento no vence a las doce de la noche, no vence a
  /// ninguna hora. Sin esto, mostrarla completa inventaria un `12:00 AM` que
  /// nadie cargo.
  final bool hasTime;

  /// Lee una fecha escrita como sea, o `null` si eso no es una fecha.
  ///
  /// Devolver `null` no es un error a mostrar: una celda con texto que no es una
  /// fecha se sigue viendo tal como se cargo. Mientras el dato no sea una fecha,
  /// escribirlo como una seria afirmar algo que no se sabe.
  static ProductDate? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final match = _pattern.firstMatch(text);

    if (match == null) {
      // Lo que no encaja arriba pero es ISO igual: lo que manda el backend con
      // milisegundos y zona (`2026-02-12T00:00:00.000Z`).
      final iso = DateTime.tryParse(text);

      return iso == null
        ? null
        : ProductDate._(iso, hasTime: text.contains(":"));
    }

    final first = int.parse(match[1]!);
    final second = int.parse(match[2]!);
    final third = int.parse(match[3]!);

    // Cuatro cifras adelante solo puede ser un ano; si no, adelante va el dia.
    final yearFirst = match[1]!.length == 4;

    final year = yearFirst ? first : _century(third, match[3]!.length);
    var month = second;
    var day = yearFirst ? third : first;

    // `02/26/2026`: el mes no llega a veintiseis y el dia si. Estaban al reves.
    // Solo cuando el ano no venia adelante: con el ano adelante el orden ya no
    // es ambiguo (`2026-13-01` no es una fecha, no es el 13 de enero).
    if (!yearFirst && month > 12 && day <= 12) (day, month) = (month, day);
    if (month < 1 || month > 12 || day < 1) return null;

    final withTime = match[4] != null;
    final hour = withTime ? _hour(int.parse(match[4]!), match[7]) : 0;
    final minute = withTime ? int.parse(match[5]!) : 0;
    final seconds = withTime && match[6] != null ? int.parse(match[6]!) : 0;

    if (hour < 0 || hour > 23 || minute > 59 || seconds > 59) return null;

    final at = DateTime(year, month, day, hour, minute, seconds);

    // `31/02/2026` no existe: [DateTime] lo corre solo al 3 de marzo en vez de
    // fallar, asi que la fecha se da por buena unicamente si volvio entera.
    if (at.month != month || at.day != day) return null;

    return ProductDate._(at, hasTime: withTime);
  }

  /// La misma fecha escrita como la guarda la tabla, o el texto tal cual si eso
  /// no era una fecha.
  ///
  /// Es lo que corre al salir de la celda: se escribe en cualquier formato y
  /// queda guardado en uno solo.
  static String normalize(String raw) => parse(raw)?.stored ?? raw;

  /// Como viaja y como se guarda: `2026-02-12`, y con hora `2026-02-12 12:30`.
  ///
  /// Va con un espacio y no con la `T` de ISO porque tambien es lo que se ve al
  /// volver a abrir la celda para corregirla, y es la misma forma que
  /// [DateTime.parse] entiende de todos modos.
  String get stored =>
    hasTime ? "$_day ${_two(at.hour)}:${_two(at.minute)}" : _day;

  /// Como se lee: `Feb 12, 2026`, en el idioma de la app.
  ///
  /// Los nombres de los meses no los escribe esta app: los trae `intl` con los
  /// datos que deja cargados `GlobalMaterialLocalizations`, asi que la fecha se
  /// ordena y se traduce sola donde se la mire.
  String short(String locale) => DateFormat.yMMMd(locale).format(at);

  /// La fecha completa: `2026-02-12`, y con su hora `2026-02-12 12:30 PM`.
  ///
  /// Es la de leer un numero exacto —comparar dos filas, copiar la fecha a otro
  /// lado— y por eso el dia va en cifras y la hora en el reloj del idioma (de 12
  /// o de 24 segun el lugar). La hora aparece unicamente si se cargo una: ver
  /// [hasTime].
  String full(String locale) =>
    hasTime ? "$_day ${DateFormat.jm(locale).format(at)}" : _day;

  String get _day =>
    "${at.year.toString().padLeft(4, "0")}-${_two(at.month)}-${_two(at.day)}";

  static String _two(int value) => value.toString().padLeft(2, "0");

  /// Un ano de dos cifras al siglo mas cercano: hasta `69` es 2000 y de `70`
  /// para arriba 1900, que es la ventana que usan las planillas.
  static int _century(int year, int digits) =>
    digits > 2 ? year : (year < 70 ? 2000 + year : 1900 + year);

  /// La hora de un reloj de 12 pasada a una de 24, si venia con `am` o `pm`.
  static int _hour(int hour, String? meridiem) {
    if (meridiem == null) return hour;

    if (meridiem.toLowerCase().startsWith("p")) {
      return hour == 12 ? 12 : hour + 12;
    }

    return hour == 12 ? 0 : hour;
  }

  /// Tres numeros separados por `-`, `/` o `.`, y detras una hora opcional.
  ///
  /// Cual de los tres es el ano no lo decide esto sino [parse]: aca solo se
  /// reconoce la forma.
  static final RegExp _pattern = RegExp(
    r"^(\d{1,4})[-/.](\d{1,2})[-/.](\d{1,4})"
    r"(?:[\sT]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?)?)?$",
    caseSensitive: false
  );
}

/// Las tres cosas que pueden separar los numeros de una fecha.
final RegExp _separators = RegExp(r"[-/.]");

/// Escribe la barra de una fecha cuando se aprieta la barra espaciadora.
///
/// Una fecha se tipea con el teclado numerico, donde el separador no esta: hay
/// que soltar la mano, buscar la barra y volver. El pulgar, en cambio, ya esta
/// sobre el espacio. Asi `12 2 26` queda `12/2/26` sin mover la mano de los
/// numeros.
///
/// Pone la barra que la fecha ya venia usando —si se empezo con `-` sigue con
/// `-`— para no dejar `2026-02/12`.
///
/// **El espacio de la hora sigue siendo un espacio.** Con dos separadores puestos
/// la fecha ya esta completa, asi que lo que viene detras es la hora
/// (`2026-02-12 12:30`) y ahi el espacio se escribe tal cual. Sin esa
/// comprobacion no habria forma de tipear una fecha con hora.
///
/// Tampoco escribe dos separadores seguidos ni uno al principio: un espacio que
/// no separa nada no se convierte en nada, simplemente no entra.
class DateSeparatorFormatter extends TextInputFormatter {
  const DateSeparatorFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value
  ) {
    // Solo la tecla recien apretada. Pegar un texto con espacios, o borrar, no
    // pasa por aca: lo que se pega se guarda como vino y ya lo entiende
    // [ProductDate].
    if (value.text.length != old.text.length + 1) return value;

    final at = value.selection.baseOffset - 1;
    if (at < 0 || at >= value.text.length || value.text[at] != " ") return value;

    final before = value.text.substring(0, at);

    // La fecha ya esta entera: lo que sigue es la hora.
    if (_separators.allMatches(before).length >= 2) return value;

    final separator =
      before.isEmpty || _separators.hasMatch(before[before.length - 1])
        ? ""
        : before.contains("-") ? "-" : "/";

    return TextEditingValue(
      text: before + separator + value.text.substring(at + 1),
      selection: TextSelection.collapsed(
        offset: before.length + separator.length
      )
    );
  }
}
