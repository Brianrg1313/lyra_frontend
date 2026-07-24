/// Cuerpo de `POST /v1/tables/structure/`.
///
/// Vive aparte de la pantalla porque es el contrato con el backend: lo que se
/// arma aca es lo que se documenta del otro lado, y asi se puede probar sin
/// montar el formulario.
///
/// La empresa dueña no va en el cuerpo: viaja en la cabecera `business_id` de
/// todas las peticiones (ver `useBusiness` en `toolkit/api.dart`).
///
/// La tabla se crea vacia: solo lleva su cabecera (titulo, descripcion y color)
/// y las columnas se definen despues. Por eso el alta no manda campos.
///
/// Forma:
///
/// ```json
/// {
///   "TITLE": "Vinos",
///   "DESCRIPTION": "Catalogo de la bodega",
///   "COLOR": "0xFF60A5FA"
/// }
/// ```
library;

/// Arma el cuerpo del alta.
///
/// Recorta los textos y omite la descripcion cuando queda vacia, en vez de
/// mandarla en blanco: el resto de los opcionales de la api se comporta igual y
/// asi el backend distingue "sin descripcion" de "descripcion borrada".
///
/// El [color] es el string que identifica visualmente a la tabla (un literal
/// ARGB de Flutter como `0xFF60A5FA`); siempre viaja, porque el formulario
/// arranca con uno elegido.
Map<String, dynamic> createTableRequest({
  required String title,
  required String description,
  required String color
}) {
  final trimmed = description.trim();

  return {
    "TITLE": title.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "COLOR": color
  };
}
