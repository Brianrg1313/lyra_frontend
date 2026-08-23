import 'package:flutter/foundation.dart';

import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'free_column.dart';
import 'sheet_order.dart';

/// La **forma** de la planilla: cuantas columnas hay, cual va en cada lugar y de
/// donde sale lo que se muestra en ella.
///
/// Son dos listas paralelas, tan largas como columnas haya, y las dos hacen
/// falta porque el orden en que se **ven** las columnas y el orden en que estan
/// los **datos** dejaron de ser el mismo desde que se pueden arrastrar:
///
/// - [keys] es con que se recuerda el ancho de cada columna (su FIELD_ID, o su
///   lugar si todavia no es un campo). Va en el orden en que se ven.
/// - [slots] dice, para cada columna, en que posicion de la fila esta su valor.
///   Los registros llegan alineados a los campos **tal como los da la
///   estructura** y ahi se quedan: mover una columna de lugar no toca ni un dato
///   leido, solo cambia por donde se lo busca.
///
/// Es una sola cosa y no dos porque es lo que escucha la planilla para saber si
/// tiene que rehacer la grilla: mientras sea la misma instancia, las columnas
/// son las mismas, estan en el mismo lugar y leen del mismo lado.
class SheetShape {
  const SheetShape(this.keys, this.slots);

  static const SheetShape empty = SheetShape([], []);

  /// Clave de ancho de cada columna, en el orden en que se ven.
  final List<String> keys;

  /// Posicion dentro de la fila de la que sale el valor de cada columna.
  final List<int> slots;

  int get length => keys.length;
}

/// Una columna de la planilla: o un campo de la tabla ([field]), o una de las
/// columnas libres del final ([free]), que todavia no existe en el backend.
///
/// Las dos se pintan igual —una columna es una columna— y lo unico que cambia es
/// que la libre no tiene donde guardar datos hasta que se le pone un titulo y se
/// crea.
class SheetColumn {
  const SheetColumn._(this.field, this.free);

  const SheetColumn.field(TableFieldModel field) : this._(field, null);
  const SheetColumn.free(FreeColumn free) : this._(null, free);

  final TableFieldModel? field;
  final FreeColumn? free;

  bool get isField => field != null;

  String get name => field?.name ?? free!.name;
  String get id => field?.id ?? "";

  /// Codigo del tipo del campo, o vacio (que se lee como texto) si la columna
  /// todavia no es un campo.
  String get type => field?.type ?? "";

  /// Las opciones de un campo de lista. Vacia en todos los demas tipos y en una
  /// columna libre, que todavia no es un campo al que pertenezcan.
  List<String> get options => field?.options ?? const [];

  /// `true` mientras se esta mandando el alta de esta columna.
  bool get creating => free?.creating ?? false;
}

/// Las columnas de la planilla y el estado de los cambios que estan viajando.
///
/// Junta las dos mitades de una misma lista: los campos que trajo la estructura
/// ([TableViewService.fields]) y las columnas libres del final, que todavia no
/// existen en el backend.
///
/// **No notifica cada vez que el servicio avisa algo**: el servicio notifica
/// tambien por cada tramo de registros que entra, y repintar la fila de campos
/// por eso seria trabajo al pedo. Como la estructura arma una lista nueva de
/// campos cada vez que se relee, alcanza con comparar identidades.
///
/// Y cuando si notifica, no todos los que escuchan tienen que rehacerse. Quien
/// mira la **forma** de la planilla (cuantas columnas y cual va en cada lugar)
/// escucha [shape], que conserva su instancia mientras esa forma no cambie;
/// quien mira el **contenido** de una columna (su titulo, su tipo, si tiene un
/// cambio en camino) lo pregunta por indice desde su propia celda. Asi un
/// renombre repinta una celda y no la grilla, y un cambio de tipo repinta esa
/// columna.
///
/// ---
///
/// **El orden lo pone el usuario, no la estructura.** Las columnas se arrastran
/// de lugar como en una planilla, y ese orden se guarda aca como una lista de
/// FIELD_ID ([_order]) que se aplica sobre los campos que trae la estructura.
/// Se guarda asi, y no reacomodando los campos ni los datos, por tres motivos
/// que son el mismo:
///
/// - **Los registros no se tocan.** Una fila leida es una lista de valores
///   alineada a los campos de la estructura; mover una columna solo cambia el
///   [SheetShape.slots] con el que su celda busca el valor, asi que arrastrar
///   una columna en una tabla de cientos de miles de registros cuesta lo mismo
///   que en una de diez.
/// - **No hay que releer nada.** El orden nuevo se ve al soltar; lo que viaja al
///   backend es solo la posicion de cada campo, y no vuelve a pedir la tabla.
/// - **El orden sobrevive.** Como son ids y no posiciones, releer la estructura
///   entera —crear una columna, renombrarla, guardar una fila— no lo pierde.
class SheetColumns extends ChangeNotifier {
  SheetColumns(this._service, {this.freeColumns = 2}) {
    _fields = _service.fields;
    FreeColumn.normalize(_free, free: freeColumns);
    _rebuild();

    _service.addListener(_onService);
  }

