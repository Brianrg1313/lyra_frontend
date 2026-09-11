import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// What kind of data a provider field asks for, as declared by the backend
/// (`ProviderField.type`).
///
/// It is not a validation: it is which keyboard and widget correspond. The only
/// one that changes behavior is [secret], which also decides **in which object
/// the value travels** (see [ChannelProviderField.secret]).
enum ChannelFieldType {
  text,
  secret,
  number,
  url,
  email,
  phone;

  /// Reads the type sent by the backend. Unknown ones are read as [text]: a new
  /// type in the catalog has to be configurable the same way from an old app,
  /// even if only with a plain text field.
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

/// A value a provider needs before it can connect: an entry of the channel
/// configuration form.
///
/// The catalog is declared entirely on the backend side
/// (`model:/channels/providers.js`), so **the front does not know a single
/// token**: it draws what it is sent, in the order it is sent. A provider added
/// to the catalog shows up on its own, without touching this app.
class ChannelProviderField {
  const ChannelProviderField({
    required this.key,
    required this.label,
    required this.type,
    required this.secret,
    required this.required,
    this.hint = ""
  });

  /// Key with which the value is stored, inside `SETTINGS` or `CREDENTIALS`
  /// depending on [secret].
  final String key;

  /// Label the form shows.
  final String label;
  final ChannelFieldType type;

  /// `true` if the value is a secret. It decides two things: that it travels in
  /// `CREDENTIALS` instead of `SETTINGS`, and that it is **never read back**.
  /// From a stored secret the backend only returns its key name, so the form
  /// can say "already configured" but not show it.
  final bool secret;

  /// `true` if the channel does not work without it.
  ///
  /// It is not the same as required to save: a channel is deliberately
  /// registered before it has its credentials —the company registers it today
  /// and pastes the tokens once Meta issues them—, so this only feeds the
  /// `ready` / `missing` of the reads and the "missing configuration" notice.
  final bool required;

  /// Where the value is found in the provider's console. The backend writes it
  /// and it is shown as is: it is the only clue whoever configures has.
  final String hint;

  factory ChannelProviderField.fromJson(Map json) {
    final type = ChannelFieldType.from(json["type"]);

    return ChannelProviderField(
      key: json["key"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      type: type,
      // The backend sends `secret` already computed, but it falls back to the
      // type if it did not come: having a secret drawn as plain text is not an
      // aesthetic detail, it is a token in plain sight.
      secret: json["secret"] == true || type == ChannelFieldType.secret,
      required: json["required"] == true,
      hint: json["hint"]?.toString() ?? ""
    );
  }
}

/// One job a provider's channel can be connected to do (`messages`,
/// `comments`, `ad_comments`, ...), with the label the picker shows for it.
///
/// A provider that declares more than one is connected once per job — each is
/// its own channel, with its own copy of the settings and credentials. See
/// `model:/channels/providers.js`.
class ChannelProviderScope {
  const ChannelProviderScope({required this.scope, required this.name});

  /// Code stored in `channels`.`scope`.
  final String scope;

  /// Human label ("Comments on posts").
  final String name;

  factory ChannelProviderScope.fromJson(Map json) => ChannelProviderScope(
    scope: json["scope"]?.toString() ?? "",
    name: json["name"]?.toString() ?? ""
  );
}

/// A provider from the catalog: a network to which a channel can connect, with
/// **exactly** what needs to be loaded to connect it.
///
/// It comes from `GET /channels/providers` and is also attached to a
/// channel's detail (`schema`), so that reopening its form is a single read.
class ChannelProviderModel {
  const ChannelProviderModel({
    required this.provider,
    required this.name,
    this.category = "",
    this.capabilities = const [],
    this.scopes = const [],
    this.external,
    this.fields = const []
  });

  /// Code stored in the channel (`whatsapp`, `instagram`, ...). It is what
  /// travels in `PROVIDER` and the only thing that **cannot be changed** later.
  final String provider;

  /// Trade name ("WhatsApp Business").
  final String name;

  /// Family it belongs to: `messaging`, `social`, `voice`, `email`, `web`.
  final String category;

  /// What the channel can carry: `messages`, `comments`, `posts`,
  /// `mentions`, `calls`.
  final List<String> capabilities;

