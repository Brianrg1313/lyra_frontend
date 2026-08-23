import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/connections/connection_detail_model.dart';
import 'package:app/services/connections/connection_lite_model.dart';
import 'package:app/services/connections/connection_request.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga del listado de conexiones (`GET /connections/`).
enum ConnectionsStatus { idle, loading, ready, empty, error }

/// Las cuentas externas que la empresa tiene conectadas: de que servicio es cada
/// una, como la llamo, si esta lista para funcionar y cuantos bots corren encima.
///
/// Una conexion es **la cuenta y sus credenciales**, nada mas: un numero de
/// WhatsApp, un perfil de Instagram, una pagina de Facebook. Lo que la cuenta
/// contesta se decide despues, en los bots que se arman sobre ella, y por eso
/// este servicio no sabe nada de roles, tablas ni herramientas.
///
/// Concentra las operaciones sobre las conexiones: el listado que consume la
/// seccion `connections`, el alta, la edicion y la baja, mas la lectura del
/// detalle de una sola, que es lo que reabre su formulario.
///
/// No confundir con `ConnectionService` (en `services/connection/`), que es el
/// socket: ese es *la* conexion con el servidor, esto son *las* conexiones de la
/// empresa con servicios de afuera.
///
/// Las escrituras dejan la cache al dia sin releer el listado, y cada una a su
/// manera, con el mismo criterio que [TablesService]: el alta la invalida
/// (`idle`) porque la conexion nueva hay que ir a buscarla —el backend le pone el
/// id y calcula si quedo lista—; la baja corrige la fila en memoria, porque lo
/// que cambio ya se sabe entero de este lado. La edicion tambien invalida: si se
/// toco la configuracion, **si quedo lista o no lo decide el backend**
/// comparando contra lo que pide ese servicio, y eso no se puede adivinar aca.
///
/// El detalle no se cachea. Es lo unico que trae la configuracion, se lee al
/// abrir una conexion y se descarta al salir: dejarlo en memoria seria guardar
/// ids de cuenta y hosts de una cuenta que ya nadie esta mirando.
///
/// La cache del listado es por empresa: las conexiones viajan atadas a la empresa
/// activa (la cabecera `business_id` que pone [useBusiness]), asi que al cambiar
/// de empresa el listado se recarga solo. Por eso [load] recibe el id de la
/// empresa y no lo deduce, igual que en las tablas.
class ConnectionsService extends ChangeNotifier {
  ConnectionsStatus _status = ConnectionsStatus.idle;
  List<ConnectionLiteModel> _connections = const [];

  /// Empresa para la que se cargo la cache actual. Si no coincide con la activa,
  /// [load] refresca aunque la cache este `ready`.
  String? _businessId;

  ConnectionsStatus get status => _status;
  List<ConnectionLiteModel> get connections => List.unmodifiable(_connections);

