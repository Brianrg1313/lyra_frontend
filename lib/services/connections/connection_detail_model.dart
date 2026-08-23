import 'package:app/services/connections/connection_provider_model.dart';

/// Una conexion con todo lo necesario para reabrir su formulario, tal como la
/// devuelve `GET /connections/detail/:CONNECTION_ID`.
///
/// **Los secretos no vienen.** [credentials] es la lista de *nombres de clave*
/// bajo los que hay un secreto guardado —lo justo para que el formulario diga
/// "token de acceso: configurado" y ofrezca reemplazarlo—; los valores no salen
/// de la base de datos, y no hay endpoint que los devuelva. Un token que se
/// perdio se pide de nuevo a quien lo emitio, no a esta api.
///
/// [schema] viene pegado en la misma lectura: es la descripcion del proveedor
/// (que campos pide ese servicio), asi que el formulario se dibuja sin tener que
/// cruzar esto con el catalogo.
class ConnectionDetailModel {
  const ConnectionDetailModel({
    required this.id,
    required this.provider,
    required this.name,
    this.description = "",
    this.position = 0,
    this.enabled = true,
    this.externalId,
    this.settings = const {},
    this.credentials = const [],
    this.missing = const [],
    this.taken = const [],
    this.ready = false,
    this.schema
  });

  final String id;
  final String provider;
  final String name;
  final String description;
  final int position;
  final bool enabled;

  /// Id de la cuenta del lado del proveedor. Lo calcula el backend a partir de
  /// los settings, no se edita a mano.
  final String? externalId;

  /// Configuracion plana: ids de cuenta, hosts, usuarios. Es lo que **si** se
  /// lee de vuelta.
  final Map<String, dynamic> settings;

  /// Nombres de clave de los secretos ya guardados. Nunca sus valores.
  final List<String> credentials;

  /// Claves obligatorias todavia vacias, en orden de formulario.
  final List<String> missing;

  /// Trabajos de la cuenta que ya tienen un bot (`messages`, `comments`, ...).
  ///
  /// Es de los bots y no de la conexion, asi que este formulario no lo edita: se
  /// lee para saber que queda libre cuando se vaya a crear uno, que es una
  /// decision de otra pantalla.
  final List<String> taken;

  /// `true` cuando [missing] esta vacio.
  final bool ready;

  /// Descripcion del proveedor de esta conexion, para dibujar su formulario.
  final ConnectionProviderModel? schema;

  /// `true` si ese secreto ya esta guardado del otro lado.
  bool hasCredential(String key) => credentials.contains(key);

  /// Valor de un ajuste plano como texto, o vacio si no esta cargado.
  String setting(String key) {
    final value = settings[key];
    return value == null ? "" : value.toString();
  }

  factory ConnectionDetailModel.fromJson(Map json) {
    final schema = json["schema"];

    return ConnectionDetailModel(
      id: (json["id"] ?? json["ID"])?.toString() ?? "",
      provider: json["provider"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      position: switch (json["position"]) {
        final num number => number.toInt(),
        final String text => int.tryParse(text) ?? 0,
        _ => 0
      },
      enabled: json["enabled"] != false && json["enabled"] != 0,
      externalId: json["external_id"]?.toString(),
      settings: json["settings"] is Map
        ? Map<String, dynamic>.from(json["settings"] as Map)
        : const {},
      credentials: [
        for (final key in _list(json["credentials"])) key.toString()
      ],
      missing: [for (final key in _list(json["missing"])) key.toString()],
      taken: [for (final scope in _list(json["taken"])) scope.toString()],
      ready: json["ready"] == true,
      schema: schema is Map ? ConnectionProviderModel.fromJson(schema) : null
    );
  }

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];
}
