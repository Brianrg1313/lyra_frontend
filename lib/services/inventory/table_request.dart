/// Cuerpos de las escrituras de una tabla: el alta
/// (`POST /v1/tables/structure/`), la edicion (`PUT /v1/tables/structure/`),
/// la baja (`DELETE /v1/tables/structure/`) y la edicion parcial de la
/// pantalla de ajustes (`PUT /v1/tables/details/`).
///
/// Viven aparte de la pantalla porque son el contrato con el backend: lo que se
/// arma aca es lo que se documenta del otro lado, y asi se puede probar sin
/// montar el formulario.
///
/// La empresa dueña no va en el cuerpo: viaja en la cabecera `business_id` de
/// todas las peticiones (ver `useBusiness` en `toolkit/api.dart`).
///
/// La tabla se crea con su cabecera (titulo, descripcion y color) y, si se
/// eligio un rubro de plantilla, con ese rubro. Las columnas nunca las arma el
/// front: cuando viaja [template] es el backend quien las crea del otro lado,
/// en la misma alta y sin una segunda peticion.
///
/// Forma del alta:
///
/// ```json
/// {
///   "TITLE": "Vinos",
///   "DESCRIPTION": "Catalogo de la bodega",
///   "COLOR": "0xFF60A5FA",
///   "TEMPLATE": "FOOD"
/// }
/// ```
///
/// Forma de la edicion:
///
/// ```json
/// { "ID": "a1b2c3", "NAME": "Vinos", "DESCRIPTION": "Catalogo de la bodega" }
/// ```
///
/// Forma de la baja:
///
/// ```json
/// { "ID": "a1b2c3" }
/// ```
///
/// Forma de la edicion parcial:
///
/// ```json
/// { "ID": "a1b2c3", "DESCRIPTION": "Catalogo de la bodega" }
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
///
/// El [template] es el codigo del rubro elegido (por ejemplo `"FOOD"`); se
/// omite cuando no se eligio ninguno, para que el backend cree la tabla sin
/// columnas igual que antes.
Map<String, dynamic> createTableRequest({
  required String title,
  required String description,
  required String color,
  String? template
}) {
  final trimmed = description.trim();

  return {
    "TITLE": title.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "COLOR": color,
    if (template != null && template.isNotEmpty) "TEMPLATE": template
  };
}

/// Arma el cuerpo de la edicion de una tabla.
///
/// El titulo viaja en `NAME` y no en `TITLE` como en el alta: es la clave que
/// pide la edicion del otro lado. Es obligatorio aunque no se lo este
/// cambiando, asi que quien edita solo la descripcion manda el que la tabla ya
/// tenia.
///
/// La descripcion **siempre viaja**, tambien vacia, y ahi esta la diferencia
/// con el alta: en una tabla que ya existe, vaciarla es borrar la que tenia. No
/// mandarla la dejaria como estaba y una descripcion puesta por error no
/// tendria vuelta atras.
Map<String, dynamic> editTableRequest({
  required String id,
  required String title,
  required String description
}) => {
  "ID": id,
  "NAME": title.trim(),
  "DESCRIPTION": description.trim()
};

/// Arma el cuerpo de la baja de una tabla.
///
/// Es solo el id: la tabla ya sabe de que empresa es, y el backend le da de
/// baja logica (`status = 0`) a ella y a sus columnas. Tiene su funcion igual
/// que las otras dos, para que las tres escrituras se lean —y se prueben— en el
/// mismo lugar.
Map<String, dynamic> deleteTableRequest({required String id}) => {"ID": id};

/// Arma el cuerpo de la edicion **parcial** de una tabla
/// (`PUT /v1/tables/details/`).
///
/// Es la escritura de la pantalla de ajustes y no la de la planilla: viaja
/// solo lo que se toco, asi que cambiar la descripcion no reescribe el nombre
/// —ni al reves—. Por eso los dos textos son opcionales y `null` significa "no
/// se cambio", que del otro lado es "dejalo como estaba".
///
/// La descripcion en blanco **si viaja**, y ahi esta la diferencia con `null`:
/// es el unico lugar donde el vacio es un valor y no la ausencia de uno, y es
/// lo que borra una descripcion puesta por error. `null` la deja intacta.
///
/// Es la misma clave `NAME` de [editTableRequest] porque es el mismo dato en
/// el mismo backend; lo que cambia es que aca no es obligatoria.
Map<String, dynamic> editTableDetailsRequest({
  required String id,
  String? name,
  String? description
}) => {
  "ID": id,
  if (name != null) "NAME": name.trim(),
  if (description != null) "DESCRIPTION": description.trim()
};
