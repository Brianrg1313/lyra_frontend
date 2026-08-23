import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';

/// Cuanto ve el modelo de IA de una columna.
///
/// Son tres estados y no un interruptor porque hay un punto intermedio que se
/// usa todo el tiempo: una columna que el agente puede **usar** para filtrar
/// sin poder **decir** lo que vale. El precio de costo es el ejemplo de
/// siempre: sirve para elegir que ofrecer y no puede salir por WhatsApp.
///
/// Los codigos son los del backend (`visible` · `declared` · `hidden`) y tienen
/// que coincidir exactamente: es lo que viaja en la lectura de la tabla.
enum TableFieldVisibility {
  /// El agente lee sus valores y los puede citar.
  visible,

  /// El agente sabe que la columna existe y filtra por ella, pero nunca dice
  /// lo que vale.
  declared,

  /// El agente no sabe que la columna existe.
  hidden;

  /// Lo desconocido cae en [visible], que es como nace una columna: una
  /// visibilidad que esta version todavia no conoce se muestra como el estado
  /// mas comun en vez de dejar la columna sin estado.
  static TableFieldVisibility from(dynamic raw) =>
    switch (raw?.toString().trim().toLowerCase()) {
      "declared" => declared,
      "hidden" => hidden,
      _ => visible
    };

  /// Codigo que usa el backend. No se traduce.
  String get value => name;

  String label(BuildContext context) => switch (this) {
    visible => S.of(context).field_visibility_visible,
    declared => S.of(context).field_visibility_declared,
    hidden => S.of(context).field_visibility_hidden
  };

  /// Que significa el estado, con todas las letras. Los tres nombres se
  /// parecen demasiado entre si como para explicarse solos, y el del medio no
  /// lo adivina nadie.
  String hint(BuildContext context) => switch (this) {
    visible => S.of(context).field_visibility_visible_hint,
    declared => S.of(context).field_visibility_declared_hint,
    hidden => S.of(context).field_visibility_hidden_hint
  };

  IconData get icon => switch (this) {
    visible => CI.eye,
    declared => CI.info,
    hidden => CI.eye_hidden
  };
}

/// Una columna de la tabla, tal como la describe
/// `GET /tables/details/<table_id>`.
///
/// Es la misma columna que dibuja la planilla pero contada entera: ademas de
/// su nombre y su tipo trae para que sirve, en que lugar esta, cuanto ve de
/// ella el modelo y sus dos fechas. Nada de eso hace falta para pintar la
/// grilla, y por eso no viene con la estructura (ver `TableFieldModel`).
class TableDetailFieldModel {
  const TableDetailFieldModel({
    required this.id,
    required this.name,
    this.description = "",
    this.position = 0,
    this.type = TableFieldType.text,
    this.options = const [],
    this.visibility = TableFieldVisibility.visible,
    this.date,
    this.updated
  });

  /// FIELD_ID: UUID publico de la columna.
  final String id;

  /// Titulo visible de la columna.
  final String name;

  /// Que guarda la columna. Vacia cuando se creo sin descripcion, que es lo
  /// normal en las columnas importadas de una planilla.
  final String description;

  /// Lugar que ocupa de izquierda a derecha, empezando en cero.
  final int position;

  final TableFieldType type;

  /// Las opciones de una columna de lista, en el orden en que se ofrecen.
  /// Vacia en todos los demas tipos.
  final List<String> options;

  final TableFieldVisibility visibility;

  /// Cuando se creo la columna.
  final DateTime? date;

  /// Cuando se la renombro, se le cambio el tipo, se la redimensiono o se le
  /// movio la visibilidad por ultima vez.
  final DateTime? updated;

  /// La misma columna con otro tipo, otra visibilidad, otras opciones, o
  /// varias de las tres.
  ///
  /// Es lo que deja que un cambio hecho desde la ficha se vea apenas el backend
  /// lo acepta, sin esperar a que vuelva la lectura entera: lo que se eligio ya
  /// se sabe de este lado. `null` es "no se toco", igual que en el cuerpo que
  /// viaja ([editFieldRequest]).
  ///
  /// Las opciones se vacian pasando una lista vacia, no `null`: es la misma
  /// regla del backend, donde el vacio es un valor y la ausencia no.
  TableDetailFieldModel withEdits({
    TableFieldType? type,
    TableFieldVisibility? visibility,
    List<String>? options
  }) => TableDetailFieldModel(
    id: id,
    name: name,
    description: description,
    position: position,
    type: type ?? this.type,
    options: options ?? this.options,
    visibility: visibility ?? this.visibility,
    date: date,
    updated: updated
  );

