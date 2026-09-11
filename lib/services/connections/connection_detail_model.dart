import 'package:app/services/connections/connection_provider_model.dart';

/// A connection with everything needed to reopen its form, exactly as
/// `GET /connections/detail/:CONNECTION_ID` returns it.
///
/// **The secrets don't come back.** [credentials] is the list of *key names*
/// under which a secret is saved — just enough for the form to say "access
/// token: configured" and offer to replace it —; the values never leave the
/// database, and no endpoint returns them. A token that got lost is
/// requested again from whoever issued it, not from this api.
///
/// [schema] comes attached to this same read: it's the provider's
/// description (what fields that service asks for), so the form can be
/// drawn without having to cross-reference this against the catalog.
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

  /// Account id on the provider's side. The backend computes it from the
  /// settings, it isn't edited by hand.
  final String? externalId;

  /// Flat configuration: account ids, hosts, usernames. This is what **does**
  /// get read back.
  final Map<String, dynamic> settings;

  /// Key names of the secrets already saved. Never their values.
  final List<String> credentials;

  /// Required keys still empty, in form order.
  final List<String> missing;

  /// Account jobs that already have a bot (`messages`, `comments`, ...).
  ///
  /// This belongs to the bots and not to the connection, so this form
  /// doesn't edit it: it's read to know what's left free for when one gets
  /// created, which is a decision made on another screen.
  final List<String> taken;

  /// `true` when [missing] is empty.
  final bool ready;

  /// This connection's provider description, to draw its form.
  final ConnectionProviderModel? schema;

  /// `true` if that secret is already saved on the other side.
  bool hasCredential(String key) => credentials.contains(key);

  /// Value of a flat setting as text, or empty if it isn't loaded.
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
