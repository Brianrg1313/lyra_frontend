/// Cuerpos de las tres escrituras de una columna (campo) de una tabla ya
/// creada: el alta (`POST /v1/tables/fields/`), la edicion
/// (`PUT /v1/tables/fields/`) y la baja (`DELETE /v1/tables/fields/`).
///
/// Viven aparte de la pantalla porque son el contrato con el backend: lo que se
/// arma aca es lo que se documenta del otro lado, y asi se puede probar sin
/// montar el modal.
///
/// La empresa dueña no va en el cuerpo: viaja en la cabecera `business_id` de
/// todas las peticiones (ver `useBusiness` en `toolkit/api.dart`). El [tableId]
/// si viaja en el alta, porque el campo pertenece a una tabla concreta; en la
/// edicion alcanza con el id del campo, que ya sabe de que tabla es.
///
/// Forma del alta:
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
///
/// Forma de la edicion:
///
/// ```json
/// {
///   "ID": "d4e5f6",
///   "NAME": "Precio",
///   "TYPE": "PRICE",
///   "VISIBILITY": "declared",
///   "WIDTH": 180
/// }
/// ```
///
/// Las opciones de un campo `SELECT` viajan en `OPTIONS`, como la lista entera y
/// no como la que se agrega: le pertenecen al campo, asi que se guardan igual
/// que su nombre o su ancho —escribiendo el valor que queda— y no con un alta
/// aparte.
///
/// ```json
/// { "ID": "d4e5f6", "NAME": "Color", "OPTIONS": ["Rojo", "Verde"] }
/// ```
///
/// Forma de la baja:
///
/// ```json
/// { "ID": "d4e5f6" }
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

/// Arma el cuerpo de la edicion de un campo.
///
/// El nombre es obligatorio aunque no se lo este cambiando: el backend lo pide
/// siempre, asi que quien edita solo el tipo manda el que el campo ya tenia. El
/// resto son opcionales de verdad y lo que no se manda no se toca, de modo que
/// cambiar el tipo no borra la descripcion, no corre la columna de lugar ni le
/// cambia el ancho.
///
/// El [width] es el ancho de la columna en pantalla y va entero: es una medida
/// en pixeles logicos, y el fraccion que deja un arrastre no significa nada del
/// otro lado.
///
/// La [visibility] es cuanto ve el modelo de IA de la columna
/// (`visible` / `declared` / `hidden`). Viaja igual que el tipo —solo cuando se
/// la cambia— porque es lo mismo: una propiedad de la columna que se corrige
/// sola, sin tocar nada de lo que hay escrito en ella.
///
/// Las [options] son la lista completa de un campo `SELECT` tal como tiene que
/// quedar. Una lista vacia **si** viaja, y es lo que borra las opciones del
/// campo: es la unica de las claves donde "vacio" es un valor y no la ausencia
/// de uno. No mandarlas las deja como estaban, como el resto de los opcionales.
Map<String, dynamic> editFieldRequest({
  required String id,
  required String name,
  String? description,
  String? type,
  int? position,
  int? width,
  String? visibility,
  List<String>? options
}) {
  final trimmed = description?.trim() ?? "";

  return {
    "ID": id,
    "NAME": name.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "POSITION": ?position,
    if (type != null && type.isNotEmpty) "TYPE": type,
    "WIDTH": ?width,
    if (visibility != null && visibility.isNotEmpty) "VISIBILITY": visibility,
    if (options != null) "OPTIONS": [
      for (final option in options)
        if (option.trim().isNotEmpty) option.trim()
    ]
  };
}

/// Arma el cuerpo de la baja de un campo.
///
/// Es solo el id: el campo ya sabe de que tabla es y de que empresa, y el
/// backend lo da de baja logica (`status = 0`) junto con lo que se haya cargado
/// en esa columna. Tiene su funcion igual que las otras dos, para que las tres
/// escrituras del campo se lean —y se prueben— en el mismo lugar.
Map<String, dynamic> deleteFieldRequest({required String id}) => {"ID": id};
