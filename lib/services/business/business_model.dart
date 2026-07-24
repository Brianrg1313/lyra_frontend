class BusinessModel {
  final String id;
  final String name;
  final String caption;

  /// Solo llegan al crear la empresa desde la app; `/init` no los devuelve y
  /// quedan vacios para las empresas que vienen de la sesion.
  final String activity;
  final String profile;

  const BusinessModel({
    required this.id,
    required this.name,
    this.caption = "",
    this.activity = "",
    this.profile = "",
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json["id"]?.toString() ?? "",
      name: json["name"] ?? "",
      caption: json["caption"] ?? "",
      activity: json["activity"] ?? "",
      profile: json["profile"] ?? "",
    );
  }

  /// Decodifica la tabla columnar de `/init`:
  /// `{"keys": ["id", "name", "caption"], "values": [[...], ...]}`.
  ///
  /// Las columnas se leen por nombre y no por posicion, asi que el backend
  /// puede reordenarlas o agregar campos sin romper el parseo.
  static List<BusinessModel> fromTable(dynamic table) {
    if (table is! Map) return const [];

    final keys = table["keys"];
    final rows = table["values"];

    if (keys is! List || rows is! List) return const [];

    return [
      for (final row in rows)
        if (row is List)
          BusinessModel.fromJson({
            for (int i = 0; i < keys.length && i < row.length; i++)
              keys[i].toString(): row[i]
          })
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "caption": caption,
      "activity": activity,
      "profile": profile,
    };
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    String? caption,
    String? activity,
    String? profile,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      caption: caption ?? this.caption,
      activity: activity ?? this.activity,
      profile: profile ?? this.profile,
    );
  }
}
