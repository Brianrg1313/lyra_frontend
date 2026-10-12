import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';

/// The state of the live connection to the backend (the socket), on the bottom-right of the
/// person's picture: green while connected, yellow while it tries, red when it is down. It is
/// what tells a screen that stopped moving from one that has nothing new.
///
/// Nothing while nobody asked for a connection ([SocketStatus.idle]): before the session opens
/// it, or on a master's devices, which have no socket — a red dot there would report a failure
/// that is not one.
class ConnectionDot extends StatelessWidget {
  const ConnectionDot({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SocketStatus>(
    valueListenable: ConnectionService().listenable,
    builder: (context, status, _) {
      final chart = ThemeColor.of(context).chart;
      final text = S.of(context);

      final (color, label) = switch (status) {
        SocketStatus.idle => (null, ""),
        SocketStatus.connected => (chart.good, text.connection_live_online),
        SocketStatus.connecting || SocketStatus.reconnecting => (chart.warning, text.connection_live_connecting),
        SocketStatus.disconnected => (chart.critical, text.connection_live_offline)
      };

      if (color == null) return const SizedBox.shrink();

      final size = AppSize.gap * 2;

      return Semantics(
        label: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // A ring of the side bar's colour cuts the dot out of the picture under it.
            border: Border.all(color: ThemeColor.of(context).navBar, width: AppSize.gap / 2)
          )
        )
      );
    }
  );
}
