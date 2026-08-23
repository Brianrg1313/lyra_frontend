import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:intl/intl.dart';

/// Como se escriben las cifras y las fechas de los ajustes de una tabla.
///
/// Vive aparte de los widgets porque lo usan los cuatro bloques y las dos
/// respuestas tienen que ser la misma en todos: una tabla que dice "12.480
/// registros" arriba y "12480" abajo se lee como dos datos distintos.

/// El idioma con el que se ordenan y se traducen los numeros y las fechas.
///
/// Sale de las localizaciones cargadas y no de una constante: los nombres de
/// los meses y el separador de miles los trae `intl` con los datos que deja
/// `GlobalMaterialLocalizations`, asi que la pantalla se escribe sola en el
/// idioma en que se la mire.
String _locale(BuildContext context) =>
  Localizations.localeOf(context).toString();

/// Una cantidad con su separador de miles: una tabla de cientos de miles de
/// filas es justamente el caso normal, y `184320` no se lee de un vistazo.
String settingsNumber(BuildContext context, int value) =>
  NumberFormat.decimalPattern(_locale(context)).format(value);

/// Una fecha completa: el dia en letras y la hora del reloj del idioma.
///
/// Va con hora y no solo el dia porque las tres fechas de esta pantalla se
/// miran para saber **que paso hoy** —cuando entro el ultimo dato, cuando se
/// toco la ultima columna—, y un dia pelado no distingue lo de esta manana de
/// lo de anoche.
///
/// Se pasa a la hora local antes de escribirla: el backend las manda en UTC, y
/// una tabla recargada a las nueve de la manana que dice haberlo sido a las
/// doce se lee como un error.
String settingsDate(BuildContext context, DateTime? at) {
  if (at == null) return "";

  final locale = _locale(context);
  final local = at.toLocal();

  return "${DateFormat.yMMMd(locale).format(local)}"
    " · ${DateFormat.jm(locale).format(local)}";
}