  factory TableDetailFieldModel.fromJson(Map json) {
    final name = (json["name"] ?? json["NAME"] ?? "").toString();
    final id = (json["id"] ?? json["ID"] ?? json["field_id"])?.toString() ?? "";

    return TableDetailFieldModel(
      id: id,
      // Sin nombre, el id sirve de titulo antes que dejar la fila en blanco.
      name: name.isNotEmpty ? name : id,
      description: (json["description"] ?? json["DESCRIPTION"] ?? "").toString(),
      position: _int(json["position"] ?? json["POSITION"]) ?? 0,
      type: TableFieldType.from(json["type"] ?? json["TYPE"]),
      options: _options(json["options"] ?? json["OPTIONS"]),
      visibility: TableFieldVisibility.from(
        json["visibility"] ?? json["VISIBILITY"]
      ),
      date: _date(json["date"] ?? json["DATE"]),
      updated: _date(json["updated"] ?? json["UPDATED"])
    );
  }
}

/// Cuantas columnas tiene la tabla y de que clase son.
///
/// Las cuentas las hace el backend sobre las filas que ya tiene en la mano, no
/// esta app sobre [TableDetailModel.fields]: son la respuesta a "que tan
/// grande es esta tabla" y tienen que poder leerse sin recorrer veinte
/// columnas.
class TableColumnsSummary {
  const TableColumnsSummary({
    this.total = 0,
    this.types = const {},
    this.visibility = const {},
    this.untyped = 0
  });

  /// Cuantas columnas hay.
  final int total;

  /// Cuantas de cada tipo. Un codigo que esta version no conoce cae en
  /// [TableFieldType.text], igual que en la planilla.
  final Map<TableFieldType, int> types;

  /// Cuantas de cada estado de visibilidad.
  final Map<TableFieldVisibility, int> visibility;

  /// Cuantas siguen siendo texto pelado, que es el tipo con el que nace toda
  /// columna importada.
  ///
  /// No es un error —una tabla puede ser legitimamente toda texto— pero es la
  /// diferencia entre una tabla que contesta preguntas y una que solo las
  /// guarda, asi que la pantalla lo dice.
  final int untyped;

  factory TableColumnsSummary.fromJson(Map json) {
    // Los tipos se suman en vez de asignarse: dos codigos distintos que esta
    // version no conoce caen los dos en `text`, y el segundo no puede pisar al
    // primero.
    final types = <TableFieldType, int>{};
    final rawTypes = json["types"] ?? json["TYPES"];

    if (rawTypes is Map) {
      for (final entry in rawTypes.entries) {
        final type = TableFieldType.from(entry.key);
        types[type] = (types[type] ?? 0) + (_int(entry.value) ?? 0);
      }
    }

    final visibility = <TableFieldVisibility, int>{};
    final rawVisibility = json["visibility"] ?? json["VISIBILITY"];

    if (rawVisibility is Map) {
      for (final entry in rawVisibility.entries) {
        final state = TableFieldVisibility.from(entry.key);
        visibility[state] = (visibility[state] ?? 0) + (_int(entry.value) ?? 0);
      }
    }

    return TableColumnsSummary(
      total: _int(json["total"] ?? json["TOTAL"]) ?? 0,
      types: types,
      visibility: visibility,
      untyped: _int(json["untyped"] ?? json["UNTYPED"]) ?? 0
    );
  }

  /// Cuantas columnas hay en ese estado.
  int of(TableFieldVisibility state) => visibility[state] ?? 0;

  /// Los tipos presentes, del mas usado al menos, y a igualdad de cantidad en
  /// el orden en que se ofrecen al crear una columna. Es como se leen: primero
  /// de que es la tabla y despues los detalles.
  List<MapEntry<TableFieldType, int>> get sorted {
    final order = TableFieldType.ordered;

    return types.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        if (count != 0) return count;

        return order.indexOf(a.key).compareTo(order.indexOf(b.key));
      });
  }
}

/// Que puede hacer el modelo de IA con esta tabla.
///
/// Son cuatro respuestas que salen de los tipos de sus columnas y no de una
/// configuracion aparte: la tabla habilita al agente por lo que tiene adentro.
class TableAgentSummary {
  const TableAgentSummary({
    this.searchable = false,
    this.filterable = 0,
    this.stock = false,
    this.image = false
  });

