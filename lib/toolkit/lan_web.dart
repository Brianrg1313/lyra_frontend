import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:web/web.dart' as web;

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import './lan_found.dart';
import './lan_key.dart';

/// Browser transport of the LAN client (`lan.dart`, `protocol-v1.md` §3).
///
/// The page is served by the master itself (plan §3), so the master is the page's own origin:
/// `/rpc` and `/pair` always go there, whatever address was stored, because the master lets a
/// browser in only from its own page (the `Origin` check in `lyra_node`'s `server.dart`). TLS
/// is the browser's: it trusts the master only with the installation CA installed.
///
/// A browser can't present a client certificate reliably. Its identity is a non-extractable
/// WebCrypto P-256 key kept in IndexedDB: it signs the pairing proof and, on every connection,
/// the `hello` challenge (`device.prove`).
Future<RpcClient> openRpc(LanDevice device, String host) async => RpcClient(await _BrowserSocket.open("/rpc"));

Future<LanPairingSocket> openPairing(String host, int port) async {
  final socket = await _BrowserSocket.open("/pair");

  return LanPairingSocket(_BrowserPairingChannel(socket), socket.close);
}

/// A browser has no multicast: the master is the page's origin.
Future<List<LanFound>> discover({Duration timeout = const Duration(seconds: 3)}) async => const [];

bool get lanSupported => true;

Future<LanDeviceKey> newDeviceKey() async {
  final pair = await _subtle.generateKey(
    {"name": "ECDSA", "namedCurve": "P-256"}.jsify()!,
    false,
    ["sign".toJS, "verify".toJS].toJS,
  ).toDart as _KeyPair;
  final spki = await _subtle.exportKey("spki", pair.publicKey).toDart as JSArrayBuffer;

  return _BrowserDeviceKey(pair, spki.toDart.asUint8List());
}

/// Signs `device.prove` with the key kept at pairing; null when this browser lost it (its site
/// data was cleared): it pairs again.
Future<Uint8List?> signProof(LanDevice device, List<int> message) async {
  final pair = await _KeyStore.get();

  return pair == null ? null : _sign(pair.privateKey, message);
}

Future<void> forgetDeviceKey() => _KeyStore.delete();

/// Only a native device, whose channel to the master is pinned, installs the CA (plan §5.3).
bool get canInstallBrowserCa => false;

Future<bool> installBrowserCa(Uint8List certificate) async => false;

web.SubtleCrypto get _subtle => web.window.crypto.subtle;

Future<Uint8List> _sign(web.CryptoKey key, List<int> message) async {
  final signature = await _subtle.sign(
    {"name": "ECDSA", "hash": "SHA-256"}.jsify()!,
    key,
    Uint8List.fromList(message).toJS,
  ).toDart as JSArrayBuffer;

  // Raw `r ‖ s`, 64 bytes: the master reads it as well as DER (`P256.verify`).
  return signature.toDart.asUint8List();
}

/// WebCrypto's `CryptoKeyPair`, which `package:web` doesn't declare.
extension type _KeyPair._(JSObject _) implements JSObject {
  external web.CryptoKey get privateKey;
  external web.CryptoKey get publicKey;
}

final class _BrowserDeviceKey implements LanDeviceKey {
  _BrowserDeviceKey(this._pair, this.spki);

  final _KeyPair _pair;

  @override
  final Uint8List spki;

  @override
  String? get privateKeyPem => null;

  @override
  Future<Uint8List> sign(List<int> message) => _sign(_pair.privateKey, message);

  @override
  Future<void> keep() => _KeyStore.put(_pair);
}

/// The device key in IndexedDB. A `CryptoKey` is stored as itself (structured clone): the
/// private half stays non-extractable, so no script can read it out, only sign with it.
abstract final class _KeyStore {
  static const _database = "lyra-lan";
  static const _store = "keys";
  static const _key = "device";

  static Future<void> put(_KeyPair pair) => _run("readwrite", (store) => store.put(pair, _key.toJS));

  static Future<_KeyPair?> get() async => await _run("readonly", (store) => store.get(_key.toJS)) as _KeyPair?;

  static Future<void> delete() => _run("readwrite", (store) => store.delete(_key.toJS));

  static Future<JSAny?> _run(String mode, web.IDBRequest Function(web.IDBObjectStore store) body) async {
    final open = web.window.indexedDB.open(_database, 1);
    open.onupgradeneeded = ((web.Event _) => (open.result as web.IDBDatabase).createObjectStore(_store)).toJS;

    final database = await _result(open) as web.IDBDatabase;
    try {
      return await _result(body(database.transaction(_store.toJS, mode).objectStore(_store)));
    } finally {
      database.close();
    }
  }

  static Future<JSAny?> _result(web.IDBRequest request) {
    final done = Completer<JSAny?>();

    request.onsuccess = ((web.Event _) => done.complete(request.result)).toJS;
    request.onerror = ((web.Event _) => done.completeError(StateError("IndexedDB: ${request.error?.message}"))).toJS;

    return done.future;
  }
}

/// A browser WebSocket to the page's own origin, as text frames.
final class _BrowserSocket implements FrameSocket {
  _BrowserSocket._(this._socket);

  final web.WebSocket _socket;
  final StreamController<String> _frames = StreamController();

  static Future<_BrowserSocket> open(String path) {
    final socket = web.WebSocket("wss://${web.window.location.host}$path");
    final wrapper = _BrowserSocket._(socket);
    final opened = Completer<_BrowserSocket>();

    socket.onopen = ((web.Event _) {
      if (!opened.isCompleted) opened.complete(wrapper);
    }).toJS;
    socket.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data.isA<JSString>()) wrapper._frames.add((data as JSString).toDart);
    }).toJS;
    // A refused TLS handshake or upgrade shows up only as a close: the browser says no more.
    socket.onclose = ((web.CloseEvent _) {
      if (!opened.isCompleted) opened.completeError(const _Unreachable());
      if (!wrapper._frames.isClosed) wrapper._frames.close();
    }).toJS;

    return opened.future.timeout(const Duration(seconds: 10), onTimeout: () {
      socket.close();
      throw const _Unreachable();
    });
  }

  @override
  Stream<String> get frames => _frames.stream;

  @override
  void send(String frame) => _socket.send(frame.toJS);

  /// Not awaiting the stream's close: with a paused reader (a pairing channel) it would only
  /// complete once someone reads the done event.
  @override
  Future<void> close() async {
    _socket.close();
    if (!_frames.isClosed) unawaited(_frames.close());
  }
}

final class _Unreachable implements Exception {
  const _Unreachable();

  @override
  String toString() => "the master's page origin did not answer";
}

/// `/pair` over a browser WebSocket. [serverFingerprint] is null: the browser checked the
/// certificate against the installed CA and doesn't show it (`protocol-v1.md` §3).
final class _BrowserPairingChannel implements PairingChannel {
  _BrowserPairingChannel(this._socket);

  final _BrowserSocket _socket;
  late final StreamIterator<String> _reader = StreamIterator(_socket.frames);

  @override
  String? get serverFingerprint => null;

  @override
  Future<Map<String, Object?>> receive() async {
    while (await _reader.moveNext().timeout(const Duration(seconds: 30))) {
      try {
        final json = jsonDecode(_reader.current);
        if (json is Map<String, Object?>) return json;
      } on FormatException {
        // Not a pairing frame: the step waiting for one keeps waiting.
      }
    }

    throw const PairingFailure(Pairing.noPairing);
  }

  @override
  void send(Map<String, Object?> message) => _socket.send(jsonEncode(message));
}
