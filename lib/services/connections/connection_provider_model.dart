import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// What kind of data a provider field asks for, exactly as the backend
/// declares it (`ProviderField.type`).
///
/// It isn't validation: it's which keyboard and which widget applies. The
/// only one that changes behavior is [secret], which also decides **which
/// object the value travels in** (see [ConnectionProviderField.secret]).
enum ConnectionFieldType {
  text,
  secret,
  number,
  url,
  email,
  phone;

  /// Reads the type the backend sent. Unknown values are read as [text]: a
  /// new catalog type still has to be configurable from an old app, even if
  /// only with a plain text field.
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

/// A value a provider needs before the account can be connected: an entry in
/// the connection's configuration form.
///
/// The catalog declares it entirely on the backend side
/// (`model:/connections/providers.js`), so **the front end doesn't know a
/// single token**: it draws whatever it's sent, in the order it's sent in. A
/// provider added to the catalog shows up on its own, without touching this
/// app.
class ConnectionProviderField {
  const ConnectionProviderField({
    required this.key,
    required this.label,
    required this.type,
    required this.secret,
    required this.required,
    this.hint = ""
  });

  /// Key the value is saved under, inside `SETTINGS` or `CREDENTIALS`
  /// depending on [secret].
  final String key;

  /// Label the form displays.
  final String label;
  final ConnectionFieldType type;

  /// `true` if the value is a secret. It decides two things: that it travels
  /// in `CREDENTIALS` instead of `SETTINGS`, and that **it's never read
  /// back**. Of a saved secret the backend only returns its key name, so the
  /// form can say "already configured" but can't show it.
  final bool secret;

  /// `true` if the account doesn't work without it.
  ///
  /// It isn't the same as required to save: a connection is deliberately
  /// registered before it has its credentials — the business registers it
  /// today and pastes the tokens once the service issues them — so this only
  /// feeds the `ready` / `missing` on reads and the "needs configuring"
  /// notice.
  final bool required;

  /// Where to find the value in the provider's console. The backend writes
  /// it and it's shown as-is: it's the only hint whoever is configuring it
  /// has.
  final String hint;

  factory ConnectionProviderField.fromJson(Map json) {
    final type = ConnectionFieldType.from(json["type"]);

    return ConnectionProviderField(
      key: json["key"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      type: type,
      // The backend sends `secret` already computed, but it falls back to
      // the type if it didn't come: a secret being drawn as plain text isn't
      // a cosmetic detail, it's a token in plain sight.
      secret: json["secret"] == true || type == ConnectionFieldType.secret,
      required: json["required"] == true,
      hint: json["hint"]?.toString() ?? ""
    );
  }
}

/// A job the connected account can be put to work on: what a bot built on
/// top of it answers (direct messages, post comments, ad comments,
/// mentions).
///
/// **None is configured here.** A connection is the account and its
/// credentials; jobs are bots and are built elsewhere. This is read to know
/// what will be possible with the account being connected: an Instagram
/// login gives four jobs, a WhatsApp number exactly one.
class ConnectionScope {
  const ConnectionScope({required this.scope, required this.name});

  /// Job code (`messages`, `comments`, `ad_comments`, ...).
  final String scope;

  /// Name the backend gave it. Used **only as a fallback**: known codes are
  /// translated in the app (see `ProviderPicker`), because the catalog only
  /// sends them in one language.
  final String name;

  factory ConnectionScope.fromJson(Map json) => ConnectionScope(
    scope: json["scope"]?.toString() ?? "",
    name: json["name"]?.toString() ?? ""
  );

  /// Reads a job that can arrive as an object (`{scope, name}`) or as a
  /// plain code, which is what any more compressed read sends.
  static ConnectionScope? from(dynamic raw) {
    if (raw is Map) {
      final scope = ConnectionScope.fromJson(raw);
      return scope.scope.isEmpty ? null : scope;
    }

    final code = raw?.toString().trim() ?? "";

    return code.isEmpty ? null : ConnectionScope(scope: code, name: code);
  }
}

/// A catalog provider: a service an account can be connected to, with
/// **exactly** what needs to be filled in to connect it and what it's good
/// for once connected.
///
/// It comes from `GET /connections/providers` and is also attached to a
/// connection's detail (`schema`), so reopening its form is a single read.
class ConnectionProviderModel {
  const ConnectionProviderModel({
    required this.provider,
    required this.name,
    this.category = "",
    this.scopes = const [],
    this.external,
    this.fields = const []
  });

  /// Code saved on the connection (`whatsapp`, `instagram`, ...). It's what
  /// travels in `PROVIDER` and the only thing that **can't be changed**
  /// afterward.
  final String provider;

  /// Commercial name ("WhatsApp Business").
  final String name;

  /// Family it belongs to: `messaging`, `social`, `voice`, `email`, `web`.
  final String category;

  /// What the account can be put to work on. It's also how many bots it can
  /// feed: one per job.
  final List<ConnectionScope> scopes;

  /// Which of the fields identifies the account on the provider's side. It's
  /// the value that can't be connected twice across the whole platform, so
  /// duplicating it is the `connection_already_exists` error.
  final String? external;

  /// Everything the provider needs, in form order.
  final List<ConnectionProviderField> fields;

  /// Providers this app already knows how to configure today.
  ///
  /// The backend's catalog carries many more (Telegram, Slack, YouTube,
  /// email, calls...), but integrations get enabled little by little: Meta's
  /// first. The rest are shown in the selector, greyed out, instead of being
  /// hidden, so it's clear where the section is headed.
  ///
  /// Enabling one just means adding its code here: its fields already come
  /// from the catalog and the form draws them on its own.
  static const Set<String> supported = {
    "whatsapp",
    "messenger",
    "facebook",
    "instagram"
  };

  /// `true` if this provider can already be configured from the app.
  bool get isSupported => supported.contains(provider);

  /// Fields that travel in `SETTINGS` (everything that isn't secret).
  List<ConnectionProviderField> get settingsFields =>
    [for (final field in fields) if (!field.secret) field];

  /// Fields that travel in `CREDENTIALS`.
  List<ConnectionProviderField> get secretFields =>
    [for (final field in fields) if (field.secret) field];

  /// Service icon. It's cosmetic and resolved by provider code, not by
  /// category: what's recognized at a glance is the network, not the family.
  IconData get icon => switch (provider) {
    "whatsapp" => CI.whatsapp,
    // Messenger doesn't have its own brand in the icon set: it gets the chat
    // bubble instead, which is what the app is.
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

  /// Reads a list that may already come decoded or may not come at all.
  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  /// Decodes the catalog. It accepts the columnar table
  /// (`{"keys": [...], "values": [...]}`) that it travels as and also a list
  /// of objects, just like the rest of the app's listings.
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
