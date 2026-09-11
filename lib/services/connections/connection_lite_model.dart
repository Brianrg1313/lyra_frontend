/// A connection exactly as `GET /connections/` returns it, with just enough
/// to paint its row: which service the account is for, what the business
/// named it, whether it's on, whether it's ready to work, and how many bots
/// are running on top of it.
///
/// The configuration is deliberately not here: tokens and account ids are
/// read one connection at a time (`GET /connections/detail/:CONNECTION_ID`),
/// and no listing needs to move that around. The secrets, moreover, aren't
/// returned by any read.
class ConnectionLiteModel {
  const ConnectionLiteModel({
    required this.id,
    required this.provider,
    required this.name,
    this.description = "",
    this.position = 0,
    this.enabled = true,
    this.bots = 0,
    this.ready = false
  });

  final String id;

  /// Service code (`whatsapp`, `instagram`, ...). It's used to look up the
  /// provider in the catalog to get its name and icon.
  final String provider;

  /// Name the business gave it ("Main account", "Sales").
  final String name;

  /// Empty when the connection was created without a description.
  final String description;

  /// Its position in the order the business arranged.
  final int position;

  /// The business's on/off switch: an account can be paused without losing
  /// its configuration. Different from [ready], which is whether it's
  /// missing something.
  final bool enabled;

  /// How many bots are answering through this account.
  ///
  /// It's the number that makes the row worth reading — which account it is,
  /// and how much is running on top of it — and also **what gets lost when
  /// it's disconnected**: a bot without an account has no way to answer, so
  /// removal takes them down with it. That's why the confirmation names
  /// them.
  final int bots;

  /// `true` when all of its service's required values are filled in.
  ///
  /// A freshly registered connection that still has no credentials is
  /// perfectly valid — it's registered before the service issues its tokens
  /// — and simply isn't ready yet. The row shows this as "needs configuring"
  /// rather than as an error.
  final bool ready;

  factory ConnectionLiteModel.fromJson(Map json) => ConnectionLiteModel(
    id: (json["id"] ?? json["ID"] ?? json["connection_id"])?.toString() ?? "",
    provider: (json["provider"] ?? json["PROVIDER"])?.toString() ?? "",
    name: (json["name"] ?? json["NAME"])?.toString() ?? "",
    description: (json["description"] ?? json["DESCRIPTION"])?.toString() ?? "",
    position: _number(json["position"] ?? json["POSITION"]) ?? 0,
    bots: _number(json["bots"] ?? json["BOTS"]) ?? 0,
    // With no data it's assumed to be on, which is how a connection is born
    // on the other side.
    enabled: _flag(json["enabled"] ?? json["ENABLED"]) ?? true,
    // With no data it's assumed **not** ready: saying that a half-configured
    // account is working is worse than asking for it to be checked
    // unnecessarily.
    ready: _flag(json["ready"] ?? json["READY"]) ?? false
  );

  /// Copies the row with what can be edited from the listing.
  ConnectionLiteModel copyWith({
    String? name,
    String? description,
    bool? enabled,
    bool? ready
  }) => ConnectionLiteModel(
    id: id,
    provider: provider,
    name: name ?? this.name,
    description: description ?? this.description,
    position: position,
    enabled: enabled ?? this.enabled,
    bots: bots,
    ready: ready ?? this.ready
  );

  /// Reads a boolean that can arrive as such, as a number, or as text: the
  /// backend normalizes it, but the column travels over JSON and MySQL sends
  /// `TINYINT`.
  static bool? _flag(dynamic value) => switch (value) {
    final bool flag => flag,
    final num number => number != 0,
    "1" || "true" => true,
    "0" || "false" => false,
    _ => null
  };

  static int? _number(dynamic value) => switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };

  /// Decodes the listing. Like the rest of the app's listings, it accepts
  /// the columnar table (`{"keys": [...], "values": [...]}`) that it travels
  /// compressed as, and also a list of objects.
  static List<ConnectionLiteModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) ConnectionLiteModel.fromJson(row)
      ];
    }

    if (data is Map) {
      final inner = data["connections"] ?? data["results"] ?? data["data"];
      if (inner != null && inner is! Map) return fromResponse(inner);

      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              ConnectionLiteModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}