  /// `true` si tiene una columna indexada por significado (`VECTOR`), que es
  /// lo que permite preguntarle al agente por algo descrito con palabras y no
  /// por un valor exacto.
  final bool searchable;

  /// Por cuantas columnas puede filtrar y ordenar: todas las que no esten
  /// escondidas.
  final int filterable;

  /// `true` si una columna de stock la ata al motor de inventario, que es
  /// tambien lo que habilita reservar productos.
  final bool stock;

  /// `true` si tiene una columna de imagen, o sea si el agente puede mandar
  /// fotos de estos registros.
  final bool image;

  factory TableAgentSummary.fromJson(Map json) => TableAgentSummary(
    searchable: json["searchable"] == true,
    filterable: _int(json["filterable"]) ?? 0,
    stock: json["stock"] == true,
    image: json["image"] == true
  );
}

/// Un canal que lee esta tabla.
///
/// Es el bot visto desde la tabla y no desde el listado de canales: de el
/// interesa como se llama, por que red contesta y si esta funcionando, que es
/// lo que contesta "quien esta usando estos datos".
class TableChannelReader {
  const TableChannelReader({
    required this.id,
    required this.name,
    this.description = "",
    this.provider = "",
    this.connectionName = "",
    this.scopeName = "",
    this.role = "",
    this.enabled = true,
    this.ready = false
  });

  final String id;
  final String name;
  final String description;

  /// Codigo de la red (`whatsapp`, `instagram`, ...). Con el se busca el
  /// nombre y el icono en el catalogo de canales.
  final String provider;

  /// Nombre que la empresa le puso a la cuenta por la que contesta.
  final String connectionName;

  /// Que atiende de esa cuenta (mensajes directos, comentarios), ya resuelto a
  /// texto por el backend.
  final String scopeName;

  /// Con que papel atiende el agente (`seller`, `support`, `agent`).
  final String role;

  /// Interruptor de la empresa: un canal pausado sigue conectado a la tabla
  /// pero no contesta.
  final bool enabled;

  /// `true` cuando tiene cargado todo lo que su red le pide.
  final bool ready;

  factory TableChannelReader.fromJson(Map json) => TableChannelReader(
    id: (json["id"] ?? json["ID"])?.toString() ?? "",
    name: (json["name"] ?? json["NAME"] ?? "").toString(),
    description: (json["description"] ?? json["DESCRIPTION"] ?? "").toString(),
    provider: (json["provider"] ?? json["PROVIDER"] ?? "").toString(),
    connectionName: (json["connection_name"] ?? "").toString(),
    scopeName: (json["scope_name"] ?? json["scope"] ?? "").toString(),
    role: (json["role"] ?? "").toString(),
    enabled: json["enabled"] != false && json["enabled"] != 0,
    ready: json["ready"] == true
  );

  static List<TableChannelReader> listOf(dynamic raw) => [
    if (raw is List)
      for (final row in raw)
        if (row is Map) TableChannelReader.fromJson(row)
  ];
}

/// Hasta donde llega la tabla: que bots la leen y por que.
///
/// Vienen dos listas y no una porque son dos cosas distintas y solo una es una
/// decision. [linked] son los que eligieron esta tabla como fuente; [open] son
/// los que **no configuraron ninguna**, que el runtime lee como "todas las de
/// la empresa" y por lo tanto tambien leen esta, sin que nadie lo haya pedido.
///
/// Mostrar solo la primera seria la respuesta comoda y la equivocada: una
/// empresa mirando "no esta conectada a ningun canal" mientras un bot sin
/// fuentes dicta sus precios de costo por WhatsApp es justo lo que esta
/// pantalla existe para evitar.
class TableChannelsSummary {
  const TableChannelsSummary({
    this.reached = false,
    this.linked = const [],
    this.open = const []
  });

  /// `true` si algun bot llega a esta tabla, por el camino que sea.
  final bool reached;

  /// Los que nombran esta tabla como fuente de datos.
  final List<TableChannelReader> linked;

  /// Los que no configuraron ninguna fuente y por eso leen todas.
  final List<TableChannelReader> open;

  factory TableChannelsSummary.fromJson(Map json) {
    final linked = TableChannelReader.listOf(json["linked"]);
    final open = TableChannelReader.listOf(json["open"]);

    return TableChannelsSummary(
      // Se recalcula sobre lo que de verdad se pudo leer en vez de tomar el
      // booleano del backend tal cual: decir que la tabla esta alcanzada sin
      // poder mostrar por quien seria una alarma sin explicacion.
      reached: json["reached"] == true || linked.isNotEmpty || open.isNotEmpty,
      linked: linked,
      open: open
    );
  }
}

