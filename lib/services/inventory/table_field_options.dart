/// Las reglas de la lista de un campo `SELECT`: que cuenta como una opcion nueva
/// y que es la que ya estaba.
///
/// Viven aparte de la pantalla porque no son de la pantalla: son lo que decide
/// si escribir "rojo" en una lista que ya tiene "Rojo" agrega una opcion o elige
/// la que hay. Sin red y sin widgets, asi que se prueban solas.
library;

import 'package:core/kit/str.dart';

/// Cuando dos opciones son la misma.
///
/// Se comparan como las compara el buscador del desplegable ([Str.clear]:
/// ignorando mayusculas y tildes), y por el mismo motivo: dos opciones que solo
/// se distinguen en eso serian indistinguibles al elegirlas, asi que no pueden
/// convivir en una lista.
bool sameFieldOption(String a, String b) => Str.clear(a) == Str.clear(b);

/// La opcion de [options] que ya es [option], o `null` si no esta.
///
/// Es lo que permite que crear una opcion repetida no falle ni duplique nada:
/// se elige la que ya estaba, que es lo que quiso decir quien la escribio.
String? fieldOptionLike(List<String> options, String option) {
  final wanted = option.trim();
  if (wanted.isEmpty) return null;

  for (final current in options) {
    if (sameFieldOption(current, wanted)) return current;
  }

  return null;
}

/// La lista del campo con [option] agregada **al final**, o `null` si no hay
/// nada que agregar: la opcion esta vacia o ya esta en la lista.
///
/// Va al final y no ordenada alfabeticamente porque el orden de la lista es el
/// orden en que se ofrece, y ese lo pone quien la arma: las opciones se
/// escribieron en algun orden y una nueva es la ultima que se penso, no una que
/// se cuela en el medio.
///
/// Devolver `null` es lo que distingue "hay algo que guardar" de "no hace falta
/// escribirle nada al backend", que es la diferencia entre una peticion y
/// ninguna.
List<String>? fieldOptionsWith(List<String> options, String option) {
  final wanted = option.trim();
  if (wanted.isEmpty) return null;

  if (fieldOptionLike(options, wanted) != null) return null;

  return [...options, wanted];
}
