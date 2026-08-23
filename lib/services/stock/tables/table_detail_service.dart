import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la lectura del detalle de una tabla
/// (`GET /tables/details/<table_id>`).
enum TableDetailStatus { idle, loading, ready, error }

/// El detalle de una tabla abierta en su pantalla de ajustes: su cabecera, sus
/// columnas, cuantos registros tiene y que bots la leen.
///
/// **No se cachea, y es a proposito.** Es lo contrario de [TablesService]: el
/// listado se mira todo el tiempo y casi no cambia, mientras que esto se abre
/// cada tanto y justamente para verificar el estado de la tabla —cuantas filas
/// entraron, cuando fue el ultimo cambio, quien la esta leyendo—. Una respuesta
/// guardada de la visita anterior contestaria esas tres preguntas con datos
/// viejos, que es peor que no contestarlas.
///
/// Por lo mismo lo posee la pantalla y no el scope de la app: se crea al entrar
/// y se descarta al salir, igual que [TableViewService].
///
/// Una relectura sobre un detalle ya dibujado **no vuelve a la pantalla en
/// blanco** ([isReloading]): se avisa arriba y lo que hay se queda donde esta.
/// Es lo que permite refrescar sin que la pagina salte, que es lo unico que se
/// hace desde aca.
class TableDetailService extends ChangeNotifier {
  TableDetailStatus _status = TableDetailStatus.idle;
  TableDetailModel _detail = const TableDetailModel();

  /// Tabla que se esta mirando. Vacio hasta el primer [load].
  String _tableId = "";

  /// `true` mientras una lectura sobre un detalle ya dibujado esta en camino.
  bool _reloading = false;

  TableDetailStatus get status => _status;
  TableDetailModel get detail => _detail;
  String get tableId => _tableId;
  bool get isReloading => _reloading;

  /// Lee el detalle de [tableId].
  ///
  /// Es la unica lectura de la pantalla: el endpoint junta en una sola
  /// respuesta lo que vive en tres bases distintas, asi que no hay nada mas
  /// que pedir despues.
  Future<void> load(String tableId) async {
    if (tableId.isEmpty) {
      _status = TableDetailStatus.error;
      notifyListeners();
      return;
    }

    if (_status == TableDetailStatus.loading || _reloading) return;

    // Ya hay un detalle dibujado: esto es una relectura, no una carga. Pasar
    // por `loading` desmontaria la pagina entera —con su desplazamiento— por
    // un refresco que casi siempre devuelve lo mismo.
    final reload = _status == TableDetailStatus.ready && _tableId == tableId;

    _tableId = tableId;

    if (reload) {
      _reloading = true;
    } else {
      _status = TableDetailStatus.loading;
      _detail = const TableDetailModel();
    }

    notifyListeners();

    // Sin barra al final: el id es un segmento de la ruta (`params:
    // ["TABLE_ID"]`), y una barra de mas lo dejaria vacio del otro lado.
    final data = await api
      .get(path: "/tables/details/$tableId", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadTableDetail failed: $error");
        return null;
      });

    // La bandera se baja antes de mirar si la tabla cambio: soltarla despues
    // dejaria una relectura descartada bloqueando para siempre a la siguiente,
    // porque la guarda de arriba la mira para no pisar una lectura en curso.
    _reloading = false;

    // Mientras la lectura viajaba se pidio otra tabla: lo que llego es de la
    // anterior y no tiene donde ir.
    if (_tableId != tableId) return;

    if (data == null) {
      // Una relectura que falla deja lo que ya habia: el detalle viejo sigue
      // siendo el de la tabla, y tirarlo dejaria la pantalla en error por un
      // refresco que no salio.
      if (!reload) _status = TableDetailStatus.error;

      notifyListeners();
      return;
    }

    final detail = TableDetailModel.fromResponse(data);

    // Una respuesta que no trae ni el id de la tabla no es un detalle: se
    // trata como una lectura fallida en vez de dibujar una pantalla de huecos.
    if (detail.isEmpty) {
      if (!reload) _status = TableDetailStatus.error;

      notifyListeners();
      return;
    }

    _detail = detail;
    _status = TableDetailStatus.ready;

