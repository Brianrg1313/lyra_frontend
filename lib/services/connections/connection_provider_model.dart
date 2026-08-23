import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Que clase de dato pide un campo de un proveedor, tal como lo declara el
/// backend (`ProviderField.type`).
///
/// No es una validacion: es que teclado y que widget corresponde. El unico que
/// cambia el comportamiento es [secret], que ademas decide **en que objeto
/// viaja el valor** (ver [ConnectionProviderField.secret]).
enum ConnectionFieldType {
  text,
  secret,
  number,
  url,
  email,
  phone;

  /// Lee el tipo que mando el backend. Lo desconocido se lee como [text]: un
  /// tipo nuevo del catalogo tiene que poder configurarse igual desde una app
  /// vieja, aunque sea con un campo de texto pelado.
  static ConnectionFieldType from(dynamic raw) => switch (
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

/// Un valor que un proveedor necesita antes de poder conectar la cuenta: una
/// entrada del formulario de configuracion de la conexion.
///
/// El catalogo lo declara entero del lado del backend
/// (`model:/connections/providers.js`), asi que **el front no conoce ni un solo
/// token**: dibuja lo que le mandan, en el orden en que se lo mandan. Un
/// proveedor agregado al catalogo aparece solo, sin tocar esta app.
class ConnectionProviderField {
  const ConnectionProviderField({
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
  final ConnectionFieldType type;

  /// `true` si el valor es un secreto. Decide dos cosas: que viaje en
  /// `CREDENTIALS` en vez de `SETTINGS`, y que **no se lea de vuelta nunca**.
  /// De un secreto guardado el backend solo devuelve su nombre de clave, asi
  /// que el formulario puede decir "ya configurado" pero no mostrarlo.
  final bool secret;

  /// `true` si la cuenta no funciona sin el.
  ///
  /// No es lo mismo que obligatorio para guardar: una conexion se registra a
  /// proposito antes de tener sus credenciales —la empresa la da de alta hoy y
  /// pega los tokens cuando el servicio se los emita—, asi que esto solo
  /// alimenta el `ready` / `missing` de las lecturas y el aviso de "falta
  /// configurar".
  final bool required;

  /// Donde se encuentra el valor en la consola del proveedor. Lo escribe el
  /// backend y se muestra tal cual: es la unica pista que tiene quien configura.
  final String hint;

  factory ConnectionProviderField.fromJson(Map json) {
    final type = ConnectionFieldType.from(json["type"]);

    return ConnectionProviderField(
      key: json["key"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      type: type,
      // El backend manda `secret` calculado, pero se cae al tipo si no vino:
      // que un secreto se dibuje como texto plano no es un detalle estetico,
      // es un token a la vista.
      secret: json["secret"] == true || type == ConnectionFieldType.secret,
      required: json["required"] == true,
      hint: json["hint"]?.toString() ?? ""
    );
  }
}

/// Un trabajo al que se puede poner la cuenta conectada: lo que contesta un bot
/// creado sobre ella (mensajes directos, comentarios de publicaciones,
/// comentarios de anuncios, menciones).
///
/// **Aca no se configura ninguno.** Una conexion es la cuenta y sus
/// credenciales; los trabajos son bots y se arman en otra parte. Esto se lee
/// para saber que se va a poder hacer con la cuenta que se esta conectando: un
/// login de Instagram da cuatro trabajos, un numero de WhatsApp exactamente uno.
class ConnectionScope {
  const ConnectionScope({required this.scope, required this.name});

  /// Codigo del trabajo (`messages`, `comments`, `ad_comments`, ...).
  final String scope;

  /// Nombre que le puso el backend. Se usa **solo como respaldo**: los codigos
  /// conocidos se traducen en la app (ver `ProviderPicker`), porque el catalogo
  /// los manda en un idioma solo.
  final String name;

  factory ConnectionScope.fromJson(Map json) => ConnectionScope(
    scope: json["scope"]?.toString() ?? "",
    name: json["name"]?.toString() ?? ""
  );

  /// Lee un trabajo que puede venir como objeto (`{scope, name}`) o como el
  /// codigo pelado, que es lo que manda cualquier lectura mas comprimida.
  static ConnectionScope? from(dynamic raw) {
    if (raw is Map) {
      final scope = ConnectionScope.fromJson(raw);
      return scope.scope.isEmpty ? null : scope;
    }

    final code = raw?.toString().trim() ?? "";

    return code.isEmpty ? null : ConnectionScope(scope: code, name: code);
  }
}

/// Un proveedor del catalogo: un servicio al que se le puede conectar una
/// cuenta, con **exactamente** lo que hay que cargarle para conectarla y para
/// que sirve una vez conectada.
///
/// Sale de `GET /connections/providers` y tambien viene pegado al detalle de una
/// conexion (`schema`), para que reabrir su formulario sea una sola lectura.
class ConnectionProviderModel {
  const ConnectionProviderModel({
    required this.provider,
    required this.name,
    this.category = "",
    this.scopes = const [],
    this.external,
    this.fields = const []
  });

  /// Codigo que se guarda en la conexion (`whatsapp`, `instagram`, ...). Es lo
  /// que viaja en `PROVIDER` y lo unico que **no se puede cambiar** despues.
  final String provider;

  /// Nombre comercial ("WhatsApp Business").
  final String name;

  /// Familia a la que pertenece: `messaging`, `social`, `voice`, `email`, `web`.
  final String category;

  /// A que se puede poner a trabajar la cuenta. Es tambien cuantos bots puede
  /// alimentar: uno por trabajo.
  final List<ConnectionScope> scopes;

  /// Cual de los campos identifica la cuenta del lado del proveedor. Es el
  /// valor que no se puede conectar dos veces en toda la plataforma, asi que
  /// duplicarlo es el error `connection_already_exists`.
  final String? external;

  /// Todo lo que el proveedor necesita, en orden de formulario.
  final List<ConnectionProviderField> fields;

  /// Proveedores que esta app sabe configurar hoy.
  ///
  /// El catalogo del backend trae muchos mas (Telegram, Slack, YouTube, correo,
  /// llamadas...), pero las integraciones se van habilitando de a poco: las de
  /// Meta primero. El resto se muestra en el selector, apagado, en vez de
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
  List<ConnectionProviderField> get settingsFields =>
    [for (final field in fields) if (!field.secret) field];

  /// Campos que viajan en `CREDENTIALS`.
  List<ConnectionProviderField> get secretFields =>
    [for (final field in fields) if (field.secret) field];

  /// Icono del servicio. Es cosmetico y se resuelve por codigo de proveedor, no
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

  factory ConnectionProviderModel.fromJson(Map json) =>
    ConnectionProviderModel(
      provider: json["provider"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      scopes: [
        for (final item in _list(json["scopes"])) ?ConnectionScope.from(item)
      ],
      external: json["external"]?.toString(),
      fields: [
        for (final field in _list(json["fields"]))
          if (field is Map) ConnectionProviderField.fromJson(field)
      ]
    );

  /// Lee una lista que puede venir ya decodificada o no venir del todo.
  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  /// Decodifica el catalogo. Acepta la tabla columnar
  /// (`{"keys": [...], "values": [...]}`) con la que viaja y tambien una lista
  /// de objetos, igual que el resto de los listados de la app.
  static List<ConnectionProviderModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) ConnectionProviderModel.fromJson(row)
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
              ConnectionProviderModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}
