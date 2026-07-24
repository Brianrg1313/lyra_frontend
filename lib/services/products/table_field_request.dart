/// Cuerpo de `POST /v1/tables/fields/`: el alta de una columna (campo) de una
/// tabla ya creada.
///
/// Vive aparte de la pantalla porque es el contrato con el backend: lo que se
/// arma aca es lo que se documenta del otro lado, y asi se puede probar sin
/// montar el modal.
///
/// La empresa dueña no va en el cuerpo: viaja en la cabecera `business_id` de
/// todas las peticiones (ver `useBusiness` en `toolkit/api.dart`). El [tableId]
/// si viaja, porque el campo pertenece a una tabla concreta.
///
/// Forma:
///
/// ```json
/// {
///   "TABLE_ID": "a1b2c3",
///   "NAME": "Precio",
///   "DESCRIPTION": "Precio de venta con IVA",
///   "POSITION": 3,
///   "TYPE": "PRICE"
/// }
/// ```
library;

/// Arma el cuerpo del alta de un campo.
///
/// Recorta los textos y omite la descripcion cuando queda vacia, en vez de
/// mandarla en blanco: asi el backend distingue "sin descripcion" de
/// "descripcion borrada", igual que el resto de los opcionales de la api.
///
/// La [position] ordena las columnas: quien crea el campo la resuelve como la
/// cantidad de columnas actuales, de modo que la nueva quede al final.
Map<String, dynamic> createFieldRequest({
  required String tableId,
  required String name,
  required String description,
  required String type,
  required int position
}) {
  final trimmed = description.trim();

  return {
    "TABLE_ID": tableId,
    "NAME": name.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "POSITION": position,
    "TYPE": type
  };
}
