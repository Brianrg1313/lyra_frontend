import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_request.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga del listado de canales (`GET /channels/set_up/`).
enum ChannelsStatus { idle, loading, ready, empty, error }

/// Los canales de comunicacion de la empresa activa: a que redes esta conectada
/// su cuenta, como se llama cada conexion y en que orden se muestran.
///
/// Concentra las operaciones sobre los canales: el listado que consume la
/// seccion `channels`, el alta, la edicion y la baja, mas la lectura del
/// detalle de uno solo, que es lo que reabre su formulario.
///
/// Las escrituras dejan la cache al dia sin releer el listado, y cada una a su
/// manera, con el mismo criterio que [TablesService]: el alta la invalida
/// (`idle`) porque el canal nuevo hay que ir a buscarlo —el backend le pone el
/// id y calcula si quedo listo—; la baja corrige la fila en memoria, porque lo
/// que cambio ya se sabe entero de este lado. La edicion tambien invalida: si
/// se toco la configuracion, **si quedo listo o no lo decide el backend**
/// comparando contra lo que pide esa red, y eso no se puede adivinar aca.
///
/// El detalle no se cachea. Es lo unico que trae la configuracion, se lee al
/// abrir un canal y se descarta al salir: dejarlo en memoria seria guardar ids
/// de cuenta y hosts de un canal que ya nadie esta mirando.
///
/// La cache del listado es por empresa: los canales viajan atados a la empresa
/// activa (la cabecera `business_id` que pone [useBusiness]), asi que al
/// cambiar de empresa el listado se recarga solo. Por eso [load] recibe el id
/// de la empresa y no lo deduce, igual que en las tablas.
class ChannelsService extends ChangeNotifier {
  ChannelsStatus _status = ChannelsStatus.idle;
  List<ChannelLiteModel> _channels = const [];

  /// Empresa para la que se cargo la cache actual. Si no coincide con la
  /// activa, [load] refresca aunque la cache este `ready`.
  String? _businessId;

  ChannelsStatus get status => _status;
  List<ChannelLiteModel> get channels => List.unmodifiable(_channels);

