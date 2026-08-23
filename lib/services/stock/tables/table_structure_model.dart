import 'dart:convert';

/// Un campo (una columna) de una tabla, tal como lo describe
/// `GET /tables/structure/<table_id>`.
///
/// Trae cinco cosas que se usan en momentos distintos: el [id] (el FIELD_ID, el
/// UUID publico del campo) es la clave con la que se guardan los datos en
/// `POST /products/manage/`; el [name] es el titulo que ve el usuario en la fila
/// de campos; el [type] (el codigo del tipo: `VECTOR`, `PRICE`, `STOCK`...)
/// decide con que editor se carga la celda y como se alinea; el [width] es lo
/// que mide la columna en pantalla; y las [options] son la lista de un campo
/// `SELECT`.
class TableFieldModel {
  const TableFieldModel({
    required this.id,
    required this.name,
    this.type = "",
    this.width = 0,
    this.options = const []
  });

  /// FIELD_ID: UUID publico del campo. Vacio solo si la respuesta no lo trae,
  /// en cuyo caso la columna se ve pero no se puede guardar.
  final String id;

  /// Titulo visible de la columna.
  final String name;

  /// Codigo del tipo del campo (`VECTOR`, `PRICE`, ...), o vacio si no vino.
  final String type;

  /// Ancho de la columna en pantalla, tal como lo dejo el ultimo que la
  /// arrastro, o `0` si nunca se la redimensiono (ahi manda el ancho por defecto
  /// de la planilla).
  ///
  /// Es una propiedad **de la tabla** y no de quien la mira: la estructura la
  /// trae con los campos, asi que todos los de la empresa abren la tabla con las
  /// columnas de la misma medida.
  final double width;

  /// Las opciones entre las que elige un campo `SELECT`, en el orden en que se
  /// ofrecen. Vacia en todos los demas tipos.
  ///
  /// **Le pertenecen al campo, no a la empresa**: dos columnas de lista nunca
  /// comparten opciones, y agregarle una a esta no le agrega nada a la otra.
  /// Vienen con la estructura y no por separado porque son parte de la columna,
  /// como su tipo o su ancho: con la misma lectura que dibuja la tabla ya se
  /// puede desplegar cualquiera de sus listas.
  ///
  /// Lo que se guarda en la celda es la opcion misma (un `SELECT` se guarda como
  /// texto), asi que un valor cargado sobrevive a que su opcion se saque de esta
  /// lista: se sigue leyendo tal como se capturo.
  final List<String> options;

  /// Lee un campo. Las claves se contemplan en minusculas (como las manda la
  /// estructura) y en mayusculas (la convencion del contrato de alta), asi el
  /// parseo no se ata a una sola forma.
  factory TableFieldModel.fromJson(Map json) {
    final id = (json["id"] ?? json["ID"] ?? json["field_id"] ?? json["FIELD_ID"])
      ?.toString() ?? "";
    final name = (json["name"] ?? json["NAME"] ?? json["title"] ?? json["TITLE"] ?? "")
      .toString();

    return TableFieldModel(
      id: id,
      // Sin nombre, el id sirve de titulo antes que dejar la columna en blanco.
      name: name.isNotEmpty ? name : id,
      type: (json["type"] ?? json["TYPE"] ?? "").toString(),
      width: _width(json["width"] ?? json["WIDTH"]),
      options: _options(json["options"] ?? json["OPTIONS"])
    );
  }

  /// Las opciones de un campo de lista. Se aceptan como lista (la forma en que
  /// las manda la estructura) y como el texto JSON de esa lista, por si el
  /// backend devuelve la columna sin decodificar.
  ///
  /// Lo que no se pueda leer se descarta y el campo queda sin opciones: una
  /// lista rara deja la columna como un `SELECT` vacio —al que igual se le
  /// pueden crear opciones— en vez de romper la carga de la tabla.
  static List<String> _options(dynamic raw) {
    if (raw == null) return const [];

    if (raw is String) {
      if (raw.trim().isEmpty) return const [];

      try {
        return _options(jsonDecode(raw));
      } catch (_) {
        return const [];
      }
    }

    if (raw is! List) return const [];

    return [
      for (final option in raw)
        if (option != null && option.toString().trim().isNotEmpty)
          option.toString().trim()
    ];
  }

  /// El ancho guardado de la columna. Una columna que nunca se arrastro viene en
  /// `null`, y cualquier cosa que no se pueda leer como un ancho valido —un
  /// texto, un cero, un negativo— se trata igual: `0`, que la planilla lee como
  /// "el de siempre". Asi un dato raro deja la columna con el ancho por defecto
  /// en vez de romper la carga de la tabla.
  static double _width(dynamic raw) {
    if (raw == null) return 0;

    final width = raw is num
      ? raw.toDouble()
      : double.tryParse(raw.toString()) ?? 0;

    return width > 0 ? width : 0;
  }
}