/// Todo lo que hay que saber de una tabla menos sus filas, tal como lo
/// devuelve `GET /tables/details/<table_id>`.
///
/// Es la pantalla de ajustes de una tabla en una sola lectura, y por eso es un
/// endpoint aparte y no una estructura mas grande: contesta cosas que viven en
/// tres bases distintas —la cabecera y las columnas en MySQL, cuantos
/// registros hay en Mongo, que bots la leen en la base de la empresa— y se
/// pide una vez cada tanto. La estructura (`/tables/structure/`) sigue siendo
/// la lectura barata que dibuja la planilla en cada clic.
///
/// **Son dos fechas porque la tabla tiene dos**, y juntarlas perderia la que
/// se estuviera preguntando: [updated] es el ultimo cambio de **estructura**
/// —la tabla o cualquiera de sus columnas—, y [lastRecord] es cuando entro el
/// ultimo dato. Una lista de precios importada en marzo y recargada esta
/// manana tiene un [updated] viejo y un [lastRecord] de hoy.
///
/// [records] es `null` —y no cero— cuando la cuenta no se pudo leer: las filas
/// viven en otra base que las columnas, asi que puede fallar sola. Una tabla
/// cuyos registros no se pudieron contar no es una tabla vacia, y la
/// diferencia importa justo en la pantalla que ofrece borrarla.
class TableDetailModel {
  const TableDetailModel({
    this.id = "",
    this.name = "",
    this.description = "",
    this.color = "",
    this.date,
    this.updated,
    this.records,
    this.lastRecord,
    this.columns = const TableColumnsSummary(),
    this.agent = const TableAgentSummary(),
    this.channels = const TableChannelsSummary(),
    this.fields = const []
  });

  /// UUID de la tabla.
  final String id;

  /// Nombre visible de la tabla.
  final String name;

  /// Vacia cuando la tabla se creo sin descripcion.
  final String description;

  /// Literal ARGB con el que se identifica la tabla (`0xFF2196F3`), tal como
  /// viaja al backend. Vacio si no vino.
  final String color;

  /// Cuando se creo la tabla.
  final DateTime? date;

  /// El ultimo cambio de estructura, sea de la tabla o de una de sus columnas.
  final DateTime? updated;

  /// Cuantas filas tiene, o `null` si no se pudieron contar. Ver la nota de la
  /// clase.
  final int? records;

  /// Cuando entro la ultima fila, o `null` si la tabla esta vacia (o si la
  /// cuenta no se pudo leer).
  final DateTime? lastRecord;

  final TableColumnsSummary columns;
  final TableAgentSummary agent;
  final TableChannelsSummary channels;

  /// Las columnas, en el orden en que se muestran.
  final List<TableDetailFieldModel> fields;

  /// `true` mientras el detalle este sin cargar: una tabla siempre tiene id.
  bool get isEmpty => id.isEmpty;

