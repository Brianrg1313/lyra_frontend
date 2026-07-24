/// Tabla de productos tal como la devuelve `GET /tables/list/`, pero solo
/// con lo justo para pintar el listado: el identificador, el titulo, la
/// descripcion y cuantas columnas tiene.
///
/// Es la version "lite" a proposito: la estructura completa (el detalle de cada
/// campo, su tipo y su orden) no hace falta para listar las tablas de una
/// empresa, asi que no se carga hasta que se abra una. Aca solo entra lo que se
/// ve en la fila.
class TableLiteModel {
  final String id;
  final String title;

  /// Vacia cuando la tabla se creo sin descripcion (es opcional en el alta).
  final String description;

  /// Cantidad de columnas de la tabla. Se muestra como referencia rapida de
  /// que tan grande es sin tener que abrirla.
  final int fields;

  const TableLiteModel({
    required this.id,
    required this.title,
    this.description = "",
    this.fields = 0,
  });

  /// Lee una fila. Las claves se contemplan en las dos convenciones que puede
  /// mandar el backend —las mayusculas del contrato de alta (`TITLE`, `FIELDS`)
  /// y las minusculas habituales de una lectura— asi el parseo no se ata a una
  /// sola forma.
  factory TableLiteModel.fromJson(Map json) {
    final rawFields = json["FIELDS"] ?? json["fields"];

    return TableLiteModel(
      id: (json["id"] ?? json["ID"] ?? json["table_id"])?.toString() ?? "",
      title: json["TITLE"] ?? json["title"] ?? json["name"] ?? "",
      description: json["DESCRIPTION"] ?? json["description"] ?? "",
      // La cantidad puede venir ya contada (`fields_count`) o como la lista
      // entera de columnas, de la que solo interesa el largo.
      fields: switch (rawFields) {
        final List list => list.length,
        _ => (json["fields_count"] ?? json["field_count"] ?? 0) is num
          ? ((json["fields_count"] ?? json["field_count"] ?? 0) as num).toInt()
          : 0
      },
    );
  }

  /// Decodifica la respuesta del listado sin atarse a un unico formato: acepta
  /// tanto una lista de objetos como la tabla columnar
  /// (`{"keys": [...], "values": [...]}`) que ya usan `/init` y `/business/list/`.
  /// Asi el parseo no se rompe si el backend cambia de forma.
  static List<TableLiteModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) TableLiteModel.fromJson(row)
      ];
    }

    if (data is Map) {
      // Algunos endpoints envuelven el listado en una clave.
      final inner = data["tables"] ?? data["results"] ?? data["data"];
      if (inner != null && inner is! Map) return fromResponse(inner);

      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              TableLiteModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}
