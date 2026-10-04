import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/button.dart';
import './widgets/lan_address.dart';
import './widgets/lan_browsers.dart';
import './widgets/pairing_panel.dart';
import './widgets/server_away.dart';
import './widgets/server_connection.dart';
import './widgets/status_dot.dart';

/// The `local_server` home section, wherever a master can be (plan §4 admin screens, D16). With
/// the server's session ([_ServerReady]); online without it, [ServerAway]: the server that
/// doesn't answer, or creating one on this computer.
class LocalServerSection extends StatelessWidget {
  const LocalServerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.select<LanService, bool>((lan) => lan.status == LanStatus.ready);
    context.watch<HybridService>();

    return ready && Deployment.mode != DeploymentMode.cloud ? const _ServerReady() : const ServerAway();
  }
}

/// How this device works with the server ([ServerConnection]) across the top; below, the
/// server's devices, who is paired and online, removing one, and, on the master's own app, adding
/// one ([PairingPanel]). The rest is reference, read once and set aside, so it sits in a side
/// column (under the list on a narrow window): the address a browser opens ([LanAddress]), on a
/// native device the browsers' root ([LanBrowsers]), this device's code and the CA it trusts,
/// and the session's way out.
class _ServerReady extends StatefulWidget {
  const _ServerReady();

  @override
  State<_ServerReady> createState() => _ServerReadyState();
}

class _ServerReadyState extends State<_ServerReady> {
  List<Map<String, Object?>>? _devices;
  Map<String, Object?>? _pairing;

  /// `devices.browserCa`: the address and the browsers' root. Absent when this master doesn't
  /// answer it yet (an older engine) or the connection dropped: both blocks then stay out.
  Map<String, Object?>? _ca;
  Timer? _refresh;

  /// Devices can't be listed without `local_server.devices`: the list then stays out.
  bool _forbidden = false;

  /// Below this width the side column goes under the list.
  static const _twoColumns = 820.0;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<LanService>().browserCa().then((ca) {
      if (mounted) setState(() => _ca = ca);
    }, onError: (_) {});
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
      if (!mounted) return;

      // A code pairs one device: once a new one shows up, the open code is spent.
      final known = {for (final d in _devices ?? const <Map<String, Object?>>[]) d["id"]};
      final paired = _devices != null && devices.any((d) => !known.contains(d["id"]));
      setState(() {
        _devices = devices;
        if (paired) _pairing = null;
      });
    } on Map<String, Object?> catch (failure) {
      if (mounted && failure["code"] == "forbidden") setState(() => _forbidden = true);
    } on Object {
      // The connection dropped: the service's status takes the page elsewhere.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableWidget(
      padding: EdgeInsets.all(AppSize.spaceM),
      children: [Align(alignment: Alignment.topLeft, child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _forbidden ? 560 : 1080),
        child: LayoutBuilder(builder: (context, box) {
          final side = _side(context);

          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ServerConnection(),
            if (_forbidden)
              side
            else if (box.maxWidth >= _twoColumns)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _roster(context)),
                SizedBox(width: AppSize.spaceL),
                SizedBox(width: 360, child: side)
              ])
            else ...[
              _roster(context),
              SizedBox(height: AppSize.spaceM),
              side
            ]
          ]);
        })
      ))]
    );
  }

  /// The devices: the server first, then who is online, then who isn't, the removed last.
  Widget _roster(BuildContext context) {
    final lan = context.watch<LanService>();
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final devices = _devices == null ? null : ([..._devices!]..sort((a, b) => _rank(a).compareTo(_rank(b))));
    final connected = devices?.where((d) => d["revoked"] == null && d["online"] == true).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextInter(s.lan_devices, multiplier: 1.8, bold: true),
          if (connected != null) TextSmall(s.lan_devices_connected(connected), color: scheme.subtitle)
        ])),
        if (lan.isMaster && _pairing == null) Button(
          title: s.lan_add_device,
          width: null,
          leftIcon: Icon(CI.plus, color: scheme.button.text),
          action: _addDevice
        )
      ]),
      SizedBox(height: AppSize.spaceS),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _pairing == null
          ? const SizedBox(width: double.infinity)
          : PairingPanel(pairing: _pairing!, onRenew: _addDevice, onClose: () => setState(() => _pairing = null))
      ),
      if (devices == null)
        SizedBox(height: AppSize.action, child: const Align(alignment: Alignment.centerLeft, child: Loading()))
      else
        for (final (i, item) in devices.indexed) ...[
          if (i > 0) Separator.horizontal(color: scheme.line),
          _DeviceRow(device: item, mine: item["id"] == lan.device?.deviceId, onRemove: () => _remove(item))
        ]
    ]);
  }

  static int _rank(Map<String, Object?> device) {
    if (device["revoked"] != null) return 3;
    if (device["kind"] == "master") return 0;
    return device["online"] == true ? 1 : 2;
  }

  /// Reference blocks over one surface, split by rules rather than a card each: they are parts
  /// of the same aside, not things of their own.
  Widget _side(BuildContext context) {
    final lan = context.watch<LanService>();
    final device = lan.device;
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    final blocks = <Widget>[
      if (_ca != null && LanAddress.url(_ca!) != null) LanAddress(ca: _ca!),
      if (!kIsWeb && _ca != null) LanBrowsers(ca: _ca!),
      if (device != null) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextMedium(s.lan_device_code(device.code), bold: true),
        SizedBox(height: AppSize.gap),
        TextSmall(s.lan_fingerprint, color: scheme.subtitle),
        TextSmall(device.caFingerprint, lines: 4, selectable: true)
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Button(
          title: s.lan_sign_out,
          leftIcon: Icon(CI.log_out, color: scheme.button.text),
          action: () => context.read<ClientService>().signOut(context)
        ),
        if (lan.isMaster) ...[
          SizedBox(height: AppSize.spaceXS),
          // Not a button like the rest: it ends the server for every device, so it is the one
          // action in the warning colour, apart from those that undo themselves.
          Align(alignment: Alignment.centerLeft, child: FocusableWidget(
            action: _stopServer,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSize.gap),
              child: TextMedium(s.lan_stop_server, bold: true, color: scheme.accent)
            )
          ))
        ]
      ])
    ];

    return Surface.over(
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, block) in blocks.indexed) ...[
          if (i > 0) Separator.horizontal(color: scheme.line, margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)),
          block
        ]
      ])
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

/// One device: its state as a dot and a word at the right edge (read down the column), its code
/// in the display face because it is what people say aloud to tell two tablets apart. A removed
/// device stays listed, dimmed, so nobody takes it for one that was never paired.
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.mine, required this.onRemove});

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
