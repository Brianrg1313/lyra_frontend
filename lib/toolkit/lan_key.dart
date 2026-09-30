import 'dart:typed_data';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

/// The key a device makes when it pairs (`protocol-v1.md` §3): it signs the pairing proof and
/// is the device's identity from then on.
abstract interface class LanDeviceKey implements DeviceSigner {
  /// The private key as PEM, kept inside the `LanDevice` (the OS key store); null in a
  /// browser, whose key is non-extractable and never leaves WebCrypto.
  String? get privateKeyPem;

  /// Keeps the key for this install once pairing succeeded: a browser's goes into IndexedDB. A
  /// native key needs nothing, its PEM is stored with the device.
  Future<void> keep();
}

/// A native device's key: an [EcKeyPair] whose PEM the OS key store holds.
final class PemDeviceKey implements LanDeviceKey {
  PemDeviceKey([EcKeyPair? key]) : key = key ?? EcKeyPair.generate();

  final EcKeyPair key;

  @override
  Uint8List get spki => key.spki;

  @override
  Future<Uint8List> sign(List<int> message) async => key.sign(message);

  @override
  String get privateKeyPem => key.privateKeyPem;

  @override
  Future<void> keep() async {}
}