  /// El mismo detalle con otro nombre, otra descripcion, o las dos cosas.
  ///
  /// Es lo que deja que un cambio hecho desde la ficha se vea en el acto: la
  /// escritura ya volvio bien y lo unico distinto es el texto que se acaba de
  /// escribir, asi que no hace falta esperar a releer las tres bases para
  /// mostrarlo. Lo demas —las cuentas, las columnas, los canales— una edicion
  /// de cabecera no lo toca.
  ///
  /// `null` es "no se cambio" y no "se vacio", igual que en el cuerpo que
  /// viaja al backend: una descripcion se borra pasandola vacia.
  TableDetailModel withText({String? name, String? description}) =>
    TableDetailModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color,
      date: date,
      updated: updated,
      records: records,
      lastRecord: lastRecord,
      columns: columns,
      agent: agent,
      channels: channels,
      fields: fields
    );

  /// El mismo detalle con una de sus columnas cambiada.
  ///
  /// Reemplaza la columna que tenga el id de [field] y deja el resto como
  /// estaba. Si no esta —el detalle se releyo y la columna ya no existe— no
  /// cambia nada: no se agrega una columna que el backend no devolvio.
  ///
  /// **Los resumenes de arriba no se recalculan.** Cuantas columnas hay de cada
  /// tipo, cuantas siguen siendo texto pelado y que puede hacer el modelo con
  /// la tabla los cuenta el backend (ver [TableColumnsSummary]), y contarlos
  /// aca seria escribir dos veces la misma regla para adelantar un segundo.
  /// Llegan con la relectura que dispara la propia escritura, mientras la barra
  /// de arriba avisa que se esta releyendo.
  TableDetailModel withField(TableDetailFieldModel field) {
    final index = fields.indexWhere((current) => current.id == field.id);
    if (index < 0) return this;

    return TableDetailModel(
      id: id,
      name: name,
      description: description,
      color: color,
      date: date,
      updated: updated,
      records: records,
      lastRecord: lastRecord,
      columns: columns,
      agent: agent,
      channels: channels,
      fields: List<TableDetailFieldModel>.from(fields)..[index] = field
    );
  }

  /// El color de la tabla ya leido, o `null` si no vino o no se puede
  /// interpretar: es un adorno y la pantalla se ve igual sin el.
  Color? get tint {
    if (color.isEmpty) return null;

    final parsed = int.tryParse(color);
    return parsed == null ? null : Color(parsed);
  }

  /// Decodifica la respuesta sin atarse a una sola forma, como el resto de las
  /// lecturas de la app: las columnas se aceptan en la tabla columnar
  /// (`{"keys": [...], "values": [...]}`) con la que viajan comprimidas y
  /// tambien como una lista de objetos.
  factory TableDetailModel.fromResponse(dynamic data) {
    if (data is! Map) return const TableDetailModel();

    // Algunos endpoints envuelven la respuesta en una clave: se baja un nivel
    // antes de rendirse.
    if (data["id"] == null && data["ID"] == null) {
      final inner = data["data"] ?? data["table"] ?? data["details"];
      if (inner is Map) return TableDetailModel.fromResponse(inner);
    }

    final records = data["records"];

    return TableDetailModel(
      id: (data["id"] ?? data["ID"])?.toString() ?? "",
      name: (data["name"] ?? data["NAME"] ?? "").toString(),
      description: (data["description"] ?? data["DESCRIPTION"] ?? "").toString(),
      color: (data["color"] ?? data["COLOR"] ?? "").toString(),
      date: _date(data["date"] ?? data["DATE"]),
      updated: _date(data["updated"] ?? data["UPDATED"]),
      // El objeto entero en `null` es "no se pudo contar"; un total ilegible
      // se lee igual, porque no decir nada es la respuesta correcta a los dos.
      records: records is Map ? _int(records["total"]) : null,
      lastRecord: records is Map ? _date(records["last"]) : null,
      columns: data["columns"] is Map
        ? TableColumnsSummary.fromJson(data["columns"] as Map)
        : const TableColumnsSummary(),
      agent: data["agent"] is Map
        ? TableAgentSummary.fromJson(data["agent"] as Map)
        : const TableAgentSummary(),
      channels: data["channels"] is Map
        ? TableChannelsSummary.fromJson(data["channels"] as Map)
        : const TableChannelsSummary(),
      fields: _fields(data["fields"] ?? data["FIELDS"])
    );
  }

  static List<TableDetailFieldModel> _fields(dynamic raw) {
    if (raw is Map) {
      final keys = raw["keys"] ?? raw["KEYS"];
      final values = raw["values"] ?? raw["VALUES"];

      if (keys is! List || values is! List) return const [];

      return [
        for (final row in values)
          if (row is List)
            TableDetailFieldModel.fromJson({
              for (int i = 0; i < keys.length && i < row.length; i++)
                keys[i].toString(): row[i]
            })
          // Por las dudas la fila venga ya como objeto.
          else if (row is Map)
            TableDetailFieldModel.fromJson(row)
      ];
    }

    if (raw is List) {
      return [
        for (final field in raw)
          if (field is Map) TableDetailFieldModel.fromJson(field)
      ];
    }

    return const [];
  }
}

/// Las opciones de una columna de lista. Se aceptan como lista (la forma en
/// que viajan) y como el texto JSON de esa lista, por si la columna llega sin
/// decodificar.
List<String> _options(dynamic raw) {
  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    try {
      return _options(jsonDecode(text));
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

/// Un entero de la respuesta, o `null` si no vino o no se puede leer como tal:
/// MySQL manda cantidades como texto mas seguido de lo que parece.
int? _int(dynamic raw) => switch (raw) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null
};

/// Las fechas llegan en ISO 8601 (`2026-07-14T10:32:11.000Z`). Una fecha
/// ilegible no rompe la pantalla: se descarta y esa fila dice que no hay.
DateTime? _date(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}