  /// Carga las conexiones de [businessId].
  ///
  /// Se cachea: volver a la seccion no vuelve a pegarle al backend salvo que se
  /// pida [force], que cambie la empresa activa, o que una escritura haya
  /// invalidado la cache dejando el estado en `idle`.
  ///
  /// Un cambio de empresa manda siempre: no lo frena ni una lectura en curso
  /// (que es de la empresa anterior) ni una cache `ready` (idem), y lo cargado
  /// se suelta en el acto para que nadie llegue a ver las cuentas de la otra
  /// empresa mientras llegan las de esta.
  Future<void> load(String businessId, {bool force = false}) async {
    final changed = _businessId != businessId;

    if (!changed) {
      if (_status == ConnectionsStatus.loading) return;
      if (!force && _status == ConnectionsStatus.ready) return;
    }

    if (changed) _connections = const [];

    _businessId = businessId;
    _status = ConnectionsStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/connections/", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadConnections failed: $error");
        return null;
      });

    // Mientras la lectura viajaba se cambio de empresa: lo que llego es de la
    // anterior. Se descarta entero, tambien el error, porque la lectura que vale
    // es la que disparo el cambio y ya esta en camino.
    if (_businessId != businessId) return;

    if (data == null) {
      _status = ConnectionsStatus.error;
      notifyListeners();
      return;
    }

    _connections = ConnectionLiteModel.fromResponse(data);
    _status = _connections.isEmpty
      ? ConnectionsStatus.empty
      : ConnectionsStatus.ready;

    notifyListeners();
  }

  /// Lee una conexion entera (`GET /connections/detail/:CONNECTION_ID`): su
  /// configuracion, que secretos ya tiene guardados —por nombre, nunca su
  /// valor—, que le falta para poder funcionar y que trabajos ya tienen un bot.
  /// Trae ademas la descripcion de su proveedor, asi que con esta sola lectura se
  /// dibuja el formulario.
  ///
  /// Devuelve `null` si fallo, habiendo mostrado el error: quien la llama muestra
  /// su pantalla de "no se pudo abrir" y ofrece reintentar.
  Future<ConnectionDetailModel?> detail(
    BuildContext context,
    String id
  ) async {
    if (id.isEmpty) return null;

    try {
      // Sin barra al final: el id es un segmento de la ruta (`params:
      // ["CONNECTION_ID"]`), y una barra de mas lo dejaria vacio del otro lado.
      final response = await api.get(
        path: "/connections/detail/$id",
        version: "v1"
      );

      if (response is! Map) return null;

      return ConnectionDetailModel.fromJson(response);
    } catch (error) {
      if (kDebugMode) print("loadConnection failed: $error");

      if (context.mounted) _report(context, error);

      return null;
    }
  }

  /// Alta de una conexion contra `POST /connections/`.
  ///
  /// Devuelve el id de la conexion creada. Ante un error muestra la bandera
  /// flotante y relanza, para que la pantalla apague su estado de carga.
  ///
  /// Al terminar bien invalida la cache del listado (`idle`) para que la proxima
  /// lectura traiga la cuenta nueva con el `ready` que calculo el backend.
  Future<String> create(
    BuildContext context,
    Map<String, dynamic> data
  ) async {
    try {
      final response = await api.post(
        path: "/connections/",
        version: "v1",
        data: data
      );

      final id = _readId(response);

      _status = ConnectionsStatus.idle;

      return id;
    } catch (error) {
      // El error se registra siempre, tambien cuando se muestra: el texto que
      // llega a pantalla suele estar recortado y aca queda el crudo.
      if (kDebugMode) print("createConnection failed: $error");

      if (context.mounted) _report(context, error);

      rethrow;
    }
  }

  /// Edicion de una conexion contra `PUT /connections/`.
  ///
  /// La cache se invalida en vez de corregirse en memoria, al reves que en las
  /// tablas, y por una razon concreta: una edicion puede completar (o vaciar) la
  /// configuracion, y si la cuenta quedo lista lo resuelve el backend contra lo
  /// que pide ese servicio. Reescribir la fila aca seria adivinar ese `ready`.
  ///
  /// Devuelve `true` si el cambio salio bien. Ante un error muestra la bandera
  /// flotante y devuelve `false`, con la conexion como estaba.
  Future<bool> edit(BuildContext context, Map<String, dynamic> data) async {
    try {
      await api.put(
        path: "/connections/",
        version: "v1",
        data: data
      );
    } catch (error) {
      if (kDebugMode) print("editConnection failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _status = ConnectionsStatus.idle;

    return true;
  }

  /// Cambia solo el interruptor de una conexion (`ENABLED`), sin tocar nada mas.
  ///
  /// Es el unico cambio que si corrige la fila en memoria: pausar una cuenta no
  /// cambia su configuracion, asi que su `ready` sigue siendo el mismo y no hay
  /// nada que ir a buscar. La fila se actualiza al instante y el cambio viaja
  /// detras; si falla, se vuelve a poner como estaba.
  ///
  /// Es ademas lo que hay que ofrecer en lugar de la baja cuando lo que se quiere
  /// es que la cuenta deje de contestar: pausarla no pierde ni las credenciales
  /// ni los bots que corren sobre ella.
  Future<bool> toggle(
    BuildContext context,
    ConnectionLiteModel connection
  ) async {
    if (connection.id.isEmpty) return false;

    final enabled = !connection.enabled;

    _replace(connection.id, (current) => current.copyWith(enabled: enabled));

    try {
      await api.put(
        path: "/connections/",
        version: "v1",
        data: {"ID": connection.id, "ENABLED": enabled}
      );
    } catch (error) {
      if (kDebugMode) print("toggleConnection failed: $error");

      _replace(connection.id, (current) => current.copyWith(
        enabled: connection.enabled
      ));

      if (context.mounted) _report(context, error);

      return false;
    }

    return true;
  }

  /// Baja de una conexion contra `DELETE /connections/`.
  ///
  /// Se lleva sus credenciales **y los bots que contestaban a traves de ella**,
  /// asi que quien la llama tiene que haberlo confirmado antes: el servicio no
  /// pregunta. La cuenta que ocupaba queda libre y se puede volver a conectar,
  /// pero configurandola de nuevo.
  ///
  /// La cache se corrige en el acto —se saca la fila— en vez de invalidarse: la
  /// conexion eliminada es lo unico que cambio, y asi desaparece del listado sin
  /// que este parpadee cargando de nuevo.
  Future<bool> remove(
    BuildContext context,
    ConnectionLiteModel connection
  ) async {
    if (connection.id.isEmpty) return false;

    try {
      await api.delete(
        path: "/connections/",
        version: "v1",
        data: deleteConnectionRequest(id: connection.id)
      );
    } catch (error) {
      if (kDebugMode) print("deleteConnection failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    final remaining = _connections
      .where((current) => current.id != connection.id)
      .toList();

    // Nada que sacar: la cache ya no era la que tenia esta conexion (se cambio
    // de empresa, o se recargo el listado mientras la baja viajaba).
    if (remaining.length == _connections.length) return true;

    _connections = remaining;

    // El estado sigue a lo que quedo: sin conexiones, el listado tiene que
    // mostrar su mensaje de vacio y no una lista en blanco.
    if (_status == ConnectionsStatus.ready && _connections.isEmpty) {
      _status = ConnectionsStatus.empty;
    }

    notifyListeners();

    return true;
  }

  /// Vacia la cache. La llama el cierre de sesion, junto al resto de los
  /// servicios de la sesion.
  void clear() {
    _connections = const [];
    _status = ConnectionsStatus.idle;
    _businessId = null;
    notifyListeners();
  }

  /// Reescribe una fila de la cache, si todavia esta.
  ///
  /// La conexion puede haberse ido mientras un cambio viajaba (un cambio de
  /// empresa, una recarga): entonces no hay nada que corregir y lo que se lea
  /// despues ya viene bien.
  void _replace(
    String id,
    ConnectionLiteModel Function(ConnectionLiteModel current) change
  ) {
    final index = _connections.indexWhere((current) => current.id == id);
    if (index < 0) return;

    _connections = List<ConnectionLiteModel>.from(_connections)
      ..[index] = change(_connections[index]);

    notifyListeners();
  }

  /// Muestra un error de una operacion sobre las conexiones.
  ///
  /// Nunca se cae en silencio: si el error no trae nada mostrable, igual se
  /// avisa. Un `action` es una instruccion de navegacion (por ejemplo, sesion
  /// vencida): se relanza tal cual para que la maneje quien corresponda, asi que
  /// esta llamada puede no volver.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Lee el identificador de la conexion de la respuesta del alta, que lo
  /// devuelve pelado (`"a1b2..."`) aunque se contempla envuelto por las dudas.
  String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["connection_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The connection was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The connection was not created (empty response)"};
    }

    return response.toString();
  }
}
