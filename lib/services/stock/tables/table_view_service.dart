import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/products/table_field_request.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga de una pagina de datos de una tabla
/// (`GET /tables/view/<table_id>/<index>`).
enum TableViewStatus { idle, loading, ready, empty, error }

/// Estado y paginacion de la vista de una tabla: los datos de una tabla
/// concreta, leidos de a paginas.
///
/// A diferencia de `TablesService` —que cachea el listado de tablas de la
/// empresa y vive en el scope de la app—, este servicio es efimero: lo posee la
/// propia pantalla de la tabla y se descarta al salir. Por eso guarda su estado
/// en memoria sin cachear entre navegaciones: cada vez que se abre una tabla se
/// arranca limpio en la primera pagina.
///
/// La paginacion es por indice (`index`), que arranca en 1 (primera pagina).
/// Como el contrato no promete metadata de "hay mas paginas", el avance se
/// resuelve sondeando: al pedir la siguiente, si vuelve vacia se entiende que no
/// hay mas y se marca el final quedandose en la pagina actual, sin dejar al
/// usuario en una vacia.
class TableViewService extends ChangeNotifier {
  TableViewStatus _status = TableViewStatus.idle;
  TableViewModel _page = const TableViewModel();

  /// Indice de la pagina cargada. Arranca en 1 (primera pagina).
  int _index = 1;

  /// Tabla que se esta viendo. Se fija al abrir y no cambia mientras la
  /// pantalla siga viva.
  String? _tableId;

  /// `true` cuando ya se sondeo la pagina siguiente y vino vacia: no hay mas
  /// datos, asi que el avance queda deshabilitado hasta cambiar de tabla.
  bool _atEnd = false;

  /// `true` mientras se esta guardando un item nuevo. Evita reentrar en [add] si
  /// se dispara dos veces; la pantalla maneja su propio estado de carga del
  /// boton.
  bool _saving = false;

  TableViewStatus get status => _status;
  TableViewModel get data => _page;

  /// Numero de pagina para mostrar. El indice ya arranca en 1, asi que es el
  /// mismo indice.
  int get page => _index;

  /// Se puede retroceder si no estamos en la primera pagina.
  bool get canGoBack => _index > 1 && _status != TableViewStatus.loading;

  /// Se puede avanzar mientras la pagina actual traiga datos y no se haya
  /// tocado el final en un sondeo previo.
  bool get canGoNext =>
    !_atEnd && _status == TableViewStatus.ready && _page.rows.isNotEmpty;

  /// Abre una tabla en su primera pagina. Reinicia el estado: este servicio no
  /// cachea entre tablas porque vive y muere con la pantalla.
  Future<void> open(String tableId) {
    _tableId = tableId;
    _atEnd = false;
    _index = 1;
    return _load(1, probe: false);
  }

  /// Reintenta la pagina actual (la usa el estado de error).
  Future<void> retry() => _load(_index, probe: false);

  /// Pagina siguiente. Sondea (`probe`) porque no sabemos de antemano si existe:
  /// si vuelve vacia, [_load] marca el final y no se mueve de la pagina actual.
  Future<void> next() {
    if (_atEnd) return Future.value();
    return _load(_index + 1, probe: true);
  }

  /// Pagina anterior. No sondea: si estamos en la pagina N es porque la N-1 ya
  /// tenia datos.
  Future<void> previous() {
    if (_index <= 1) return Future.value();
    return _load(_index - 1, probe: false);
  }

  /// Alta de un item (una fila) contra `POST /products/manage/`.
  ///
  /// [values] son los datos capturados, indexados por FIELD_ID: es lo que va en
  /// el campo `DATA` del cuerpo, junto al `TABLE_ID` de la tabla abierta (que la
  /// pantalla no tiene que pasar, lo pone el servicio). La empresa dueña viaja
  /// en la cabecera `business_id`, como en el resto de las apis.
  ///
  /// Devuelve `true` si el alta salio bien; en ese caso recarga la pagina actual
  /// para que el item nuevo aparezca. Ante un error muestra la bandera flotante
  /// y devuelve `false`, dejando el borrador intacto para reintentar.
  Future<bool> add(BuildContext context, Map<String, dynamic> values) async {
    if (_saving) return false;

    final tableId = _tableId;
    if (tableId == null) return false;

    _saving = true;
    notifyListeners();

    try {
      await api.post(
        path: "/products/manage/",
        version: "v1",
        data: {"TABLE_ID": tableId, "DATA": values}
      );

      _saving = false;
      // El item nuevo todavia no esta en la pagina: se recarga para traerlo.
      await _load(_index, probe: false);
      return true;
    } catch (error) {
      if (kDebugMode) print("addProduct failed: $error");

      _saving = false;
      notifyListeners();

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Alta de una columna (campo) contra `POST /tables/fields/`.
  ///
  /// Es una modificacion de la estructura de la tabla abierta, no de sus datos:
  /// el campo se agrega al final ([TableViewModel.columns] da la [POSITION]) y la
  /// tabla no lo tiene que pasar, lo pone el servicio junto al `TABLE_ID`. El
  /// resto (nombre, descripcion, tipo) llega del modal.
  ///
  /// Devuelve `true` si el alta salio bien; en ese caso recarga la pagina actual
  /// para que la columna nueva (y sus celdas vacias) aparezca. Ante un error
  /// muestra la bandera flotante y devuelve `false`.
  Future<bool> addField(
    BuildContext context, {
    required String name,
    required String description,
    required String type
  }) async {
    final tableId = _tableId;
    if (tableId == null) return false;

    try {
      await api.post(
        path: "/tables/fields/",
        version: "v1",
        data: createFieldRequest(
          tableId: tableId,
          name: name,
          description: description,
          type: type,
          // La nueva columna va al final: su posicion es la cantidad actual.
          position: _page.columns.length
        )
      );

      // La columna nueva todavia no esta en la pagina: se recarga para traerla.
      await _load(_index, probe: false);
      return true;
    } catch (error) {
      if (kDebugMode) print("addField failed: $error");

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Carga la pagina [index] de la tabla activa.
  ///
  /// Con [probe] la carga es tentativa: una pagina vacia no es un estado a
  /// mostrar sino la senal de que se paso el final, asi que se descarta y se
  /// deja la pagina actual en su lugar. Sin [probe] la pagina vacia si se
  /// muestra (una tabla recien creada, sin datos todavia).
  Future<void> _load(int index, {required bool probe}) async {
    if (_status == TableViewStatus.loading) return;

    final tableId = _tableId;
    if (tableId == null) return;

    _status = TableViewStatus.loading;
    notifyListeners();

    final data = await api
        .get(path: "/tables/view/$tableId/$index", version: "v1")
        .catchError((error) {
      if (kDebugMode) print("loadTableView failed: $error");
      return null;
    });

    if (data == null) {
      _status = TableViewStatus.error;
      notifyListeners();
      return;
    }

    final page = TableViewModel.fromResponse(data);

    // Sondeo que se paso del final: no hay mas datos. Se marca el tope y se
    // vuelve al estado `ready` sin tocar la pagina que ya se veia.
    if (probe && page.isEmpty) {
      _atEnd = true;
      _status = TableViewStatus.ready;
      notifyListeners();
      return;
    }

    _index = index;
    _page = page;
    _atEnd = false;
    _status = page.isEmpty ? TableViewStatus.empty : TableViewStatus.ready;

    notifyListeners();
  }
}
