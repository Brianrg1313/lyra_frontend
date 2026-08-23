import 'package:flutter/foundation.dart';
import 'package:core/socket.dart' show SocketStatus, SocketHandler;

import 'package:app/toolkit/sockets.dart';

// El estado y la firma de los handlers son parte de la api de este servicio:
// quien lo consuma no deberia tener que importar el paquete para nombrarlos.
export 'package:core/socket.dart' show SocketStatus, SocketHandler;

/// Estado general de la conexion en tiempo real.
///
/// Es el unico dueno del ciclo de vida del socket: nadie mas deberia llamar a
/// `sockets.connect()` ni a `sockets.disconnect()` directamente, porque este
/// servicio es el que sabe si hay un intento en curso y el que traduce el
/// resultado a algo que la app pueda mostrar.
///
/// Es singleton porque la conexion es una sola y de larga vida: la abre la
/// sesion (`ClientService`) y la consumen pantallas que van y vienen, asi que
/// no puede depender del ciclo de vida de ningun widget. Ademas se registra en
/// `initialBuilder` con `ChangeNotifierProvider.value` para poder observarlo
/// con `context.watch`, y por eso mismo no debe destruirlo el provider.
///
/// ```dart
/// // Estado, para pintar un indicador de conexion.
/// final online = context.watch<ConnectionService>().isConnected;
///
/// // Eventos del servidor. `on` devuelve la baja del listener.
/// final remove = ConnectionService().on("stock:update", (data) => ...);
/// ```
class ConnectionService extends ChangeNotifier {
  //SINGLETON
  static final ConnectionService _singleton = ConnectionService._internal();
  factory ConnectionService() => _singleton;

  ConnectionService._internal() {
    sockets.status.addListener(_onStatus);
  }

  /// Intento de apertura en curso, para que varias llamadas a [open] se cuelguen
  /// del mismo handshake en vez de encadenar reintentos.
  Future<void>? _opening;

  /// Verdadero desde que se cierra a proposito hasta la proxima apertura. Sirve
  /// para no reportar como fallo el corte que provoca el propio [close].
  bool _closed = false;

  Map<String, dynamic>? _error;

  // ─── Estado ─────────────────────────────────────────────────────────────────

  SocketStatus get status => sockets.status.value;

  /// El estado crudo, por si conviene pintarlo con un `ValueListenableBuilder`
  /// en vez de reconstruir con el provider.
  ValueListenable<SocketStatus> get listenable => sockets.status;

  bool get isConnected => status == SocketStatus.connected;

  /// Hay un intento en curso (primero o reintento). No es un fallo: la UI que
  /// avisa de la caida deberia esperar a [isDisconnected].
  bool get isConnecting =>
    status == SocketStatus.connecting || status == SocketStatus.reconnecting;

  /// La conexion no esta disponible y nadie la esta reintentando.
  bool get isDisconnected =>
    status == SocketStatus.disconnected || status == SocketStatus.idle;

  /// Ultimo fallo, ya normalizado a `{message, action}` para poder pasarselo a
  /// `FloatFlag.fromError`. Se limpia al conectar.
  Map<String, dynamic>? get error => _error;

  /// Id que el servidor le dio a esta conexion. Cambia en cada reconexion.
  String? get id => sockets.id;

  // ─── Ciclo de vida ──────────────────────────────────────────────────────────

  /// Abre la conexion. Es lo que hay que llamar cuando la sesion ya es valida.
  ///
  /// No lanza: un fallo de conexion no deberia romper el flujo que la abrio (el
  /// arranque de la app, entrar al home), asi que el error queda en [error] y
  /// el cliente sigue reintentando solo. Es idempotente, se puede llamar cada
  /// vez que se entra a una seccion autenticada.
  Future<void> open() async {
    if (isConnected) return;

    final pending = _opening;
    if (pending != null) return pending;

    final attempt = _open();
    _opening = attempt;

    try {
      await attempt;
    } finally {
      _opening = null;
    }
  }

  Future<void> _open() async {
    _closed = false;
    _fail(null);

    try {
      await sockets.connect();
    } catch (e) {
      // El corte lo provoco un `close` que llego mientras se abria: no es un
      // fallo que haya que mostrar.
      if (_closed) return;
      _fail(e is Map ? Map<String, dynamic>.from(e) : sockets.exception(e));
    }
  }

  /// Cierra la conexion sin soltar los listeners: un [open] posterior vuelve a
  /// recibir los mismos eventos. Es lo que hay que llamar al cerrar sesion.
  void close() {
    _closed = true;
    _fail(null);
    sockets.disconnect();
  }

  /// Reconecta rehaciendo el handshake.
  ///
  /// Hace falta cuando cambio algo que viaja en el (token nuevo, otra empresa
  /// activa): esos datos se leen al abrir la conexion, reconectar sin mas los
  /// mantendria viejos.
  Future<void> refresh() async {
    _closed = false;
    _fail(null);

    try {
      await sockets.refresh();
    } catch (e) {
      if (_closed) return;
      _fail(e is Map ? Map<String, dynamic>.from(e) : sockets.exception(e));
    }
  }

  // ─── Eventos ────────────────────────────────────────────────────────────────
  //
  // Pasan derecho al socket. Se pueden registrar antes de que la conexion este
  // abierta: quedan anotados y se enganchan al conectar, y sobreviven a un
  // [refresh].

  /// Escucha un evento del servidor. Devuelve la funcion que lo da de baja.
  void Function() on(String event, SocketHandler handler) =>
    sockets.on(event, handler);

  /// Escucha un evento una sola vez.
  void once(String event, SocketHandler handler) => sockets.once(event, handler);

  /// Da de baja un handler, o todos los del evento si no se pasa ninguno.
  void off(String event, [SocketHandler? handler]) => sockets.off(event, handler);

  /// El evento como `Stream`, para consumirlo con un `StreamBuilder`.
  Stream<dynamic> stream(String event) => sockets.stream(event);

  /// Manda un evento sin esperar respuesta.
  void emit(String event, [dynamic data]) => sockets.emit(event, data);

  /// Manda un evento y espera la respuesta del servidor, como una peticion REST
  /// (lanza el error normalizado si falla).
  Future<dynamic> request(String event, {dynamic data, Duration? timeout}) =>
    sockets.request(event, data: data, timeout: timeout);

  // ─── Interno ────────────────────────────────────────────────────────────────

  void _onStatus() {
    // Conectar deja sin vigencia el fallo anterior; si no, un indicador que
    // muestre `error` seguiria en rojo con la conexion ya restablecida.
    if (isConnected) _error = null;
    notifyListeners();
  }

  void _fail(Map<String, dynamic>? value) {
    if (_error == null && value == null) return;
    _error = value;
    notifyListeners();
  }
}
