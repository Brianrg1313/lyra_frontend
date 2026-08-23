// WIDGETS
import 'package:core/form.dart';

/// Un dato editable de la empresa: con que clave viaja al backend, que hay
/// guardado hoy y con que se lo escribe.
///
/// Vive aca y no en la ficha del perfil porque es lo que necesita el formulario
/// para armarse solo: quien dibuja una fila describe su dato una vez y no tiene
/// que saber nada del modal que lo cambia.
///
/// Un dato con opciones se **elige** y uno sin ellas se **escribe**: esa es la
/// unica diferencia entre los dos, y la decide el propio dato. Tambien decide
/// donde se cambia: los que se escriben abren el modal de un campo
/// (`EditBusinessFieldModal`), los que se eligen despliegan su lista en la
/// misma fila de la ficha (`ProfileSelectField`).
class BusinessField {
  const BusinessField.text({
    required this.key,
    required this.value,
    this.pattern = "IGNORE",
    this.hint,
    this.min,
    this.max,
    this.type = InputType.text,
    this.obligatory = false
  }) : options = const [];

  /// Un dato que se elige de una lista cerrada (el sector, el idioma, la
  /// moneda). Siempre es obligatorio: la lista no tiene la opcion "ninguno", y
  /// desplegarla para no elegir nada es cerrarla, no vaciar el dato.
  const BusinessField.select({
    required this.key,
    required this.value,
    required this.options
  }) : pattern = "IGNORE",
       hint = null,
       min = null,
       max = null,
       type = InputType.select,
       obligatory = true;

  /// Clave con la que el dato viaja en `PUT /business/profile/` (`LEGAL_NAME`,
  /// `ACTIVITY_TYPE`...). Es la misma con la que se lo crea.
  final String key;

  /// Lo que hay guardado, **en la forma en que viaja**: el codigo de la opcion
  /// en los que se eligen (`RETAIL`) y no la etiqueta traducida que se lee en
  /// la ficha. Es con lo que el formulario se abre lleno.
  final String value;

  /// Las opciones, cuando el dato se elige. Vacio es un campo de texto.
  final List<SelectOption> options;

  final String pattern;

  /// Que forma tiene lo que se espera, para los datos donde el nombre del campo
  /// no alcanza (una fecha, un codigo de pais).
  final String? hint;

  final int? min;
  final int? max;
  final InputType type;

  /// Si el dato no se puede dejar vacio. Casi todo el perfil si se puede: una
  /// empresa recien creada tiene el nombre, el sector y poco mas.
  final bool obligatory;
}
