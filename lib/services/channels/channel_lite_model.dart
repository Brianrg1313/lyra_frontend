/// Un canal tal como lo devuelve `GET /channels/set_up/`, con lo justo para
/// pintar su fila: que red es, como lo llamo la empresa, si esta encendido y si
/// esta listo para funcionar.
///
/// La configuracion no esta aca a proposito: los tokens y los ids de cuenta se
/// leen de a un canal por vez (`GET /channels/set_up/detail/:ID`), y ningun
/// listado tiene por que mover eso. Los secretos, ademas, no los devuelve
/// ninguna lectura. La unica excepcion es [tableId]: sobre que datos contesta el
/// canal es lo que se lee de su fila, junto con de que red es.
class ChannelLiteModel {
  const ChannelLiteModel({
    required this.id,
    required this.provider,
    required this.name,
    this.description = "",
    this.position = 0,
    this.enabled = true,
    this.tableId = "",
    this.ready = false
  });

  final String id;

  /// Codigo de la red (`whatsapp`, `instagram`, ...). Con el se busca el
  /// proveedor en el catalogo para saber su nombre y su icono.
  final String provider;

  /// Nombre que le puso la empresa ("Ventas", "Soporte").
  final String name;

  /// Vacia cuando el canal se creo sin descripcion.
  final String description;

  /// Lugar que ocupa en el orden que armo la empresa.
  final int position;

  /// Id de la tabla de productos de la que lee el canal, vacio cuando todavia no
  /// se eligio ninguna. Es el id y no el nombre —renombrar la tabla no puede
  /// desconectar el canal—, asi que la fila lo cruza contra [TablesService] para
  /// mostrar de que tabla se trata.
  final String tableId;

  /// Interruptor de la empresa: un canal se puede pausar sin perder su
  /// configuracion. Distinto de [ready], que es si le falta algo.
  final bool enabled;

  /// `true` cuando todos los valores obligatorios de su red estan cargados.
  ///
  /// Un canal recien registrado y todavia sin credenciales es perfectamente
  /// valido —se da de alta antes de que Meta emita los tokens— y simplemente
  /// no esta listo. La fila lo muestra como "falta configurar" y no como error.
  final bool ready;

  factory ChannelLiteModel.fromJson(Map json) => ChannelLiteModel(
    id: (json["id"] ?? json["ID"] ?? json["channel_id"])?.toString() ?? "",
    provider: (json["provider"] ?? json["PROVIDER"])?.toString() ?? "",
    name: (json["name"] ?? json["NAME"] ?? json["title"])?.toString() ?? "",
    description: (json["description"] ?? json["DESCRIPTION"])?.toString() ?? "",
    position: _number(json["position"] ?? json["POSITION"]) ?? 0,
    tableId:
      (json["data_table_id"] ?? json["DATA_TABLE_ID"])?.toString() ?? "",
    // Sin dato se asume encendido, que es como nace un canal del otro lado.
    enabled: _flag(json["enabled"] ?? json["ENABLED"]) ?? true,
    // Sin dato se asume **no** listo: decir que un canal a medio configurar
    // esta funcionando es peor que pedir que lo revisen de mas.
    ready: _flag(json["ready"] ?? json["READY"]) ?? false
  );

  /// Copia la fila con lo que se edita desde el listado.
  ChannelLiteModel copyWith({
    String? name,
    String? description,
    bool? enabled,
    bool? ready
  }) => ChannelLiteModel(
    id: id,
    provider: provider,
    name: name ?? this.name,
    description: description ?? this.description,
    position: position,
    enabled: enabled ?? this.enabled,
    tableId: tableId,
    ready: ready ?? this.ready
  );

  /// Lee un booleano que puede llegar como tal, como numero o como texto: el
  /// backend lo normaliza, pero la columna viaja por JSON y MySQL manda
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

  /// Decodifica el listado. Como el resto de los listados de la app acepta la
  /// tabla columnar (`{"keys": [...], "values": [...]}`) con la que viaja
  /// comprimido y tambien una lista de objetos.
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