    notifyListeners();
  }

  /// Vuelve a leer la tabla que se esta mirando.
  Future<void> refresh() => load(_tableId);

  /// Reintenta despues de un error. Es [load] otra vez: la lectura fallida no
  /// dejo nada que conservar.
  Future<void> retry() {
    if (_status == TableDetailStatus.error) _status = TableDetailStatus.idle;
    return load(_tableId);
  }

  /// Cambia el nombre y/o la descripcion de la tabla que se esta mirando,
  /// contra `PUT /tables/details/`.
  ///
  /// Es una escritura **parcial**: viaja solo lo que se toco (ver
  /// [editTableDetailsRequest]), asi que corregir la descripcion no reescribe
  /// el nombre ni desconecta ningun canal. Esa es la diferencia con
  /// `PUT /tables/structure/`, que es la caja de renombre de la planilla y por
  /// eso pide el nombre siempre.
  ///
  /// Lo escrito se pinta en el acto sobre el detalle que ya esta en pantalla y
  /// recien despues se relee. Son dos cosas distintas: el texto nuevo ya se
  /// sabe entero de este lado —lo acaba de escribir quien mira—, pero la fecha
  /// de "estructura actualizada" la pone el backend al guardar, y esa fecha se
  /// muestra en esta misma pagina. Sin la relectura quedaria contando el
  /// cambio anterior justo al lado del que se acaba de hacer.
  ///
  /// La relectura no se espera: es una lectura cara (tres bases) y quien
  /// guardo ya puede irse. Mientras viaja, la barra de arriba muestra que se
  /// esta releyendo y la ficha se queda con lo que hay.
  ///
  /// Devuelve `true` si el cambio entro. Ante un error muestra la bandera
  /// flotante y devuelve `false`, con la ficha como estaba.
  Future<bool> edit(
    BuildContext context, {
    String? name,
    String? description
  }) async {
    if (_tableId.isEmpty) return false;

    // Nada que mandar. No es un error: es que quien llama no cambio ninguno de
    // los dos textos, y el backend rechaza un cuerpo sin nada que escribir.
    if (name == null && description == null) return false;

    try {
      await api.put(
        path: "/tables/details/",
        version: "v1",
        data: editTableDetailsRequest(
          id: _tableId,
          name: name,
          description: description
        )
      );
    } catch (error) {
      if (kDebugMode) print("editTableDetail failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    // Lo guardado viaja recortado, asi que la ficha muestra lo mismo que quedo
    // del otro lado y no lo que se tipeo con espacios de mas.
    _detail = _detail.withText(
      name: name?.trim(),
      description: description?.trim()
    );

    notifyListeners();

    // Ver la nota de arriba: la fecha del cambio la escribe el backend.
    unawaited(refresh());

    return true;
  }

  /// Cambia el tipo, la visibilidad o las opciones de una columna, contra
  /// `PUT /tables/fields/`.
  ///
  /// Es la escritura de la lista de columnas de esta pantalla, donde cada
  /// columna es una fila con sus tres desplegables. Solo viaja lo que se
  /// eligio; el nombre va siempre porque el backend lo pide, asi que cambiarle
  /// el tipo a una columna manda el nombre que ya tenia y no toca ni su
  /// descripcion, ni su ancho, ni su lugar.
  ///
  /// Es el mismo endpoint que usa la planilla ([TableViewService.editField]) y
  /// no hay que sincronizar nada entre las dos: la planilla tiene su propio
  /// servicio, que muere con la pantalla y vuelve a leer la estructura al
  /// abrirse.
  ///
  /// Lo elegido se pinta en el acto sobre la columna y despues se relee, por lo
  /// mismo que en [edit]: el valor nuevo ya se sabe de este lado, pero las
  /// cuentas de arriba —cuantas columnas de cada tipo, cuantas sin tipar, que
  /// puede hacer el modelo con la tabla— las hace el backend y cambian con
  /// esto. Un cambio de tipo ademas reescribe del otro lado los valores ya
  /// cargados en esa columna, asi que la respuesta buena tampoco es el final de
  /// la historia.
  ///
  /// Devuelve `true` si el cambio entro. Ante un error muestra la bandera
  /// flotante y devuelve `false`, con la columna como estaba.
  Future<bool> editField(
    BuildContext context,
    TableDetailFieldModel field, {
    TableFieldType? type,
    TableFieldVisibility? visibility,
    List<String>? options
  }) async {
    // Sin FIELD_ID no hay columna que editar: es una columna que se leyo pero
    // que el backend no identifico.
    if (field.id.isEmpty) return false;

    if (type == null && visibility == null && options == null) return false;

    // Lo que de verdad va a quedar guardado: el cuerpo recorta las opciones y
    // descarta las vacias, y la columna tiene que mostrar eso y no lo que se
    // escribio.
    final saved = options == null
      ? null
      : [
          for (final option in options)
            if (option.trim().isNotEmpty) option.trim()
        ];

    try {
      await api.put(
        path: "/tables/fields/",
        version: "v1",
        data: editFieldRequest(
          id: field.id,
          name: field.name,
          type: type?.value,
          visibility: visibility?.value,
          options: saved
        )
      );
    } catch (error) {
      if (kDebugMode) print("editTableField failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _detail = _detail.withField(field.withEdits(
      type: type,
      visibility: visibility,
      options: saved
    ));

    notifyListeners();

    // Ver la nota de arriba: las cuentas de la ficha las hace el backend.
    unawaited(refresh());

    return true;
  }

  /// Muestra el error de una escritura como lo muestra el resto de los
  /// servicios: la bandera flotante con lo que el backend haya dicho, y el
  /// crudo por consola aunque se haya mostrado (el texto de pantalla suele ir
  /// recortado).
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }
}