  /// The jobs a channel on this service can be connected to do. `SCOPE` is
  /// required by the backend on creation, so the picker needs this to know
  /// what to send — see [defaultScope].
  final List<ChannelProviderScope> scopes;

  /// Which of the fields identifies the account on the provider's side. It is
  /// the value that cannot be connected twice across the whole platform, so
  /// duplicating it is the `channel_already_connected` error.
  final String? external;

  /// Everything the provider needs, in form order.
  final List<ChannelProviderField> fields;

  /// Code of the WhatsApp Personal option: linking a personal number by
  /// scanning a QR code, through the local `baileys_server` sidecar, instead
  /// of a Meta business account.
  ///
  /// **Not a catalog entry.** `GET /channels/providers` never sends this
  /// code — there is nothing to configure on the backend's side, since the
  /// number links locally — so [ChannelCatalogService.byCode] answers it
  /// from [whatsappPersonal] instead of searching the loaded catalog. Every
  /// other place that resolves a provider by code goes through that same
  /// method and gets this transparently.
  static const String whatsappPersonalCode = "whatsapp_personal";

  /// The synthetic schema for [whatsappPersonalCode]: single scope
  /// (`messages`), no fields at all — there are no tokens to paste, only a
  /// QR to scan once the channel exists (`BaileysChannelSwitch`,
  /// `CredentialsBlock`'s notice for this provider).
  factory ChannelProviderModel.whatsappPersonal() => ChannelProviderModel(
    provider: whatsappPersonalCode,
    name: S.current.channel_type_whatsapp_personal,
    category: "messaging",
    capabilities: const ["messages"],
    scopes: [
      ChannelProviderScope(
        scope: "messages",
        name: S.current.channel_capability_messages
      )
    ]
  );

  /// Providers this app knows how to configure today.
  ///
  /// The backend catalog brings many more (Telegram, Slack, YouTube, email,
  /// calls...), but channels are enabled gradually: Meta's first. The rest are
  /// shown in the selector, disabled, instead of being hidden, so that it is
  /// visible where the section is heading.
  ///
  /// Enabling one is adding its code here: its fields already come from the
  /// catalog and the form draws them on its own.
  static const Set<String> supported = {
    "whatsapp",
    "messenger",
    "facebook",
    "instagram"
  };

  /// `true` if this provider can already be configured from the app.
  bool get isSupported => supported.contains(provider);

  /// `true` when the provider does only one job (WhatsApp, Messenger: just
  /// `messages`). The picker can then send [defaultScope] on its own instead
  /// of asking which job this channel is for.
  ///
  /// A provider with several (Facebook, Instagram) is left out of the picker
  /// until it has a scope selector of its own — offering it without one would
  /// connect a channel for whichever job happens to come first in the list.
  bool get hasSingleScope => scopes.length == 1;

  /// The scope to send on creation, when [hasSingleScope]. Empty otherwise.
  String get defaultScope => hasSingleScope ? scopes.first.scope : "";

  /// Fields that travel in `SETTINGS` (everything that is not a secret).
  List<ChannelProviderField> get settingsFields =>
    [for (final field in fields) if (!field.secret) field];

  /// Fields that travel in `CREDENTIALS`.
  List<ChannelProviderField> get secretFields =>
    [for (final field in fields) if (field.secret) field];

  /// Network icon. It is cosmetic and resolved by provider code, not by
  /// category: what is recognized at a glance is the network, not the family.
  IconData get icon => switch (provider) {
    "whatsapp" || whatsappPersonalCode => CI.whatsapp,
    // Messenger has no brand of its own in the set: the chat balloon is left,
    // which is what the app is.
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
    scopes: [
      for (final item in _list(json["scopes"]))
        if (item is Map) ChannelProviderScope.fromJson(item)
    ],
    external: json["external"]?.toString(),
    fields: [
      for (final field in _list(json["fields"]))
        if (field is Map) ChannelProviderField.fromJson(field)
    ]
  );

  /// Reads a list that may come already decoded or as the JSON text of one
  /// (depending on how the backend serialized the column).
  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  /// Decodes the catalog. It accepts the columnar table
  /// (`{"keys": [...], "values": [...]}`) with which it travels and also a
  /// list of objects, like the rest of the app's lists.
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
