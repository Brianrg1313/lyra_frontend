import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';
import './lan_browsers.dart';
import './pairing_qr.dart';

/// Signed in to the master. Until the domains arrive (plan phase 4) this is the server's
/// devices: who is paired and online, removing one, and, on the master's own app, adding one
/// (`pairing.start` shows the code to type on the new device and the QR a phone scans). A
/// native device also hands out the browsers' root ([LanBrowsers]).
class LanConnected extends StatefulWidget {
  const LanConnected({super.key});

  @override
  State<LanConnected> createState() => _LanConnectedState();
}

class _LanConnectedState extends State<LanConnected> {
  List<Map<String, Object?>>? _devices;
  Map<String, Object?>? _pairing;
  Timer? _refresh;

  /// Devices can't be listed without `local_server.devices`: the block then stays out.
  bool _forbidden = false;

  @override
  void initState() {
    super.initState();
    _load();
    // Pairing happens on the other device: the list follows it while the page is open.
    _refresh = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final devices = await context.read<LanService>().devices();
      if (mounted) setState(() => _devices = devices);
    } on Map<String, Object?> catch (failure) {
      if (mounted && failure["code"] == "forbidden") setState(() => _forbidden = true);
    } on Object {
      // The connection dropped: the service's status takes the page elsewhere.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lan = context.watch<LanService>();
    final device = lan.device;
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return DeploymentFrame(
      title: s.lan_ready_title,
      subtitle: s.lan_ready_subtitle,
      maxWidth: 560,
      children: [
        if (device != null) Surface(
          color: scheme.surface,
          padding: EdgeInsets.all(AppSize.spaceS),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextMedium(s.lan_device_code(device.code), bold: true),
            SizedBox(height: AppSize.gap),
            TextSmall(s.lan_fingerprint, color: scheme.subtitle),
            TextSmall(device.caFingerprint, lines: 4, selectable: true)
          ])
        ),
        if (!_forbidden) ...[
          SizedBox(height: AppSize.spaceM),
          Row(children: [
            Expanded(child: TextInter(s.lan_devices, multiplier: 1.4, bold: true)),
            if (lan.isMaster) Button(title: s.lan_add_device, width: null, action: _addDevice)
          ]),
          if (_pairing != null) _PairingCode(pairing: _pairing!),
          SizedBox(height: AppSize.spaceXS),
          if (_devices == null)
            SizedBox(height: AppSize.action, child: const Center(child: Loading()))
          else
            for (final item in _devices!) _DeviceRow(device: item, onRemove: () => _remove(item))
        ],
        if (!kIsWeb) const LanBrowsers(),
        SizedBox(height: AppSize.spaceM),
        Button(title: s.lan_sign_out, action: lan.signOut),
        if (lan.isMaster) ...[
          SizedBox(height: AppSize.spaceXS),
          Button(title: s.lan_stop_server, action: _stopServer)
        ]
      ]
    );
  }

  Future<void> _addDevice() async {
    try {
      final pairing = await context.read<LanService>().startPairing();
      if (mounted) setState(() => _pairing = pairing);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  Future<void> _remove(Map<String, Object?> device) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).lan_devices_remove_title(device["name"] as String),
      message: S.of(context).lan_devices_remove_message,
      confirmText: S.of(context).lan_devices_remove,
      cancelText: S.of(context).cancel
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<LanService>().revoke(device["id"] as String);
      await _load();
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  Future<void> _stopServer() async {
    final online = (_devices ?? const []).where((d) => d["online"] == true && d["kind"] != "master").length;
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).lan_stop_server_title,
      message: S.of(context).lan_stop_server_message(online),
      confirmText: S.of(context).lan_stop_server,
      cancelText: S.of(context).cancel
    );
    if (!confirmed || !mounted) return;

    await context.read<LanService>().stopServer();
  }
}

/// The code to type on the new device, when it stops working (S-40), and the QR with the same
/// lifetime for a phone.
class _PairingCode extends StatelessWidget {
  const _PairingCode({required this.pairing});

  final Map<String, Object?> pairing;

  @override
  Widget build(BuildContext context) {
    final code = pairing["code"] as String;
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceXS),
      child: Surface(
        color: scheme.surfaceOver,
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(children: [
          TextSmall(S.of(context).lan_pairing_code, color: scheme.subtitle),
          SizedBox(height: AppSize.gap),
          TextInter("${code.substring(0, 4)} ${code.substring(4)}", multiplier: 2.4, bold: true, selectable: true),
          SizedBox(height: AppSize.gap),
          TextSmall(S.of(context).lan_pairing_expires, color: scheme.subtitle, textAlign: TextAlign.center, lines: 2),
          SizedBox(height: AppSize.spaceS),
          TextSmall(S.of(context).lan_pairing_scan, color: scheme.subtitle, textAlign: TextAlign.center, lines: 2),
          SizedBox(height: AppSize.gap),
          PairingQr(data: pairing["qr"] as String)
        ])
      )
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.onRemove});

  final Map<String, Object?> device;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final master = device["kind"] == "master";
    final revoked = device["revoked"] != null;
    final state = revoked
      ? s.lan_devices_revoked
      : master ? s.lan_devices_master : device["online"] == true ? s.lan_devices_online : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.gap * 0.5),
      child: Row(children: [
        SizedBox(width: 32, child: TextMedium(device["code"] as String, bold: true, color: scheme.subtitle)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextMedium(device["name"] as String, ellipsis: true),
          TextSmall(
            [device["platform"], ?state].join(" · "),
            color: revoked ? scheme.accent : scheme.subtitle
          )
        ])),
        if (!master && !revoked) Button(title: s.lan_devices_remove, width: null, action: onRemove)
      ])
    );
  }
}