/// Estructura de una tabla: su cabecera (nombre, descripcion, color, fecha,
/// cuantos registros tiene) y sus campos, tal como los devuelve
/// `GET /tables/structure/<table_id>`.
///
/// Es la primera de las dos fases con las que se abre una tabla. La estructura
/// se pide una sola vez —no cambia mientras se navega por los datos— y es lo que
/// permite dibujar la planilla entera (la fila de campos y las columnas) antes
/// de que llegue el primer dato. La segunda fase, los registros, se lee aparte y
/// paginada.
///
/// Los campos vienen en la forma columnar (`{"keys": [...], "values": [...]}`)
/// que ya usan `/init` y `/business/list/`: [keys] nombra las propiedades y cada
/// fila de [values] es un campo, alineado por posicion.
class TableStructureModel {
  const TableStructureModel({
    this.id = "",
    this.name = "",
    this.description = "",
    this.color = "",
    this.date,
    this.records = 0,
    this.fields = const []
  });

  /// UUID de la tabla.
  final String id;

  /// Nombre visible de la tabla. Es el titulo de la pantalla.
  final String name;

  /// Vacia cuando la tabla se creo sin descripcion (es opcional en el alta).
  final String description;

  /// Literal ARGB con el que se identifica visualmente la tabla
  /// (`0xFF2196F3`), tal como viaja al backend. Vacio si no vino.
  final String color;

  /// Fecha de creacion, o `null` si no vino o no se pudo leer.
  final DateTime? date;

  /// Cuantos registros tiene la tabla en total, no en la pagina que se este
  /// viendo.
  final int records;

  /// Las columnas de la tabla, en el orden en que se muestran.
  final List<TableFieldModel> fields;

  /// `true` mientras la estructura este sin cargar: una tabla siempre tiene id.
  bool get isEmpty => id.isEmpty;

  /// Decodifica la estructura sin atarse a un unico formato: los campos se
  /// aceptan en la forma columnar del contrato y tambien como una lista de
  /// objetos, por si el backend cambia de forma.
  factory TableStructureModel.fromResponse(dynamic data) {
    if (data is! Map) return const TableStructureModel();

    // Algunos endpoints envuelven la respuesta en una clave: se baja un nivel
    // antes de rendirse.
    if (data["id"] == null && data["ID"] == null) {
      final inner = data["data"] ?? data["table"] ?? data["structure"];
      if (inner is Map) return TableStructureModel.fromResponse(inner);
    }

    final records = data["records"] ?? data["RECORDS"] ?? data["count"];

    return TableStructureModel(
      id: (data["id"] ?? data["ID"] ?? data["table_id"])?.toString() ?? "",
      name: (data["name"] ?? data["NAME"] ?? data["title"] ?? data["TITLE"] ?? "")
        .toString(),
      description: (data["description"] ?? data["DESCRIPTION"] ?? "").toString(),
      color: (data["color"] ?? data["COLOR"] ?? "").toString(),
      date: _date(data["date"] ?? data["DATE"] ?? data["created_at"]),
      records: records is num
        ? records.toInt()
        : int.tryParse(records?.toString() ?? "") ?? 0,
      fields: _fields(data["fields"] ?? data["FIELDS"] ?? data["keys"])
    );
  }

  /// Lee los campos en cualquiera de sus dos formas: la tabla columnar del
  /// contrato o una lista de objetos.
  static List<TableFieldModel> _fields(dynamic raw) {
    if (raw is Map) {
      final keys = raw["keys"] ?? raw["KEYS"];
      final values = raw["values"] ?? raw["VALUES"];

      if (keys is List && values is List) {
        return [
          for (final row in values)
            if (row is List)
              TableFieldModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
            // Por las dudas la fila venga ya como objeto.
            else if (row is Map)
              TableFieldModel.fromJson(row)
        ];
      }

      return const [];
    }

    if (raw is List) {
      return [
        for (final field in raw)
          if (field is Map)
            TableFieldModel.fromJson(field)
          // Un campo pelado solo da el nombre: se muestra igual, aunque sin id
          // no se pueda guardar nada en el.
          else if (field != null)
            TableFieldModel(id: "", name: field.toString())
      ];
    }

    return const [];
  }

  /// La fecha llega en ISO 8601 (`2026-07-14T10:32:11.000Z`). Una fecha ilegible
  /// no rompe la carga de la tabla: se descarta y la estructura se usa igual.
  static DateTime? _date(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
