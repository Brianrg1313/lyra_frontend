import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart';
import './lan_device.dart';
import './lan_identity_store.dart';

/// Why pairing stopped, for the pairing page to say.
enum LanPairingError {
  /// The code (or QR) didn't match: typed wrong, expired, or used up (S-40).
  wrongCode,

  /// Someone answered who isn't the master that was shown (`wrong_master`): the page warns
  /// that something on the network is in the middle.
  wrongMaster,

  /// Nothing answered at that address.
  unreachable,
}

/// Pairs this install with a master as a client (plan §5.3): finds masters on the LAN, runs
/// the code exchange (`pairDevice`) with a key it just made, and keeps the result.
///
/// Flow-scoped: the pairing page provides it.
class LanPairingService extends ChangeNotifier {
  LanPairingService({
    LanIdentityStore store = const SecureLanIdentityStore(),
    Future<List<LanFound>> Function()? discover,
    Future<LanPairingSocket> Function(String host, int port)? open,
    Future<LanDeviceKey> Function()? newKey,
    String? deviceName,
  }) : _store = store,
       _discover = discover ?? discoverMasters,
       _open = open ?? openPairingSocket,
       _newKey = newKey ?? newDeviceKey,
       _deviceName = deviceName;

  final LanIdentityStore _store;
  final Future<List<LanFound>> Function() _discover;
  final Future<LanPairingSocket> Function(String host, int port) _open;
  final Future<LanDeviceKey> Function() _newKey;
  final String? _deviceName;

  List<LanFound> _found = const [];
  List<LanFound> get found => _found;

  bool _searching = false;
  bool get searching => _searching;

  /// Looks for masters answering mDNS.
  Future<void> search() async {
    _searching = true;
    notifyListeners();

    _found = await _discover();
    _searching = false;
    notifyListeners();
  }

  /// Pairs with the master at [host]:[port] using the 8-digit [code] shown on it, as a device
  /// called [name]. Null on success; this device is then a `local` client.
  Future<LanPairingError?> pair({required String host, required int port, required String code, required String name}) =>
    _pair(host, port, name: name, code: code);

  /// Pairs with the master whose QR was scanned ([PairingOffer.parse]): its token is the
  /// secret and its CA fingerprint is checked. Tries each address it lists, the likeliest first.
  Future<LanPairingError?> pairScanned(PairingOffer offer, {required String name}) async {
    for (final host in offer.addresses) {
      final failure = await _pair(host, offer.port, name: name, offer: offer);
      // Only an address that didn't answer is worth trying the next: any master that did
      // answer has spent the token.
      if (failure != LanPairingError.unreachable) return failure;
    }

    return LanPairingError.unreachable;
  }

  Future<LanPairingError?> _pair(String host, int port, {required String name, String? code, PairingOffer? offer}) async {
    final LanPairingSocket socket;

    try {
      socket = await _open(host, port);
    } catch (error) {
      if (kDebugMode) print("pairing: $host:$port unreachable: $error");
      return LanPairingError.unreachable;
    }

    try {
      final key = await _newKey();
      final result = await pairDevice(
        socket.channel,
        device: PairingDevice(name: _deviceName ?? name, platform: lanPlatform, appVersion: lanAppVersion),
        signer: key,
        code: code,
        offer: offer,
      );

      await key.keep();
      await _store.saveDevice(LanDevice(
        role: DeploymentRole.client,
        instanceId: result.instanceId,
        deviceId: result.deviceId,
        code: result.deviceCode,
        caCertificate: result.caCertificate,
        // A browser gets none: it proves itself with its WebCrypto key (`device.prove`).
        certificate: result.certificate ?? Uint8List(0),
        privateKeyPem: key.privateKeyPem ?? "",
        hosts: [host],
        port: port,
      ));
      await _store.saveRefreshToken(null);
      Deployment.choose(DeploymentMode.local, role: DeploymentRole.client);

      return null;
    } on PairingFailure catch (failure) {
      return failure.code == PairingFailure.wrongMaster ? LanPairingError.wrongMaster : LanPairingError.wrongCode;
    } catch (error) {
      if (kDebugMode) print("pairing failed: $error");
      return LanPairingError.unreachable;
    } finally {
      await socket.close();
    }
  }
}
