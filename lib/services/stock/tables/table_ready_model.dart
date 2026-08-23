/// El aviso `table/ready`: el backend termino de preparar una tabla importada.
///
/// Existe porque **la importacion de la estructura contesta antes de estar
/// terminada**. `POST /tables/import/structure/<formato>/` devuelve el id de la
/// tabla apenas existen sus columnas —todas `text` y todas visibles— y deja
/// para despues la mitad lenta: leer que hay en cada columna y preguntarle a un
/// modelo que significa, que tarda cerca de medio minuto, mas la columna de
/// imagen que toda tabla termina teniendo. Cuando eso cae, el backend lo emite
/// a la sala de la empresa y **ese es el momento de releer la tabla**.
///
/// Llega siempre: salga bien o mal, y tambien cuando la importacion pidio no
/// normalizar (`NORMALIZE=0`, que deja `ok: true, normalized: false`). Por eso
/// se lo puede esperar sin condiciones en vez de adivinar si va a venir.
///
/// Lo escuchan los dos lados que muestran una tabla, cada uno por su cuenta y
/// para lo suyo: [TablesService], que es quien esta importando y no le sube las
/// filas al archivo hasta que sus columnas tengan tipo, y [TableViewService],
/// que si la tabla esta abierta la vuelve a leer donde esta.
class TableReadyModel {
  /// Nombre del evento en el socket. Es un contrato escrito a mano de los dos
  /// lados —aca y en `Normalizer.prepare`—, asi que vive en una sola constante:
  /// un evento mal escrito no falla, simplemente no llega nunca.
  static const String event = "table/ready";

  /// La tabla que quedo lista. Vacio cuando el aviso no se pudo leer, que es la
  /// unica forma de descartarlo.
  final String id;

  /// Si la preparacion termino sin fallar. Que sea `false` no deshace nada: la
  /// tabla existe igual, con sus columnas como quedaron.
  final bool ok;

  /// Si las columnas llegaron a tiparse. Es `false` cuando la importacion pidio
  /// no normalizar, y eso tambien es un final bueno.
  final bool normalized;

  /// Cuantas columnas cambiaron de tipo.
  ///
  /// Es lo que decide si lo que ya se leyo de la tabla sirve: al retipar una
  /// columna el backend reescribe **los valores guardados** para que dejen de
  /// ser texto (`Products.recast`), asi que los registros que estuvieran en
  /// memoria quedaron viejos aunque las columnas sean las mismas.
  final int retyped;

  /// Cuantas columnas quedaron con su visibilidad sembrada (que tanto de ellas
  /// ve el agente). No cambia nada de lo que se muestra en la planilla.
  final int narrowed;

  /// La columna de imagen de la tabla, creada o promovida a la primera
  /// posicion. Vacia si no vino: nunca es motivo para descartar el aviso.
  final String image;

  /// Que fallo, cuando [ok] es `false`. Vacio si salio bien.
  final String reason;

  const TableReadyModel({
    this.id = "",
    this.ok = false,
    this.normalized = false,
    this.retyped = 0,
    this.narrowed = 0,
    this.image = "",
    this.reason = ""
  });

  /// Lee el aviso tal como llega del socket.
  ///
  /// Nada de esto se valida contra lo que se esperaba: un aviso que no se pueda
  /// leer sale con [id] vacio y quien lo reciba lo tira. Es lo unico razonable
  /// —no hay a quien devolverle un error— y ademas lo unico seguro: la peor
  /// consecuencia es que la tabla se relea a mano.
  factory TableReadyModel.fromEvent(dynamic data) {
    if (data is! Map) return const TableReadyModel();

    return TableReadyModel(
      id: (data["id"] ?? data["ID"] ?? data["table_id"])?.toString() ?? "",
      ok: _flag(data["ok"]),
      normalized: _flag(data["normalized"]),
      retyped: _count(data["retyped"]),
      narrowed: _count(data["narrowed"]),
      image: data["image"]?.toString() ?? "",
      reason: data["reason"]?.toString() ?? ""
    );
  }

  /// Si el aviso trae una tabla que se pueda releer.
  bool get isEmpty => id.isEmpty;

  /// Si los valores guardados se reescribieron. Lo unico que obliga a tirar los
  /// registros leidos: las columnas pueden ser las mismas y sus valores no.
  bool get changedValues => retyped > 0;

  static bool _flag(dynamic value) => switch (value) {
    final bool flag => flag,
    final num number => number != 0,
    final String text => text == "true" || text == "1",
    _ => false
  };

  static int _count(dynamic value) => switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };
}
