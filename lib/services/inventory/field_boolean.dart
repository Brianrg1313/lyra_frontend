/// How a `BOOLEAN` cell is read and written.
///
/// The engine stores a real boolean and takes `true`/`1` and `false`/`0` (`Cells.read` in
/// `lyra_node`); an imported column brings it written in words («Sí», «x», «No»), which the
/// import already reads the same way. The sheet writes only `true` and `false`.
library;

import 'package:core/kit/str.dart';

/// What the cell says: `true`, `false`, or `null` when it is empty or holds something that is
/// not a yes or a no (drawn as written, not as an unchecked box that would claim a «no»).
bool? fieldBoolean(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw == 1 ? true : raw == 0 ? false : null;

  return switch (Str.clear("${raw ?? ""}".trim())) {
    "true" || "1" || "si" || "yes" || "sim" || "verdadero" || "verdadeiro" || "x" => true,
    "false" || "0" || "no" || "nao" || "falso" => false,
    _ => null
  };
}

/// How a flipped cell travels.
String fieldBooleanValue(bool value) => value ? "true" : "false";
