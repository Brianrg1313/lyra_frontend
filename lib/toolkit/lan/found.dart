// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

/// A master seen on the LAN by mDNS (`Discovery`): its advertised name and where it listens.
class LanFound {
  const LanFound({required this.name, required this.host, required this.port});

  /// `lyra-<advertised id>`: no company name, on purpose (plan §5.2).
  final String name;
  final String host;
  final int port;
}

/// A `/pair` connection and how to close it.
class LanPairingSocket {
  const LanPairingSocket(this.channel, this.close);

  final PairingChannel channel;
  final Future<void> Function() close;
}
