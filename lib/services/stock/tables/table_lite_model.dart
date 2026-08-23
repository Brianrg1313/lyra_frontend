/// Tabla de productos tal como la devuelve `GET /tables/list/`, pero solo
/// con lo justo para pintar el listado: el identificador, el titulo, la
/// descripcion y que tan grande es (cuantas columnas y cuantos registros).
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

  /// Cantidad de registros cargados en la tabla.
  ///
  /// Es nulo —y no cero— cuando el backend no pudo contarlos: las filas viven
  /// en otra base que las columnas, asi que la cuenta puede fallar sola. Una
  /// tabla cuyos registros no se pudieron contar no es una tabla vacia, y el
  /// listado prefiere no decir nada antes que decir que esta vacia.
  final int? records;

  const TableLiteModel({
    required this.id,
    required this.title,
    this.description = "",
    this.fields = 0,
    this.records
  });

  /// Lee una fila. Las claves se contemplan en las dos convenciones que puede
  /// mandar el backend —las mayusculas del contrato de alta (`TITLE`, `FIELDS`)
  /// y las minusculas habituales de una lectura— asi el parseo no se ata a una
  /// sola forma.
  factory TableLiteModel.fromJson(Map json) => TableLiteModel(
    id: (json["id"] ?? json["ID"] ?? json["table_id"])?.toString() ?? "",
    title: json["TITLE"] ?? json["title"] ?? json["name"] ?? "",
    description: json["DESCRIPTION"] ?? json["description"] ?? "",
    fields: _count(
      json["FIELDS"] ?? json["fields"] ??
      json["fields_count"] ?? json["field_count"]
    ) ?? 0,
    records: _count(
      json["RECORDS"] ?? json["records"] ??
      json["records_count"] ?? json["record_count"]
    )
  );

  /// Lee una cantidad de la respuesta.
  ///
  /// Puede venir ya contada (un numero, o el texto de uno) o como la lista
  /// entera de la que solo interesa el largo —asi llegan los campos cuando se
  /// lee la estructura completa—. Lo que no sea ninguna de las dos cosas
  /// (incluido no venir) se lee como "no se sabe", que es distinto de cero:
  /// quien la use decide que hacer con eso.
  static int? _count(dynamic value) => switch (value) {
    final List list => list.length,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };

  /// Copia la tabla con los textos cambiados. La usa el listado para reflejar
  /// una edicion sin volver a pedirle todo al backend: lo unico que se edita
  /// desde ahi son el titulo y la descripcion, y las cantidades siguen siendo
  /// las mismas.
  TableLiteModel withText({String? title, String? description}) =>
    TableLiteModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fields: fields,
      records: records
    );

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