  final TableViewService _service;

  /// Columnas libres que siempre sobran a la derecha, por el mismo motivo que
  /// las filas en blanco: la planilla no se termina en el ultimo campo.
  final int freeColumns;

  /// Columnas libres del final: las que todavia no son un campo de la tabla.
  /// Siempre hay [freeColumns] en blanco al final, y entre medio las que tienen
  /// titulo pero todavia se estan creando.
  final List<FreeColumn> _free = [];

  /// Titulos nuevos que todavia estan viajando, por FIELD_ID. La celda muestra
  /// el nuevo (apagado, como el de una columna que se esta creando) en vez de
  /// volver por un momento al viejo mientras el backend responde.
  final Map<String, String> _renaming = {};

  /// Campos cuya baja esta en camino, por FIELD_ID. Su celda se ve apagada y no
  /// se puede escribir hasta que la columna desaparezca.
  final Set<String> _deleting = {};

  /// Los campos con los que se armo [_list], **como los da la estructura**. Se
  /// guarda para saber, cuando el servicio notifica, si lo que cambio fueron las
  /// columnas o solo los datos, y es el orden contra el que estan alineados los
  /// registros leidos.
  List<TableFieldModel> _fields = const [];

  /// Los mismos campos, en el orden en que el usuario los dejo.
  List<TableFieldModel> _ordered = const [];

  /// El orden que eligio el usuario, por FIELD_ID. Vacio mientras no haya
  /// arrastrado ninguna columna, que es el caso de siempre: ahi manda la
  /// estructura y no hay nada que reordenar.
  List<String> _order = const [];

  List<SheetColumn> _list = const [];

  SheetShape _shape = SheetShape.empty;

  /// Las columnas de la planilla, en orden.
  List<SheetColumn> get list => _list;

  int get length => _list.length;

  /// Cuantas de las columnas son campos de la tabla. Detras de esa posicion
  /// empiezan las libres.
  int get fieldCount => _fields.length;

  /// Los campos de la tabla en el orden en que se ven. Es lo que se manda al
  /// guardar el orden nuevo: la posicion de cada campo es su lugar en esta
  /// lista.
  List<TableFieldModel> get ordered => _ordered;

  SheetColumn? at(int index) =>
    index >= 0 && index < _list.length ? _list[index] : null;

  /// El campo que ocupa esa posicion, o `null` si ahi todavia hay una columna
  /// libre.
  TableFieldModel? fieldAt(int index) =>
    index >= 0 && index < _ordered.length ? _ordered[index] : null;

  /// La columna libre que ocupa esa posicion de la planilla, o `null` si ahi hay
  /// un campo.
  FreeColumn? freeAt(int index) {
    final local = index - _fields.length;
    return local >= 0 && local < _free.length ? _free[local] : null;
  }