  /// Carga los canales de [businessId].
  ///
  /// Se cachea: volver a la seccion no vuelve a pegarle al backend salvo que se
  /// pida [force], que cambie la empresa activa, o que una escritura haya
  /// invalidado la cache dejando el estado en `idle`.
  ///
  /// Un cambio de empresa manda siempre: no lo frena ni una lectura en curso
  /// (que es de la empresa anterior) ni una cache `ready` (idem), y lo cargado
  /// se suelta en el acto para que nadie llegue a ver los canales de la otra
  /// empresa mientras llegan los de esta.
  Future<void> load(String businessId, {bool force = false}) async {
    final changed = _businessId != businessId;

    if (!changed) {
      if (_status == ChannelsStatus.loading) return;
      if (!force && _status == ChannelsStatus.ready) return;
    }

    if (changed) _channels = const [];

    _businessId = businessId;
    _status = ChannelsStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/channels/set_up/", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadChannels failed: $error");
        return null;
      });

    // Mientras la lectura viajaba se cambio de empresa: lo que llego es de la
    // anterior. Se descarta entero, tambien el error, porque la lectura que
    // vale es la que disparo el cambio y ya esta en camino.
    if (_businessId != businessId) return;

    if (data == null) {
      _status = ChannelsStatus.error;
      notifyListeners();
      return;
    }

    _channels = ChannelLiteModel.fromResponse(data);
    _status = _channels.isEmpty ? ChannelsStatus.empty : ChannelsStatus.ready;

    notifyListeners();
  }

  /// Lee un canal entero (`GET /channels/set_up/detail/:ID`): su configuracion,
  /// que secretos ya tiene guardados —por nombre, nunca su valor— y que le
  /// falta para poder funcionar. Trae ademas la descripcion de su proveedor,
  /// asi que con esta sola lectura se dibuja el formulario.
  ///
  /// Devuelve `null` si fallo, habiendo mostrado el error: quien la llama
  /// muestra su pantalla de "no se pudo abrir" y ofrece reintentar.
  Future<ChannelDetailModel?> detail(BuildContext context, String id) async {
    if (id.isEmpty) return null;

    try {
      // Sin barra al final: el id es un segmento de la ruta (`params:
      // ["CHANNEL_ID"]`), y una barra de mas lo dejaria vacio del otro lado.
      final response = await api.get(
        path: "/channels/set_up/detail/$id",
        version: "v1"
      );

      if (response is! Map) return null;

      return ChannelDetailModel.fromJson(response);
    } catch (error) {
      if (kDebugMode) print("loadChannel failed: $error");

      if (context.mounted) _report(context, error);

      return null;
    }
  }

  /// Alta de un canal contra `POST /channels/set_up/`.
  ///
  /// Devuelve el id del canal creado. Ante un error muestra la bandera flotante
  /// y relanza, para que la pantalla apague su estado de carga.
  ///
  /// Al terminar bien invalida la cache del listado (`idle`) para que la
  /// proxima lectura traiga el canal nuevo con el `ready` que calculo el
  /// backend.
  Future<String> create(
    BuildContext context,
    Map<String, dynamic> data
  ) async {
    try {
      final response = await api.post(
        path: "/channels/set_up/",
        version: "v1",
        data: data
      );

      final id = _readId(response);

      _status = ChannelsStatus.idle;

      return id;
    } catch (error) {
      // El error se registra siempre, tambien cuando se muestra: el texto que
      // llega a pantalla suele estar recortado y aca queda el crudo.
      if (kDebugMode) print("createChannel failed: $error");

      if (context.mounted) _report(context, error);

      rethrow;
    }
  }

  /// Edicion de un canal contra `PUT /channels/set_up/`.
  ///
  /// La cache se invalida en vez de corregirse en memoria, al reves que en las
  /// tablas, y por una razon concreta: una edicion puede completar (o vaciar)
  /// la configuracion, y si el canal quedo listo lo resuelve el backend contra
  /// lo que pide esa red. Reescribir la fila aca seria adivinar ese `ready`.
  ///
  /// Devuelve `true` si el cambio salio bien. Ante un error muestra la bandera
  /// flotante y devuelve `false`, con el canal como estaba.
  Future<bool> edit(BuildContext context, Map<String, dynamic> data) async {
    try {
      await api.put(
        path: "/channels/set_up/",
        version: "v1",
        data: data
      );
    } catch (error) {
      if (kDebugMode) print("editChannel failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _status = ChannelsStatus.idle;

    return true;
  }

  /// Cambia solo el interruptor de un canal (`ENABLED`), sin tocar nada mas.
  ///
  /// Es el unico cambio que si corrige la fila en memoria: pausar un canal no
  /// cambia su configuracion, asi que su `ready` sigue siendo el mismo y no hay
  /// nada que ir a buscar. La fila se actualiza al instante y el cambio viaja
  /// detras; si falla, se vuelve a poner como estaba.
  Future<bool> toggle(BuildContext context, ChannelLiteModel channel) async {
    if (channel.id.isEmpty) return false;

    final enabled = !channel.enabled;

    _replace(channel.id, (current) => current.copyWith(enabled: enabled));

    try {
      await api.put(
        path: "/channels/set_up/",
        version: "v1",
        data: {"ID": channel.id, "ENABLED": enabled}
      );
    } catch (error) {
      if (kDebugMode) print("toggleChannel failed: $error");

      _replace(channel.id, (current) => current.copyWith(
        enabled: channel.enabled
      ));

      if (context.mounted) _report(context, error);

      return false;
    }

    return true;
  }

  /// Baja de un canal contra `DELETE /channels/set_up/`.
  ///
  /// Se lleva sus credenciales, asi que quien la llama tiene que haberlo
  /// confirmado antes: el servicio no pregunta. La cuenta que ocupaba queda
  /// libre y se puede volver a conectar, pero configurandola de nuevo.
  ///
  /// La cache se corrige en el acto —se saca la fila— en vez de invalidarse:
  /// el canal eliminado es lo unico que cambio, y asi desaparece del listado
  /// sin que este parpadee cargando de nuevo.
  Future<bool> remove(BuildContext context, ChannelLiteModel channel) async {
    if (channel.id.isEmpty) return false;

    try {
      await api.delete(
        path: "/channels/set_up/",
        version: "v1",
        data: deleteChannelRequest(id: channel.id)
      );
    } catch (error) {
      if (kDebugMode) print("deleteChannel failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    final remaining = _channels
      .where((current) => current.id != channel.id)
      .toList();

    // Nada que sacar: la cache ya no era la que tenia este canal (se cambio de
    // empresa, o se recargo el listado mientras la baja viajaba).
    if (remaining.length == _channels.length) return true;

    _channels = remaining;

    // El estado sigue a lo que quedo: sin canales, el listado tiene que mostrar
    // su mensaje de vacio y no una lista en blanco.
    if (_status == ChannelsStatus.ready && _channels.isEmpty) {
      _status = ChannelsStatus.empty;
    }

    notifyListeners();

    return true;
  }

  /// Vacia la cache. La llama el cierre de sesion, junto al resto de los
  /// servicios de la sesion.
  void clear() {
    _channels = const [];
    _status = ChannelsStatus.idle;
    _businessId = null;
    notifyListeners();
  }

  /// Reescribe una fila de la cache, si todavia esta.
  ///
  /// El canal puede haberse ido mientras un cambio viajaba (un cambio de
  /// empresa, una recarga): entonces no hay nada que corregir y lo que se lea
  /// despues ya viene bien.
  void _replace(
    String id,
    ChannelLiteModel Function(ChannelLiteModel current) change
  ) {
    final index = _channels.indexWhere((current) => current.id == id);
    if (index < 0) return;

    _channels = List<ChannelLiteModel>.from(_channels)
      ..[index] = change(_channels[index]);

    notifyListeners();
  }

  /// Muestra un error de una operacion sobre los canales.
  ///
  /// Nunca se cae en silencio: si el error no trae nada mostrable, igual se
  /// avisa. Un `action` es una instruccion de navegacion (por ejemplo, sesion
  /// vencida): se relanza tal cual para que la maneje quien corresponda, asi
  /// que esta llamada puede no volver.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Lee el identificador del canal de la respuesta del alta, que lo devuelve
  /// pelado (`"a1b2..."`) aunque se contempla envuelto por las dudas.
  String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["channel_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The channel was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The channel was not created (empty response)"};
    }

    return response.toString();
  }
}
