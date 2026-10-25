import 'dart:convert';
import 'dart:typed_data';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/toolkit/backend/deployment.dart';

/// What this install keeps to reach its master (`docs/offline/protocol-v1.md` §3): the
/// installation CA it trusts, its own certificate and key, and where the master was last seen.
///
/// Stored whole in the OS key store (`LanIdentityStore`): the private key never touches a
/// plain file.
class LanDevice {
  const LanDevice({
    required this.role,
    required this.instanceId,
    required this.deviceId,
    required this.code,
    required this.caCertificate,
    required this.certificate,
    required this.privateKeyPem,
    required this.hosts,
    required this.port,
  });

  factory LanDevice.fromJson(Map<String, dynamic> json) => LanDevice(
    role: DeploymentRole.values.byName(json["role"] as String),
    instanceId: json["instanceId"] as String,
    deviceId: json["deviceId"] as String,
    code: json["code"] as String,
    caCertificate: base64.decode(json["caCertificate"] as String),
    certificate: base64.decode(json["certificate"] as String),
    privateKeyPem: json["privateKeyPem"] as String,
    hosts: (json["hosts"] as List).cast<String>(),
    port: json["port"] as int,
  );

  final DeploymentRole role;
  final String instanceId;
  final String deviceId;

  /// `A`, `B`…: the device's code on its master (`session.md` session.devices).
  final String code;
  final Uint8List caCertificate;
  final Uint8List certificate;
  final String privateKeyPem;

  /// Addresses of the master, the last one that answered first. The master's own app
  /// always talks to `127.0.0.1`.
  final List<String> hosts;
  final int port;

  /// SHA-256 of the pinned CA, grouped for people (the admin screen and the setup guide compare it).
  String get caFingerprint => Fingerprint.display(Fingerprint.of(caCertificate));

  LanDevice copyWith({List<String>? hosts, int? port}) => LanDevice(
    role: role,
    instanceId: instanceId,
    deviceId: deviceId,
    code: code,
    caCertificate: caCertificate,
    certificate: certificate,
    privateKeyPem: privateKeyPem,
    hosts: hosts ?? this.hosts,
    port: port ?? this.port,
  );

  Map<String, dynamic> toJson() => {
    "role": role.name,
    "instanceId": instanceId,
    "deviceId": deviceId,
    "code": code,
    "caCertificate": base64.encode(caCertificate),
    "certificate": base64.encode(certificate),
    "privateKeyPem": privateKeyPem,
    "hosts": hosts,
    "port": port,
  };
}
