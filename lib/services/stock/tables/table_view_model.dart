import 'package:app/services/stock/tables/table_structure_model.dart';

/// Una columna de una tabla, tal como la describe una pagina de
/// `POST /tables/records/`.
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
  const TableRowModel(this.values, {this.id = ""});

  final List<dynamic> values;

  /// Identificador del registro, que viaja fuera de los campos: es la primera
  /// columna de la pagina (`keys: ["id", <field_id>, ...]`) y no se muestra.
  ///
  /// Es lo que hace editable una fila ya guardada: sin el se la puede leer,
  /// pero no hay a que registro mandarle el cambio. Vacio en las filas de una
  /// respuesta que no lo trae.
  final String id;

  /// Valor de la celda en la columna [index], o `null` si la fila es mas corta.
  dynamic at(int index) =>
    index >= 0 && index < values.length ? values[index] : null;

  /// La misma fila con otro valor en [index].
  ///
  /// Se copia en vez de escribirse encima porque las filas se comparan por
  /// identidad para decidir que se repinta: una fila nueva es la señal de que
  /// esa celda cambio. Una fila mas corta que [index] se completa con vacios,
  /// que es el caso de una columna recien creada en la que todavia no hay nada.
  TableRowModel withValue(int index, dynamic value) {
    if (index < 0) return this;

    final next = List<dynamic>.of(values);
    while (next.length <= index) {
      next.add(null);
    }
    next[index] = value;

    return TableRowModel(next, id: id);
  }
}

/// Una pagina de datos de una tabla: los encabezados (las columnas, con su
/// FIELD_ID) y las filas de esa pagina. Es lo que se pinta con `DataTableView`
/// de `core/tables`.
///
/// La lectura es paginada (`POST /tables/records/`), asi que cada
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

  /// Devuelve esta pagina reordenada contra las columnas de la estructura.
  ///
  /// Quien manda sobre las columnas es la estructura, que se cargo antes y una
  /// sola vez; la pagina solo aporta los valores. Como cada pagina trae sus
  /// propios encabezados, sus valores se reacomodan al orden de la estructura
  /// buscando cada campo por FIELD_ID (y, si la pagina no lo trae, por nombre),
  /// asi la celda de una columna siempre muestra el dato de esa columna aunque
  /// las dos respuestas no coincidan en el orden.
  ///
  /// Un campo que la pagina no trae queda en `null`, que se ve como celda vacia.
  /// Si la pagina no trae encabezados, se respeta el orden posicional: es lo
  /// unico que se puede suponer.
  ///
  /// De esa misma pasada sale el id de cada registro ([_idPosition]), que es la
  /// columna que **no** es de ningun campo: no se muestra, pero es lo que
  /// despues permite editar la fila.
  TableViewModel alignedTo(List<TableFieldModel> fields) {
    if (fields.isEmpty) return this;

    final structure = [
      for (final field in fields)
        TableColumnModel(id: field.id, name: field.name, type: field.type)
    ];

    if (columns.isEmpty) return TableViewModel(columns: structure, rows: rows);

    final order = [for (final field in fields) _positionOf(field)];
    final identifier = _idPosition(order);

    return TableViewModel(
      columns: structure,
      rows: [
        for (final row in rows)
          TableRowModel(
            [
              for (final position in order)
                position < 0 ? null : row.at(position)
            ],
            id: identifier < 0 ? "" : row.at(identifier)?.toString() ?? ""
          )
      ]
    );
  }

  /// Cual de los encabezados de la pagina es el id del registro, o `-1` si no
  /// se lo puede distinguir.
  ///
  /// Solo se busca entre las columnas que no quedaron emparejadas con ningun
  /// campo ([used]): el id viaja al lado de los datos pero no es uno de ellos,
  /// y un campo llamado "id" es un campo como cualquier otro. De esas, se toma
  /// la que se llame como un identificador y, si ninguna lo hace, la primera de
  /// la pagina, que es donde la pone el contrato.
  int _idPosition(List<int> used) {
    int? first;

    for (final (index, column) in columns.indexed) {
      if (used.contains(index)) continue;

      final name = column.name.toUpperCase();
      if (name == "ID" || name.endsWith("_ID")) return index;

      first ??= index;
    }

    return first == 0 ? 0 : -1;
  }

  /// Posicion que ocupa [field] en los encabezados de esta pagina, o `-1` si la
  /// pagina no lo trae.
  int _positionOf(TableFieldModel field) {
    if (field.id.isNotEmpty) {
      final byId = columns.indexWhere((column) => column.id == field.id);
      if (byId >= 0) return byId;

      // El contrato manda los encabezados pelados y son los FIELD_ID
      // (`keys: ["id", <field_id>, ...]`), asi que ahi el "nombre" de la
      // columna es su id: la primera columna, la del id del registro, no
      // empareja con ningun campo y por eso no se muestra.
      final byKey = columns.indexWhere(
        (column) => column.id.isEmpty && column.name == field.id
      );
      if (byKey >= 0) return byKey;
    }

    // Sin FIELD_ID en la pagina, el nombre es lo unico que queda para
    // emparejarlos.
    return columns.indexWhere(
      (column) => column.id.isEmpty && column.name == field.name
    );
  }

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
