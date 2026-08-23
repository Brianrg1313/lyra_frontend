import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Que clase de dato pide un campo de un proveedor, tal como lo declara el
/// backend (`ProviderField.type`).
///
/// No es una validacion: es que teclado y que widget corresponde. El unico que
/// cambia el comportamiento es [secret], que ademas decide **en que objeto
/// viaja el valor** (ver [ChannelProviderField.secret]).
enum ChannelFieldType {
  text,
  secret,
  number,
  url,
  email,
  phone;

  /// Lee el tipo que mando el backend. Lo desconocido se lee como [text]: un
  /// tipo nuevo del catalogo tiene que poder configurarse igual desde una app
  /// vieja, aunque sea con un campo de texto pelado.
  static ChannelFieldType from(dynamic raw) => switch (
    raw?.toString().trim().toLowerCase()
  ) {
    "secret" => secret,
    "number" => number,
    "url" => url,
    "email" => email,
    "phone" => phone,
    _ => text
  };
}

/// Un valor que un proveedor necesita antes de poder conectarse: una entrada
/// del formulario de configuracion del canal.
///
/// El catalogo lo declara entero del lado del backend
/// (`model:/channels/providers.js`), asi que **el front no conoce ni un solo
/// token**: dibuja lo que le mandan, en el orden en que se lo mandan. Un
/// proveedor agregado al catalogo aparece solo, sin tocar esta app.
class ChannelProviderField {
  const ChannelProviderField({
    required this.key,
    required this.label,
    required this.type,
    required this.secret,
    required this.required,
    this.hint = ""
  });

  /// Clave con la que se guarda el valor, dentro de `SETTINGS` o `CREDENTIALS`
  /// segun [secret].
  final String key;

  /// Etiqueta que muestra el formulario.
  final String label;
  final ChannelFieldType type;

  /// `true` si el valor es un secreto. Decide dos cosas: que viaje en
  /// `CREDENTIALS` en vez de `SETTINGS`, y que **no se lea de vuelta nunca**.
  /// De un secreto guardado el backend solo devuelve su nombre de clave, asi
  /// que el formulario puede decir "ya configurado" pero no mostrarlo.
  final bool secret;

  /// `true` si el canal no funciona sin el.
  ///
  /// No es lo mismo que obligatorio para guardar: un canal se registra a
  /// proposito antes de tener sus credenciales —la empresa lo da de alta hoy y
  /// pega los tokens cuando Meta se los emita—, asi que esto solo alimenta el
  /// `ready` / `missing` de las lecturas y el aviso de "falta configurar".
  final bool required;

  /// Donde se encuentra el valor en la consola del proveedor. Lo escribe el
  /// backend y se muestra tal cual: es la unica pista que tiene quien configura.
  final String hint;

  factory ChannelProviderField.fromJson(Map json) {
    final type = ChannelFieldType.from(json["type"]);

    return ChannelProviderField(
      key: json["key"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      type: type,
      // El backend manda `secret` calculado, pero se cae al tipo si no vino:
      // que un secreto se dibuje como texto plano no es un detalle estetico,
      // es un token a la vista.
      secret: json["secret"] == true || type == ChannelFieldType.secret,
      required: json["required"] == true,
      hint: json["hint"]?.toString() ?? ""
    );
  }
}

/// Un proveedor del catalogo: una red a la que se puede conectar un canal, con
/// **exactamente** lo que hay que cargarle para conectarla.
///
/// Sale de `GET /channels/set_up/providers` y tambien viene pegado al detalle
/// de un canal (`schema`), para que reabrir su formulario sea una sola lectura.
class ChannelProviderModel {
  const ChannelProviderModel({
    required this.provider,
    required this.name,
    this.category = "",
    this.capabilities = const [],
    this.external,
    this.fields = const []
  });

  /// Codigo que se guarda en el canal (`whatsapp`, `instagram`, ...). Es lo que
  /// viaja en `PROVIDER` y lo unico que **no se puede cambiar** despues.
  final String provider;

