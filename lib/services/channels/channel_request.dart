/// Cuerpos de las escrituras de un canal: el alta
/// (`POST /v1/channels/set_up/`), la edicion (`PUT /v1/channels/set_up/`), la
/// baja (`DELETE /v1/channels/set_up/`) y el reordenamiento
/// (`PUT /v1/channels/set_up/order/`).
///
/// Viven aparte de la pantalla porque son el contrato con el backend, igual que
/// los de las tablas de productos.
///
/// La empresa dueña no va en el cuerpo: viaja en la cabecera `business_id` de
/// todas las peticiones (ver `useBusiness` en `toolkit/api.dart`).
///
/// La configuracion se parte en dos objetos y **esa division no es del
/// formulario, es del backend**:
///
/// - `SETTINGS` — lo que no es secreto (ids de cuenta, hosts, nombres) y
///   ademas los ajustes propios de esta app (rol del agente, fuente de datos,
///   herramientas). Se lee de vuelta.
/// - `CREDENTIALS` — los tokens y secretos. Solo viajan de ida: ninguna lectura
///   los devuelve.
///
/// Cual campo va en cual lo dice el catalogo del proveedor (`secret: true`), no
/// esta app.
///
/// Forma del alta:
///
/// ```json
/// {
///   "PROVIDER": "whatsapp",
///   "NAME": "Ventas",
///   "DESCRIPTION": "Atiende el numero principal",
///   "SETTINGS": { "phone_number_id": "123", "agent_role": "seller" },
///   "CREDENTIALS": { "access_token": "EAAG..." }
/// }
/// ```
library;

/// Arma el cuerpo del alta.
///
/// Solo el proveedor y el nombre hacen falta de verdad: **un canal se registra
/// a proposito antes de tener sus credenciales**. La empresa da de alta
/// "Instagram — Ventas" hoy y pega los tokens cuando Meta se los emita, asi que
/// mandar `SETTINGS` y `CREDENTIALS` a medio llenar es el caso normal y no un
/// error; el canal queda "no listo" hasta que se completen.
///
/// Los valores vacios se sacan en vez de mandarse en blanco: en el alta una
/// clave con valor nulo es una clave que nunca se configuro, y dejarla haria
/// parecer configurado lo que no lo esta.
Map<String, dynamic> createChannelRequest({
  required String provider,
  required String name,
  required String description,
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> credentials = const {}
}) {
  final trimmed = description.trim();

  return {
    "PROVIDER": provider,
    "NAME": name.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "SETTINGS": _clean(settings),
    "CREDENTIALS": _clean(credentials)
  };
}

/// Arma el cuerpo de la edicion.
///
/// La descripcion **siempre viaja**, tambien vacia: en un canal que ya existe,
/// vaciarla es borrar la que tenia, y el backend lee el vacio como "no dejar
/// ninguna". Es la misma regla que en la edicion de una tabla.
///
/// `SETTINGS` se manda entero porque se parchea clave por clave del otro lado:
/// lo que va vacio borra ese ajuste, y lo que no se menciona queda como estaba.
/// Por eso los ajustes vacios **si** viajan aca (como `null`) y no en el alta.
///
/// `CREDENTIALS` es al reves: solo se mandan los secretos que se escribieron.
/// Un campo de secreto vacio significa "el que ya estaba", no "borralo" — el
/// formulario nunca puede mostrar el token guardado, asi que dejarlo en blanco
/// es lo que hace cualquiera que solo venia a cambiar el nombre. Mandarlo vacio
/// borraria el token de un canal que estaba funcionando.
///
/// `PROVIDER` no se manda: no se puede cambiar. Los secretos guardados se
/// juntaron para una red, y apuntarlos a otra dejaria valores que ahi no
/// significan nada; la otra red es un canal nuevo.
Map<String, dynamic> editChannelRequest({
  required String id,
  required String name,
  required String description,
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> credentials = const {},
  bool? enabled
}) => {
  "ID": id,
  "NAME": name.trim(),
  "DESCRIPTION": description.trim(),
  "SETTINGS": settings,
  "CREDENTIALS": _clean(credentials),
  "ENABLED": ?enabled
};

/// Arma el cuerpo de la baja. Es solo el id: el canal ya sabe de que empresa
/// es.
///
/// La baja es logica y libera la cuenta que el canal ocupaba, asi que el mismo
/// numero o pagina se puede volver a conectar despues. Lo que **no** vuelve son
/// las credenciales: se van con el canal y reconectar es configurarlo de nuevo.
Map<String, dynamic> deleteChannelRequest({required String id}) => {"ID": id};

/// Arma el cuerpo del reordenamiento: los ids en el orden en que deben verse.
///
/// Va en una sola llamada y no en una posicion por canal porque mover uno
/// cambia donde quedan los demas: mandandolos de a uno el listado quedaria a
/// medio ordenar entre peticion y peticion.
Map<String, dynamic> orderChannelsRequest({required List<String> ids}) =>
  {"CHANNELS": ids};

/// Saca las claves sin valor de un objeto de configuracion.
///
/// Se recortan los textos de paso: un token pegado desde la consola de Meta
/// suele venir con un salto de linea detras, y ese espacio invisible es la
/// diferencia entre un canal que conecta y uno que devuelve 401.
Map<String, dynamic> _clean(Map<String, dynamic> config) {
  final cleaned = <String, dynamic>{};

  for (final entry in config.entries) {
    final value = entry.value;

    if (value == null) continue;

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) continue;

      cleaned[entry.key] = text;
      continue;
    }

    cleaned[entry.key] = value;
  }

  return cleaned;
}
