import 'package:app/services/channels/channel_table_model.dart';

/// A channel as returned by `GET /channels/`, with just enough to paint
/// its row: which network it is and what job it does on it, whether it is on,
/// which data sources it reads, and whether it is ready to work.
///
/// The configuration is deliberately not here: the tokens and the account ids
/// are read one channel at a time (`GET /channels/detail/:ID`), and no list
/// has to carry that. Besides, no read returns the secrets.
///
/// The data sources are the exception, and they travel **named** ([tables]):
/// a card that says "1 table" says nothing to a company with four of them,
/// and now that a channel carries no name of its own the table it answers
/// from is what tells one card from the next. The backend gathers them for
/// the whole listing in one pair of reads, not one per row.
class ChannelLiteModel {
  const ChannelLiteModel({
    required this.id,
    required this.provider,
    required this.scope,
    this.scopeName = "",
    this.name = "",
    this.description = "",
    this.position = 0,
    this.enabled = true,
    this.sources = 0,
    this.tables = const [],
    this.ready = false
  });

  final String id;

  /// Code of the network (`whatsapp`, `instagram`, ...). With it the provider
  /// is looked up in the catalog to know its name and icon.
  final String provider;

  /// What job this channel does on that network (`messages`, `comments`,
  /// `ad_comments`, `mentions`, `posts`, `calls`). A provider that supports
  /// several is connected once per job, each its own channel.
  final String scope;

  /// Human label of [scope] ("Comentarios en publicaciones"), computed by the
  /// backend so a listing does not need its own copy of the scope catalog.
  final String scopeName;

  /// Name the company gave it. A channel no longer needs one: empty is normal
  /// and not a loading gap.
  final String name;

  /// Empty when the channel was created without a description.
  final String description;

  /// Place it occupies in the order the company set up.
  final int position;

  /// How many data sources (product tables, today) this channel reads from.
  /// Always `tables.length` — it is the same answer counted, kept as its own
  /// field because that is the shape the backend sends.
  final int sources;

  /// Those sources, with the name each table has right now. Empty is the
  /// legitimate "this channel has nothing to answer from", which is what the
  /// card says in its place.
  final List<ChannelTableModel> tables;

  /// The company's switch: a channel can be paused without losing its
  /// configuration. Different from [ready], which is whether it is missing
  /// something.
  final bool enabled;

  /// `true` when all the required values of its network are loaded.
  ///
  /// A newly registered channel still without credentials is perfectly valid
  /// —it is registered before Meta issues the tokens— and simply not ready. The
  /// row shows it as "missing configuration" and not as an error.
  final bool ready;

  factory ChannelLiteModel.fromJson(Map json) => ChannelLiteModel(
    id: (json["id"] ?? json["ID"] ?? json["channel_id"])?.toString() ?? "",
    provider: (json["provider"] ?? json["PROVIDER"])?.toString() ?? "",
    scope: (json["scope"] ?? json["SCOPE"])?.toString() ?? "",
    scopeName: (json["scope_name"] ?? json["SCOPE_NAME"])?.toString() ?? "",
    name: (json["name"] ?? json["NAME"] ?? json["title"])?.toString() ?? "",
    description: (json["description"] ?? json["DESCRIPTION"])?.toString() ?? "",
    position: _number(json["position"] ?? json["POSITION"]) ?? 0,
    sources: _number(json["sources"] ?? json["SOURCES"]) ?? 0,
    tables: ChannelTableModel.fromResponse(json["tables"] ?? json["TABLES"]),
    // Without data it is assumed on, which is how a channel is born on the
    // other side.
    enabled: _flag(json["enabled"] ?? json["ENABLED"]) ?? true,
    // Without data it is assumed **not** ready: saying a half-configured
    // channel is working is worse than asking for it to be checked again.
    ready: _flag(json["ready"] ?? json["READY"]) ?? false
  );

  /// Copies the row with what is edited from the list.
  ChannelLiteModel copyWith({
    String? name,
    String? description,
    bool? enabled,
    bool? ready
  }) => ChannelLiteModel(
    id: id,
    provider: provider,
    scope: scope,
    scopeName: scopeName,
    name: name ?? this.name,
    description: description ?? this.description,
    position: position,
    sources: sources,
    tables: tables,
    enabled: enabled ?? this.enabled,
    ready: ready ?? this.ready
  );

  /// Reads a boolean that can come as such, as a number or as text: the
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

  /// Decodes the list. Like the rest of the app's lists, it accepts the
  /// columnar table (`{"keys": [...], "values": [...]}`) with which it travels
  /// compressed and also a list of objects.
  static List<ChannelLiteModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) ChannelLiteModel.fromJson(row)
      ];
    }

    if (data is Map) {
      final inner = data["channels"] ?? data["results"] ?? data["data"];
      if (inner != null && inner is! Map) return fromResponse(inner);

      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              ChannelLiteModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}
