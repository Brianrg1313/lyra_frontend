import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

import './status_dot.dart';

/// One device: its state as a dot and a word at the right edge (read down the column), its code
/// in the display face because it is what people say aloud to tell two tablets apart. A removed
/// device stays listed, dimmed, so nobody takes it for one that was never paired.
class ServerDeviceRow extends StatelessWidget {
  const ServerDeviceRow({super.key, required this.device, required this.mine, required this.onRemove});

  final Map<String, Object?> device;
  final bool mine;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final master = device["kind"] == "master";
    final revoked = device["revoked"] != null;
    final online = !revoked && device["online"] == true;
    final platform = device["platform"] as String?;
    final (state, color) = revoked
      ? (s.lan_devices_revoked, scheme.accent)
      : master
        ? (s.lan_devices_master, scheme.primary)
        : online ? (s.lan_devices_online, scheme.primary) : (s.lan_devices_offline, scheme.subtitle);

    return Opacity(
      opacity: revoked ? 0.55 : 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
        child: Row(children: [
          StatusDot(on: online),
          SizedBox(width: AppSize.spaceS),
          SizedBox(
            width: 44,
            child: TextMedium(device["code"] as String, font: TextFont.bebas, multiplier: 1.5, color: scheme.subtitle)
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: TextMedium(device["name"] as String, bold: true, ellipsis: true)),
              if (mine) ...[
                SizedBox(width: AppSize.gap),
                TextSmall(s.lan_devices_this, color: scheme.primary)
              ]
            ]),
            if (platform != null) TextSmall(platform, color: scheme.subtitle, ellipsis: true)
          ])),
          SizedBox(width: AppSize.spaceS),
          TextSmall(state, color: color),
          if (!master && !revoked) ...[
            SizedBox(width: AppSize.spaceS),
            Button(title: s.lan_devices_remove, width: null, action: onRemove)
          ]
        ])
      )
    );
  }
}