  /// El titulo que le toca a la columna: el que se acaba de escribir si el
  /// renombre todavia esta viajando y, si no, el que trae la estructura.
  String nameOf(int index) {
    final column = at(index);
    if (column == null) return "";

    return column.id.isEmpty
      ? column.name
      : _renaming[column.id] ?? column.name;
  }

  /// `true` mientras la columna tenga un cambio en camino: se esta creando,
  /// renombrando o eliminando. Su celda se ve apagada y no se escribe hasta que
  /// el cambio vuelva.
  bool busyAt(int index) {
    final column = at(index);
    if (column == null) return false;

    return column.creating ||
      (column.id.isNotEmpty &&
        (_renaming.containsKey(column.id) || _deleting.contains(column.id)));
  }

  /// Si se puede escribir el titulo de esa columna: las libres esperan uno y los
  /// campos ya creados se renombran (o se eliminan, vaciandolas) desde ahi
  /// mismo. Las unicas que no son las que tienen un cambio en camino y las de un
  /// campo sin FIELD_ID, que el backend no sabria cual es.
  bool canEditAt(int index) {
    final column = at(index);
    if (column == null) return false;

    return !busyAt(index) && (!column.isField || column.id.isNotEmpty);
  }

  /// Clave con la que se recuerda el ancho de una columna: el FIELD_ID si vino
  /// y, si no, la posicion.
  String keyOf(int index) {
    final column = at(index);
    final id = column?.id ?? "";

    return id.isNotEmpty ? id : "col_$index";
  }

  /// La forma de la planilla: las claves de ancho y de donde sale el valor de
  /// cada columna.
  ///
  /// Mientras sea la misma instancia, la grilla tiene las mismas columnas en el
  /// mismo lugar —aunque alguna haya cambiado de nombre, de tipo o este
  /// ocupada— y por eso es esto, y no [list], lo que escucha la planilla:
  /// renombrar una columna no puede costar la grilla entera. Lo que cambia
  /// adentro de cada celda lo escucha cada celda.
  SheetShape get shape => _shape;

  /// Las claves de ancho de todas las columnas, en orden. Es con lo que
  /// `SheetWidths` recuerda cuanto mide cada una.
  ///
  /// Son los FIELD_ID, no las posiciones, y por eso arrastrar una columna se
  /// lleva su ancho con ella sin que haya que mover nada.
  List<String> get keys => _shape.keys;

  /// De que posicion de la fila sale el valor de la columna [index].
  ///
  /// Los registros llegan alineados a los campos tal como los da la estructura,
  /// asi que esto es el indice del campo ahi —que no es donde se lo ve si se lo
  /// arrastro de lugar—. Las columnas libres del final tambien tienen el suyo,
  /// detras de todos los campos: no hay donde guardar todavia, pero lo que se
  /// escriba en ellas necesita un lugar propio en el borrador de la fila.
  int slotAt(int index) =>
    index >= 0 && index < _shape.slots.length ? _shape.slots[index] : index;

  /// Codigo del tipo de la columna, o vacio (que se lee como texto) si todavia
  /// no es un campo de la tabla.
  String typeOf(int index) => at(index)?.type ?? "";

  /// Las opciones entre las que elige esa columna, si es un campo de lista.
  ///
  /// Vacia en cualquier otro tipo: una lista sin opciones se despliega igual,
  /// con el boton de crear la primera.
  List<String> optionsOf(int index) => at(index)?.options ?? const [];

  /// Si la columna ya es un campo de la tabla. Una libre se ve igual pero no
  /// tiene donde guardar, asi que sus celdas no se escriben.
  bool isFieldAt(int index) => at(index)?.isField ?? false;

  /// Escribe el titulo de una columna libre mientras se tipea.
  ///
  /// Devuelve `true` si con eso cambio la cantidad de columnas: llenar la ultima
  /// libre agrega otra detras y vaciarla se lleva la que sobra, y eso si hay que
  /// repintarlo. Cambiar el texto sin mas no notifica: esa celda tiene el editor
  /// abierto y ya se ve lo que se escribe.
  bool writeFree(int index, String name) {
    final free = freeAt(index);
    if (free == null) return false;

    final before = _free.length;
    free.name = name.trim();
    FreeColumn.normalize(_free, free: freeColumns);

    if (_free.length == before) return false;

    _rebuild();
    notifyListeners();
    return true;
  }

