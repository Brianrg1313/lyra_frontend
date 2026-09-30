import 'dart:async';
import 'dart:io';

// PACKAGES
import 'package:lyra_protocol/io.dart';
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:multicast_dns/multicast_dns.dart';

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import './lan_found.dart';

/// Native transport of the LAN client (`lan.dart`): `dart:io` sockets, mutual TLS pinned to
/// the installation CA, mDNS discovery.
///
/// The master refuses a revoked device's upgrade with `403` (`protocol-v1.md` §3): that comes
/// back as `device_revoked`, not as an unreachable master.
Future<RpcClient> openRpc(LanDevice device, String host) async {
  try {
    return await connectRpc(
      host,
      device.port,
      LanIdentity(
        caCertificate: device.caCertificate,
        certificate: device.certificate,
        privateKeyPem: device.privateKeyPem,
      ),
      timeout: const Duration(seconds: 5),
    );
  } on WebSocketException catch (error) {
    if (error.httpStatusCode == HttpStatus.forbidden) throw const RpcError(ErrorCodes.deviceRevoked, "");
    rethrow;
  }
}

Future<LanPairingSocket> openPairing(String host, int port) async {
  final channel = await connectPairing(host, port);

  return LanPairingSocket(channel, channel.close);
}

/// The masters answering `_lyra._tcp.local` within [timeout] (plan §5.2). Only a hint: a
/// spoofed answer at most gets a pairing that fails.
Future<List<LanFound>> discover({Duration timeout = const Duration(seconds: 3)}) async {
  final client = MDnsClient(rawDatagramSocketFactory: (host, int port, {bool? reuseAddress, bool? reusePort, int? ttl}) =>
    // Windows has no SO_REUSEPORT.
    RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: !Platform.isWindows && (reusePort ?? false), ttl: ttl ?? 255));
  final found = <String, LanFound>{};

  try {
    await client.start();

    final pointers = await client
      .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(Discovery.serviceType))
      .timeout(timeout, onTimeout: (sink) => sink.close())
      .toList();

    for (final pointer in pointers.map((record) => record.domainName).toSet()) {
      final services = await client
        .lookup<SrvResourceRecord>(ResourceRecordQuery.service(pointer))
        .timeout(timeout, onTimeout: (sink) => sink.close())
        .toList();

      for (final service in services) {
        final addresses = await client
          .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(service.target))
          .timeout(timeout, onTimeout: (sink) => sink.close())
          .toList();

        for (final address in addresses) {
          found[pointer] ??= LanFound(
            name: pointer.split(".").first,
            host: address.address.address,
            port: service.port,
          );
        }
      }
    }
  } on SocketException {
    // No multicast here (a VPN, a firewall): the person types the address instead.
  } finally {
    client.stop();
  }

  return found.values.toList();
}

bool get lanSupported => true;
