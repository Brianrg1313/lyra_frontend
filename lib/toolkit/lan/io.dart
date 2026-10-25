import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

// PACKAGES
import 'package:lyra_protocol/io.dart';
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:multicast_dns/multicast_dns.dart';

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import './found.dart';
import './key.dart';
import './file.dart';

/// Native transport of the LAN client (`_lan.dart`): `dart:io` sockets, mutual TLS pinned to
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

Future<LanDeviceKey> newDeviceKey() async => PemDeviceKey();

/// A native device proves itself with its TLS certificate and the master never challenges it;
/// should one ask, it signs with the same key.
Future<Uint8List?> signProof(LanDevice device, List<int> message) async =>
  device.privateKeyPem.isEmpty ? null : EcKeyPair.fromPem(device.privateKeyPem).sign(message);

/// The key lives in the `LanDevice`, cleared with it.
Future<void> forgetDeviceKey() async {}

bool get canInstallBrowserCa => Platform.isWindows || Platform.isMacOS;

/// Installs the browsers' root (the name-constrained one, plan §5.3) in this user's trust store,
/// so a browser on this computer can open the master's web build. The OS asks the person first
/// (Windows: its security warning; macOS: the account password). False when they say no or
/// this OS has no way here (Linux: the file is exported instead).
///
/// It came over the pinned channel, so nothing on the network could have swapped it.
Future<bool> installBrowserCa(Uint8List certificate) async {
  if (!canInstallBrowserCa) return false;

  final folder = await Directory.systemTemp.createTemp("lyra-ca");
  final file = File("${folder.path}${Platform.pathSeparator}lyra-ca.crt");

  try {
    await file.writeAsBytes(certificate);

    final result = Platform.isWindows
      ? await Process.run("certutil", ["-user", "-addstore", "Root", file.path])
      : await Process.run("security", [
          "add-trusted-cert", "-r", "trustRoot",
          "-k", "${Platform.environment["HOME"]}/Library/Keychains/login.keychain-db",
          file.path,
        ]);

    return result.exitCode == 0;
  } finally {
    await folder.delete(recursive: true);
  }
}

/// `GET /f/<id>` or `PUT /f` on [host] (`protocol-v1.md` §6), over the same pinned mutual TLS as
/// `/rpc`: the session's token goes only to the master this device paired with.
Future<LanFileResponse> fileRequest(
  LanDevice device,
  String host,
  String method,
  String path, {
  required String token,
  Map<String, String> headers = const {},
  Uint8List? body,
}) async {
  final identity = LanIdentity(
    caCertificate: device.caCertificate,
    certificate: device.certificate,
    privateKeyPem: device.privateKeyPem,
  );
  final client = HttpClient(context: identity.context)..connectionTimeout = const Duration(seconds: 5);
  final address = InternetAddress.tryParse(host);
  final authority = address?.type == InternetAddressType.IPv6 ? "[$host]" : host;

  try {
    final request = await client.openUrl(method, Uri.parse("https://$authority:${device.port}$path"));
    request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
    headers.forEach(request.headers.set);
    if (body != null) request.add(body);

    final response = await request.close().timeout(const Duration(seconds: 60));
    final bytes = await response.fold<BytesBuilder>(BytesBuilder(copy: false), (builder, chunk) => builder..add(chunk));

    return (status: response.statusCode, body: bytes.takeBytes());
  } on SocketException {
    throw const LanFileUnreachable();
  } on HandshakeException {
    throw const LanFileUnreachable();
  } on TimeoutException {
    throw const LanFileUnreachable();
  } finally {
    client.close(force: true);
  }
}