  /// Nombre comercial ("WhatsApp Business").
  final String name;

  /// Familia a la que pertenece: `messaging`, `social`, `voice`, `email`, `web`.
  final String category;

  /// Que puede transportar el canal: `messages`, `comments`, `posts`,
  /// `mentions`, `calls`.
  final List<String> capabilities;

  /// Cual de los campos identifica la cuenta del lado del proveedor. Es el
  /// valor que no se puede conectar dos veces en toda la plataforma, asi que
  /// duplicarlo es el error `channel_already_connected`.
  final String? external;

  /// Todo lo que el proveedor necesita, en orden de formulario.
  final List<ChannelProviderField> fields;

  /// Proveedores que esta app sabe configurar hoy.
  ///
  /// El catalogo del backend trae muchos mas (Telegram, Slack, YouTube, correo,
  /// llamadas...), pero los canales se van habilitando de a poco: los de Meta
  /// primero. El resto se muestra en el selector, apagado, en vez de
  /// esconderse, para que se vea hacia donde va la seccion.
  ///
  /// Habilitar uno es agregar su codigo aca: sus campos ya vienen del catalogo
  /// y el formulario los dibuja solo.
  static const Set<String> supported = {
    "whatsapp",
    "messenger",
    "facebook",
    "instagram"
  };

  /// `true` si este proveedor ya se puede configurar desde la app.
  bool get isSupported => supported.contains(provider);

  /// Campos que viajan en `SETTINGS` (todo lo que no es secreto).
  List<ChannelProviderField> get settingsFields =>
    [for (final field in fields) if (!field.secret) field];

  /// Campos que viajan en `CREDENTIALS`.
  List<ChannelProviderField> get secretFields =>
    [for (final field in fields) if (field.secret) field];

  /// Icono de la red. Es cosmetico y se resuelve por codigo de proveedor, no
  /// por categoria: lo que se reconoce de un vistazo es la red, no la familia.
  IconData get icon => switch (provider) {
    "whatsapp" => CI.whatsapp,
    // Messenger no tiene marca propia en el set: queda el globo de chat, que es
    // lo que la app es.
    "messenger" => CI.chat,
    "facebook" => CI.facebook,
    "instagram" => CI.instagram,
    "telegram" => CI.telegram,
    "twitter" => CI.twitter,
    "youtube" => CI.youtube,
    "tiktok" => CI.tiktok,
    "linkedin" => CI.linkedin,
    "slack" => CI.slack,
    "discord" => CI.discord,
    "sms" => CI.sms,
    "voice" => CI.phone,
    "email" => CI.mail,
    "webchat" => Icons.language_outlined,
    _ => CI.link
  };

  factory ChannelProviderModel.fromJson(Map json) => ChannelProviderModel(
    provider: json["provider"]?.toString() ?? "",
    name: json["name"]?.toString() ?? "",
    category: json["category"]?.toString() ?? "",
    capabilities: [
      for (final item in _list(json["capabilities"])) item.toString()
    ],
    external: json["external"]?.toString(),
    fields: [
      for (final field in _list(json["fields"]))
        if (field is Map) ChannelProviderField.fromJson(field)
    ]
  );

  /// Lee una lista que puede venir ya decodificada o como el texto JSON de una
  /// (segun como el backend haya serializado la columna).
  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  /// Decodifica el catalogo. Acepta la tabla columnar
  /// (`{"keys": [...], "values": [...]}`) con la que viaja y tambien una lista
  /// de objetos, igual que el resto de los listados de la app.
  static List<ChannelProviderModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) ChannelProviderModel.fromJson(row)
      ];
    }

    if (data is Map) {
      final inner = data["providers"] ?? data["results"] ?? data["data"];
      if (inner != null && inner is! Map) return fromResponse(inner);

      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              ChannelProviderModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}