  /// Marca que la columna libre esta viajando (se esta creando el campo).
  void startCreate(FreeColumn free) {
    free.creating = true;
    notifyListeners();
  }

  /// La columna libre ya es un campo de la tabla: se la saca del final. Si el
  /// alta fallo ([created] en `false`) sigue siendo libre y con su titulo
  /// puesto, para reintentar saliendo de la celda otra vez.
  void endCreate(FreeColumn free, {required bool created}) {
    free.creating = false;

    if (created) {
      _free.remove(free);
      FreeColumn.normalize(_free, free: freeColumns);
      _rebuild();
    }

    notifyListeners();
  }

  void startRename(String id, String name) {
    _renaming[id] = name;
    notifyListeners();
  }

  void endRename(String id) {
    if (_renaming.remove(id) == null) return;
    notifyListeners();
  }

  void startDelete(String id) {
    _deleting.add(id);
    notifyListeners();
  }

  void endDelete(String id) {
    if (!_deleting.remove(id)) return;
    notifyListeners();
  }

  /// Lleva la columna [from] hasta el borde [to] (ver [movedOrder]).
  ///
  /// Devuelve el orden que habia antes, o `null` si no se movio nada. Eso ultimo
  /// es lo que necesita el controlador para dos cosas: saber si hay algo que
  /// mandar al backend, y poder devolver la planilla a como estaba si el cambio
  /// no sale.
  ///
  /// No se mueven las columnas libres del final —no son campos de la tabla, no
  /// hay nada que reordenar en ellas— ni las de una tabla que tenga algun campo
  /// sin FIELD_ID: el orden se guarda por id, y sin el no habria como escribirlo
  /// ni como volver a aplicarlo cuando la estructura se relea.
  List<String>? reorder(int from, int to) {
    if (from < 0 || from >= _ordered.length) return null;
    if (to < 0 || to > _ordered.length) return null;

    for (final field in _ordered) {
      if (field.id.isEmpty) return null;
    }

    final before = _order.isNotEmpty
      ? _order
      : [for (final field in _ordered) field.id];

    final after = movedOrder(before, from: from, to: to);
    if (identical(after, before)) return null;

    _order = after;
    _rebuild();
    notifyListeners();

    return before;
  }

  /// Vuelve al orden [order], que es el que habia antes de un arrastre que el
  /// backend no acepto.
  void restoreOrder(List<String> order) {
    if (listEquals(_order, order)) return;

    _order = order;
    _rebuild();
    notifyListeners();
  }

  /// El servicio notifica por todo: la estructura, cada tramo de registros, cada
  /// alta. Aca solo importa que hayan cambiado los campos, y la estructura arma
  /// una lista nueva cada vez que se relee, asi que la identidad alcanza.
  void _onService() {
    if (identical(_service.fields, _fields)) return;

    _fields = _service.fields;
    _rebuild();
    notifyListeners();
  }

  void _rebuild() {
    _ordered = fieldsInOrder(_fields, _order);

    _list = [
      for (final field in _ordered) SheetColumn.field(field),
      for (final free in _free) SheetColumn.free(free)
    ];

    final keys = [
      for (int index = 0; index < _list.length; index++) keyOf(index)
    ];

    final slots = slotsOf(_fields, _ordered, free: _free.length);

    // Se conserva la instancia anterior si la forma es la misma: es la identidad
    // con la que la planilla decide si tiene que rehacer la grilla, y una
    // estructura releida trae objetos nuevos aunque no haya cambiado nada de la
    // forma de la tabla.
    if (listEquals(_shape.keys, keys) && listEquals(_shape.slots, slots)) {
      return;
    }

    _shape = SheetShape(keys, slots);
  }

  @override
  void dispose() {
    _service.removeListener(_onService);
    super.dispose();
  }
}
