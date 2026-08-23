/// Una conexion tal como la devuelve `GET /connections/`, con lo justo para
/// pintar su fila: de que servicio es la cuenta, como la llamo la empresa, si
/// esta encendida, si esta lista para funcionar y cuantos bots estan corriendo
/// sobre ella.
///
/// La configuracion no esta aca a proposito: los tokens y los ids de cuenta se
/// leen de a una conexion por vez (`GET /connections/detail/:CONNECTION_ID`), y
/// ningun listado tiene por que mover eso de un lado a otro. Los secretos,
/// ademas, no los devuelve ninguna lectura.
class ConnectionLiteModel {
  const ConnectionLiteModel({
    required this.id,
    required this.provider,
    required this.name,
    this.description = "",
    this.position = 0,
    this.enabled = true,
    this.bots = 0,
    this.ready = false
  });

  final String id;

  /// Codigo del servicio (`whatsapp`, `instagram`, ...). Con el se busca el
  /// proveedor en el catalogo para saber su nombre y su icono.
  final String provider;

  /// Nombre que le puso la empresa ("Cuenta principal", "Ventas").
  final String name;

  /// Vacia cuando la conexion se creo sin descripcion.
  final String description;

  /// Lugar que ocupa en el orden que armo la empresa.
  final int position;

  /// Interruptor de la empresa: una cuenta se puede pausar sin perder su
  /// configuracion. Distinto de [ready], que es si le falta algo.
  final bool enabled;

  /// Cuantos bots estan contestando a traves de esta cuenta.
  ///
  /// Es el numero que hace que la fila valga la pena leerse —que cuenta es, y
  /// cuanto esta corriendo encima— y ademas **lo que se pierde al
  /// desconectarla**: un bot sin cuenta no tiene por donde contestar, asi que la
  /// baja se los lleva. Por eso la confirmacion los nombra.
  final int bots;

  /// `true` cuando todos los valores obligatorios de su servicio estan
  /// cargados.
  ///
  /// Una conexion recien registrada y todavia sin credenciales es perfectamente
  /// valida —se da de alta antes de que el servicio emita los tokens— y
  /// simplemente no esta lista. La fila lo muestra como "falta configurar" y no
  /// como error.
  final bool ready;

  factory ConnectionLiteModel.fromJson(Map json) => ConnectionLiteModel(
    id: (json["id"] ?? json["ID"] ?? json["connection_id"])?.toString() ?? "",
    provider: (json["provider"] ?? json["PROVIDER"])?.toString() ?? "",
    name: (json["name"] ?? json["NAME"])?.toString() ?? "",
    description: (json["description"] ?? json["DESCRIPTION"])?.toString() ?? "",
    position: _number(json["position"] ?? json["POSITION"]) ?? 0,
    bots: _number(json["bots"] ?? json["BOTS"]) ?? 0,
    // Sin dato se asume encendida, que es como nace una conexion del otro lado.
    enabled: _flag(json["enabled"] ?? json["ENABLED"]) ?? true,
    // Sin dato se asume **no** lista: decir que una cuenta a medio configurar
    // esta funcionando es peor que pedir que la revisen de mas.
    ready: _flag(json["ready"] ?? json["READY"]) ?? false
  );

  /// Copia la fila con lo que se edita desde el listado.
  ConnectionLiteModel copyWith({
    String? name,
    String? description,
    bool? enabled,
    bool? ready
  }) => ConnectionLiteModel(
    id: id,
    provider: provider,
    name: name ?? this.name,
    description: description ?? this.description,
    position: position,
    enabled: enabled ?? this.enabled,
    bots: bots,
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
  static List<ConnectionLiteModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) ConnectionLiteModel.fromJson(row)
      ];
    }

    if (data is Map) {
      final inner = data["connections"] ?? data["results"] ?? data["data"];
      if (inner != null && inner is! Map) return fromResponse(inner);

      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              ConnectionLiteModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}
