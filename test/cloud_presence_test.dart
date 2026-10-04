import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:core/socket.dart';
import 'package:app/services/connection/cloud_presence.dart';

/// The backend's `/presence` socket as the app reads it: null until it answers, then connected
/// or not; shared, opened by the first holder and closed by the last.
void main() {
  setUpAll(() => AppController.devMode = true);

  test("the first holder doesn't read the last one's closing as the backend gone", () {
    final socket = _Socket()..status.value = SocketStatus.disconnected;
    final presence = CloudPresence(socket: socket);

    presence.start();
    expect((socket.connects, presence.live.value), (1, null));

    socket.status.value = SocketStatus.connecting;
    expect(presence.live.value, isNull);

    socket.status.value = SocketStatus.connected;
    expect(presence.live.value, isTrue);

    socket.status.value = SocketStatus.reconnecting;
    expect(presence.live.value, isFalse);
    presence.stop();
  });

  test('a second holder reads the open socket at once, and only the last one closes it', () {
    final socket = _Socket();
    final first = CloudPresence(socket: socket), second = CloudPresence(socket: socket);

    first.start();
    socket.status.value = SocketStatus.connected;
    second.start();
    expect((socket.connects, second.live.value), (1, true));

    first.stop();
    expect((socket.disconnects, first.live.value, second.live.value), (0, null, true));

    second.stop();
    expect(socket.disconnects, 1);
  });
}

/// A socket that only counts: its status is the test's.
class _Socket extends SocketAPI {
  int connects = 0;
  int disconnects = 0;

  @override
  ApiModel get dev => ApiModel(host: "localhost", name: "/presence", port: 80, scheme: "http", type: ApiMode.socket, tokenName: "Presence");

  @override
  ApiModel get prod => dev;

  @override
  Future<void> preConnect() async {}

  @override
  Future<void> connect() async => connects++;

  @override
  void disconnect() {
    disconnects++;
    status.value = SocketStatus.disconnected;
  }
}
