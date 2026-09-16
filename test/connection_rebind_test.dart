import 'package:flutter_test/flutter_test.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/toolkit/sockets.dart';

/// `ConnectionService.rebind` is what `BusinessService` calls on every change
/// of the active business: the server joins a socket to its business's rooms
/// once, in the handshake, so a switch that does not redo it leaves the app
/// listening to the business it started with.
///
/// What is pinned here is the half a test can reach without a server: it
/// reconnects **only a connection somebody asked for**. Never opened, the next
/// `open` already carries the new business; closed on sign out, reconnecting
/// would bring back a socket for a session that is gone. Both leave the socket
/// untouched — which is also what keeps every test that switches business off
/// the network.
void main() {
  test('a connection that was never opened is left alone', () async {
    expect(sockets.status.value, SocketStatus.idle);

    await ConnectionService().rebind();

    expect(sockets.status.value, SocketStatus.idle);
  });

  test('a connection closed on sign out is not brought back', () async {
    ConnectionService().close();

    await ConnectionService().rebind();

    expect(sockets.status.value, SocketStatus.disconnected);
  });
}
