// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import './lan_found.dart';

/// Web stand-in of `lan_io.dart`. A browser reaches its master through the web build the
/// master serves and proves itself with a WebCrypto key (`protocol-v1.md` §3); that client is
/// not built yet, so LAN mode isn't offered on web ([lanSupported]).
Future<RpcClient> openRpc(LanDevice device, String host) =>
  Future.error(UnsupportedError("LAN mode on web"));

Future<LanPairingSocket> openPairing(String host, int port) =>
  Future.error(UnsupportedError("LAN mode on web"));

Future<List<LanFound>> discover({Duration timeout = const Duration(seconds: 3)}) async => const [];

bool get lanSupported => false;
