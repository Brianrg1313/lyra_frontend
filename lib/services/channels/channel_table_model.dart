/// One of the company's own tables a channel reads from, as the backend
/// attaches it to a channel — both in the list (`GET /channels/`) and in the
/// detail (`GET /channels/detail/:ID`).
///
/// It is the id **and** the name, and the name is not a convenience: it is
/// re-joined against the tables database on every read, so a table deleted
/// since it was linked simply does not come back instead of arriving as a
/// source that no longer exists. What is stored on the channel is the id
/// alone, which is why renaming a table does not disconnect it.
class ChannelTableModel {
  const ChannelTableModel({required this.id, required this.name});

  final String id;
  final String name;

  factory ChannelTableModel.fromJson(Map json) => ChannelTableModel(
    id: json["id"]?.toString() ?? "",
    name: json["name"]?.toString() ?? ""
  );

  /// Decodes the list a channel carries. It arrives as a list of objects in
  /// both reads; anything else —a key that did not travel, a `null` on a
  /// channel with no sources— is no sources, which is a legitimate state and
  /// not a failure.
  static List<ChannelTableModel> fromResponse(dynamic value) {
    if (value is! List) return const [];

    return [
      for (final item in value)
        if (item is Map) ChannelTableModel.fromJson(item)
    ];
  }
}
