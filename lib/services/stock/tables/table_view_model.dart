/// Una columna de una tabla, tal como la describe
/// `GET /tables/view/<table_id>/<index>`.
///
/// Trae tres cosas que se usan en distintos momentos: el [id] (el FIELD_ID, el
/// UUID publico del campo) es la clave con la que se guardan los datos en
/// `POST /products/manage/`; el [name] es el encabezado que ve el usuario; y el
/// [type] (el codigo del tipo: `TEXT`, `PRICE`, `NUMBER`...) decide con que
/// editor se carga la celda.
class TableColumnModel {
  const TableColumnModel({
    required this.id,
    required this.name,
    this.type = ""
  });

  /// FIELD_ID: UUID publico del campo. Vacio solo si la respuesta no lo trae,
  /// en cuyo caso la columna no se puede guardar.
  final String id;

  /// Encabezado visible.
  final String name;

  /// Codigo del tipo del campo (`TEXT`, `PRICE`, ...), o vacio si no vino.
  final String type;
}

/// Una fila de datos. Los valores van en el mismo orden que
/// [TableViewModel.columns], asi que se leen por posicion.
class TableRowModel {
  const TableRowModel(this.values);

  final List<dynamic> values;

  /// Valor de la celda en la columna [index], o `null` si la fila es mas corta.
  dynamic at(int index) =>
    index >= 0 && index < values.length ? values[index] : null;
}

/// Una pagina de datos de una tabla: los encabezados (las columnas, con su
/// FIELD_ID) y las filas de esa pagina. Es lo que se pinta con `DataTableView`
/// de `core/tables`.
///
/// La lectura es paginada (`.../view/<table_id>/<index>`), asi que cada
/// [TableViewModel] es solo un tramo de la tabla, no la tabla entera; quien
/// pagina es [TableViewService].
class TableViewModel {
  const TableViewModel({
    this.columns = const [],
    this.rows = const []
  });

  final List<TableColumnModel> columns;
  final List<TableRowModel> rows;

  bool get isEmpty => rows.isEmpty;

  /// Decodifica una pagina sin atarse a un unico formato: acepta la tabla
  /// columnar (`{"keys": [...], "values": [...]}`) que ya usan `/init` y
  /// `/business/list/`, una lista de objetos, o cualquiera de esas dos envuelta
  /// en una clave. Asi el parseo no se rompe si el backend cambia de forma.
  ///
  /// En el formato columnar cada encabezado (`keys[i]`) puede venir como un
  /// objeto con el FIELD_ID, el nombre y el tipo, o como un texto pelado (y ahi
  /// solo se tiene el nombre). Las filas (`values`) van alineadas por posicion
  /// con los encabezados.
  factory TableViewModel.fromResponse(dynamic data) {
    if (data is Map) {
      final keys = data["keys"] ?? data["columns"] ?? data["fields"];
      final values = data["values"] ?? data["rows"];

      if (keys is List && values is List) {
        final columns = [for (final key in keys) _column(key)];

        return TableViewModel(
          columns: columns,
          rows: [
            for (final row in values)
              if (row is List)
                TableRowModel(List<dynamic>.of(row))
              // Por las dudas la fila venga como objeto: se ordena contra las
              // columnas, buscando el valor por FIELD_ID y, si no, por nombre.
              else if (row is Map)
                TableRowModel([
                  for (final column in columns)
                    row[column.id] ?? row[column.name]
                ])
          ]
        );
      }

      // Algunos endpoints envuelven la pagina (y su metadata de paginacion) en
      // una clave: se baja un nivel a buscar los datos.
      final inner = data["data"] ?? data["results"] ?? data["table"] ?? data["page"];
      if (inner is List || inner is Map) return TableViewModel.fromResponse(inner);
    }

    // Lista de objetos: cada fila es un mapa. Las columnas salen de la primera
    // fila (sin FIELD_ID, que ese formato no lo trae) y el orden es el del JSON.
    if (data is List) {
      final maps = [for (final row in data) if (row is Map) row];
      if (maps.isEmpty) return const TableViewModel();

      final columns = [
        for (final key in maps.first.keys)
          TableColumnModel(id: "", name: key.toString())
      ];

      return TableViewModel(
        columns: columns,
        rows: [
          for (final row in maps)
            TableRowModel([for (final column in columns) row[column.name]])
        ]
      );
    }

    return const TableViewModel();
  }

  /// Lee un encabezado en cualquiera de sus dos formas: un objeto con el
  /// FIELD_ID, el nombre y el tipo, o un texto pelado que solo da el nombre. Las
  /// claves se contemplan en mayusculas (el contrato) y minusculas (una lectura
  /// habitual) por las dudas.
  static TableColumnModel _column(dynamic key) {
    if (key is Map) {
      final id = (key["ID"] ?? key["id"] ?? key["FIELD_ID"] ?? key["field_id"] ?? key["uuid"])?.toString() ?? "";
      final name = (key["NAME"] ?? key["name"] ?? key["TITLE"] ?? key["title"] ?? "").toString();

      return TableColumnModel(
        id: id,
        // Sin nombre, el id sirve de encabezado antes que dejar la columna en
        // blanco.
        name: name.isNotEmpty ? name : id,
        type: (key["TYPE"] ?? key["type"] ?? "").toString()
      );
    }

    return TableColumnModel(id: "", name: key?.toString() ?? "");
  }
}
