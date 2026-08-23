/// Decodifica un catalogo de `/init` sin atarse a un unico formato.
///
/// Los catalogos viajan como la tabla columnar que arma `Response.parse` en el
/// backend (`{"keys": [...], "values": [[...], ...]}`), que es la forma en la
/// que ya llegan las empresas de la sesion y el listado de tablas. Se acepta
/// igual una lista de objetos: es lo que devuelve el mismo endpoint si alguna
/// vez deja de comprimir, y leer las dos formas cuesta cuatro lineas.
///
/// Las columnas se leen **por nombre y no por posicion**, asi que el backend
/// puede reordenarlas o agregar una sin romper el parseo. Lo que no se entiende
/// devuelve la lista vacia y no una excepcion: un catalogo que no llego deja a
/// la app sin opciones que ofrecer, no rota.
List<Map<String, dynamic>> catalogRows(dynamic data) {
  if (data is List) {
    return [
      for (final row in data)
        if (row is Map) row.map((key, value) => MapEntry(key.toString(), value))
    ];
  }

  if (data is! Map) return const [];

  final keys = data["keys"];
  final rows = data["values"];

  if (keys is! List || rows is! List) return const [];

  return [
    for (final row in rows)
      if (row is List)
        {
          for (int i = 0; i < keys.length && i < row.length; i++)
            keys[i].toString(): row[i]
        }
  ];
}
