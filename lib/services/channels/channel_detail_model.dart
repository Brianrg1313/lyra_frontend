import 'package:app/services/channels/channel_provider_model.dart';

/// Un canal con todo lo necesario para reabrir su formulario, tal como lo
/// devuelve `GET /channels/set_up/detail/:CHANNEL_ID`.
///
/// **Los secretos no vienen.** [credentials] es la lista de *nombres de clave*
/// bajo los que hay un secreto guardado —lo justo para que el formulario diga
/// "token de acceso: configurado" y ofrezca reemplazarlo—; los valores no salen
/// de la base de datos, y no hay endpoint que los devuelva. Un token que se
/// perdio se pide de nuevo a quien lo emitio, no a esta api.
///
/// [schema] viene pegado en la misma lectura: es la descripcion del proveedor
/// (que campos pide esa red), asi que el formulario se dibuja sin tener que
/// cruzar esto con el catalogo.
class ChannelDetailModel {
  const ChannelDetailModel({
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
  /// lee de vuelta, y donde ademas viven los ajustes propios de esta app (el
  /// rol del agente, la fuente de datos y las herramientas).
  final Map<String, dynamic> settings;

  /// Nombres de clave de los secretos ya guardados. Nunca sus valores.
  final List<String> credentials;

  /// Claves obligatorias todavia vacias, en orden de formulario.
  final List<String> missing;

  /// `true` cuando [missing] esta vacio.
  final bool ready;

  /// Descripcion del proveedor de este canal, para dibujar su formulario.
  final ChannelProviderModel? schema;

  /// `true` si ese secreto ya esta guardado del otro lado.
  bool hasCredential(String key) => credentials.contains(key);

  /// Valor de un ajuste plano como texto, o vacio si no esta cargado.
  String setting(String key) {
    final value = settings[key];
    return value == null ? "" : value.toString();
  }

  /// Valor de un ajuste booleano. Se guardan como booleanos de verdad
  /// (`Channels.config` los acepta), pero se leen tolerantes porque una vuelta
  /// por JSON los puede dejar como numero o como texto.
  bool flag(String key) => switch (settings[key]) {
    final bool value => value,
    final num value => value != 0,
    "1" || "true" => true,
    _ => false
  };

  factory ChannelDetailModel.fromJson(Map json) {
    final schema = json["schema"];

    return ChannelDetailModel(
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
      ready: json["ready"] == true,
      schema: schema is Map ? ChannelProviderModel.fromJson(schema) : null
    );
  }

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];
}
