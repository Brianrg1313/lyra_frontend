import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga del listado de tablas (`GET /tables/list/`).
enum TablesStatus { idle, loading, ready, empty, error }

/// Estado y comportamiento de las tablas de productos de la empresa activa.
///
/// Concentra las dos operaciones sobre las tablas: la lectura del listado, que
/// consume la seccion `products`, y el alta de una tabla nueva, que dispara la
/// sub-pagina de creacion. Al crear invalida la cache para que la vuelta al
/// listado muestre la tabla recien creada sin recargar a mano.
///
/// Se registra en el scope mas alto de la app (`initialBuilder`) con
/// `ChangeNotifierProvider` porque su estado —la cache del listado— debe
/// sobrevivir a la navegacion entre el listado y la pantalla de creacion.
///
/// La cache es por empresa: las tablas viajan atadas a la empresa activa (la
/// cabecera `business_id` que pone [useBusiness]), asi que al cambiar de empresa
/// el listado se recarga solo. Por eso [load] recibe el id de la empresa y no lo
/// deduce: mantiene al servicio desacoplado de `BusinessService`.
class TablesService extends ChangeNotifier {
  TablesStatus _status = TablesStatus.idle;
  List<TableLiteModel> _tables = const [];

  /// Empresa para la que se cargo la cache actual. Si no coincide con la activa,
  /// [load] refresca aunque la cache este `ready`.
  String? _businessId;

  TablesStatus get status => _status;
  List<TableLiteModel> get tables => List.unmodifiable(_tables);

  /// Carga las tablas de [businessId].
  ///
  /// Se cachea: una vez cargado, las siguientes visitas a la seccion no vuelven
  /// a pegarle al backend salvo que se pida [force], que cambie la empresa
  /// activa, o que un alta invalide la cache dejando el estado en `idle`.
  Future<void> load(String businessId, {bool force = false}) async {
    if (_status == TablesStatus.loading) return;
    if (!force && _status == TablesStatus.ready && _businessId == businessId) {
      return;
    }

    _businessId = businessId;
    _status = TablesStatus.loading;
    notifyListeners();

    final data = await api
        .get(path: "/tables/list/", version: "v1")
        .catchError((error) {
      if (kDebugMode) print("loadTables failed: $error");
      return null;
    });

    if (data == null) {
      _status = TablesStatus.error;
      notifyListeners();
      return;
    }

    _tables = TableLiteModel.fromResponse(data);
    _status = _tables.isEmpty ? TablesStatus.empty : TablesStatus.ready;

    notifyListeners();
  }

  /// Alta de la estructura de una tabla contra `POST /tables/structure/`.
  ///
  /// La empresa dueña no viaja en [data]: va en la cabecera `business_id` que
  /// ponen las apis solas (ver `useBusiness` en `toolkit/api.dart`).
  ///
  /// Devuelve el identificador de la tabla creada. Ante un error muestra la
  /// bandera flotante y relanza, para que la pantalla apague su estado de carga.
  /// Al terminar bien invalida la cache del listado (`idle`) para que la proxima
  /// lectura traiga la tabla nueva.
  Future<String> create(BuildContext context, Map<String, dynamic> data) async {
    try {
      final response = await api.post(
        path: "/tables/structure/",
        version: "v1",
        data: data,
      );

      final id = _readId(response);

      // La tabla recien creada todavia no esta en la cache: se marca vencida
      // para que el listado la vuelva a pedir al abrirse.
      _status = TablesStatus.idle;

      return id;
    } catch (error) {
      // El error se registra siempre, incluso cuando se muestra al usuario: el
      // texto que llega a pantalla suele estar recortado y aca queda el crudo.
      if (kDebugMode) print("createTable failed: $error");

      if (!context.mounted) rethrow;

      // Un `action` es una instruccion de navegacion (por ejemplo, sesion
      // vencida): se relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      // Nunca se cae en silencio: si el error no trae nada mostrable, igual se
      // avisa que el alta no salio.
      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()},
      );

      rethrow;
    }
  }

  /// Vacia la cache. La llama el cierre de sesion, junto al resto de los
  /// servicios de la sesion.
  void clear() {
    _tables = const [];
    _status = TablesStatus.idle;
    _businessId = null;
    notifyListeners();
  }

  /// Lee el identificador de la tabla de la respuesta del alta.
  ///
  /// El backend puede devolver el id pelado (`5`, `"5"`) o envuelto en un objeto
  /// (`{"id": 5}`), asi que se contemplan las dos formas antes de rendirse.
  String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["table_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The table was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The table was not created (empty response)"};
    }

    return response.toString();
  }
}
