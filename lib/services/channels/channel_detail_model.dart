import 'package:app/services/channels/channel_payment_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channel_table_model.dart';

/// A channel with everything needed to reopen its form, as returned by
/// `GET /channels/detail/:CHANNEL_ID`.
///
/// **The secrets do not come.** [credentials] is the list of *key names* under
/// which a secret is stored —just enough for the form to say "access token:
/// configured" and offer to replace it—; the values do not leave the database,
/// and there is no endpoint that returns them. A lost token is requested again
/// from whoever issued it, not from this api.
///
/// [schema] comes attached in the same read: it is the provider's description
/// (which fields that network asks for), so the form is drawn without having to
/// cross-reference this with the catalog.
class ChannelDetailModel {
  const ChannelDetailModel({
    required this.id,
    required this.provider,
    required this.name,
    this.description = "",
    this.role = "",
    this.position = 0,
    this.enabled = true,
    this.externalId,
    this.settings = const {},
    this.credentials = const [],
    this.tables = const [],
    this.paymentMethods = const [],
    this.missing = const [],
    this.ready = false,
    this.schema
  });

  final String id;
  final String provider;
  final String name;
  final String description;

  /// Persona it answers with (`sales`, `support`, `marketing`, `services`,
  /// `billing`, `general`), a real column on the backend and not app-invented
  /// settings — see [ChannelAgentRole].
  final String role;

  final int position;
  final bool enabled;

  /// Id of the account on the provider's side. The backend computes it from
  /// the settings; it is not edited by hand.
  final String? externalId;

  /// Flat configuration: account ids, hosts, users. It is what **is** read
  /// back, and where this app's own settings also live (the agent role, the
  /// data source and the tools).
  final Map<String, dynamic> settings;

  /// Key names of the already stored secrets. Never their values.
  final List<String> credentials;

  /// The company's own tables this channel may read from, linked in
  /// `channel_tables`. Their names come attached so the form does not need a
  /// second read to show which ones they are.
  final List<ChannelTableModel> tables;

  /// The company's payment accounts this channel may offer a customer, linked
  /// in `channel_payment_methods`. They come named for the same reason the
  /// tables do: the form has to say which account it is offering, and the
  /// money screen is behind a permission whoever arranges channels does not
  /// necessarily have.
  final List<ChannelPaymentModel> paymentMethods;

  /// Required keys still empty, in form order.
  final List<String> missing;

  /// `true` when [missing] is empty.
  final bool ready;

  /// Description of this channel's provider, to draw its form.
  final ChannelProviderModel? schema;

  /// `true` if that secret is already stored on the other side.
  bool hasCredential(String key) => credentials.contains(key);

  /// Value of a flat setting as text, or empty if it is not loaded.
  String setting(String key) {
    final value = settings[key];
    return value == null ? "" : value.toString();
  }

  /// Value of a boolean setting. They are stored as real booleans
  /// (`Channels.config` accepts them), but are read tolerantly because a round
  /// trip through JSON can leave them as a number or as text.
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
      role: json["role"]?.toString() ?? "",
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
      tables: ChannelTableModel.fromResponse(json["tables"]),
      paymentMethods: ChannelPaymentModel.fromResponse(json["payment_methods"]),
      missing: [for (final key in _list(json["missing"])) key.toString()],
      ready: json["ready"] == true,
      schema: schema is Map ? ChannelProviderModel.fromJson(schema) : null
    );
  }

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];
}
