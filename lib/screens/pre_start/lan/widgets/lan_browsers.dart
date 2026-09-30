import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show Fingerprint;

// SERVICES
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';

/// The browsers' root of the installation (plan §5.3), on a native device: a browser opens the
/// master's web build only where it is trusted. This device's channel to the master is pinned,
/// so what it installs or saves can't have been swapped on the network. Installed by hand, the
/// person compares the fingerprint the OS shows with the one here.
class LanBrowsers extends StatefulWidget {
  const LanBrowsers({super.key});

  @override
  State<LanBrowsers> createState() => _LanBrowsersState();
}

class _LanBrowsersState extends State<LanBrowsers> {
  Map<String, Object?>? _ca;
  String? _note;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    context.read<LanService>().browserCa().then((ca) {
      if (mounted) setState(() => _ca = ca);
    }, onError: (_) {
      // Not on this master yet (an older engine) or the connection dropped: the block stays out.
    });
  }

  @override
  Widget build(BuildContext context) {
    final ca = _ca;
    if (ca == null) return const SizedBox.shrink();

    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final addresses = (ca["addresses"] as List).cast<String>();
    final address = addresses.isEmpty ? null : "https://${addresses.first}:${ca["port"]}";

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceM),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextInter(s.lan_browsers_title, multiplier: 1.4, bold: true),
        SizedBox(height: AppSize.gap),
        TextSmall(s.lan_browsers_subtitle, lines: 4, color: scheme.subtitle),
        SizedBox(height: AppSize.spaceXS),
        Surface(
          color: scheme.surface,
          padding: EdgeInsets.all(AppSize.spaceS),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextSmall(s.lan_browsers_fingerprint, color: scheme.subtitle),
            TextSmall(Fingerprint.display(ca["fingerprint"] as String), lines: 4, selectable: true),
            SizedBox(height: AppSize.gap),
            TextSmall(s.lan_browsers_thumbprint, color: scheme.subtitle),
            TextSmall(Fingerprint.display(ca["thumbprint"] as String), lines: 2, selectable: true),
            if (address != null) ...[
              SizedBox(height: AppSize.gap),
              TextSmall(s.lan_browsers_open(address), lines: 2, selectable: true)
            ]
          ])
        ),
        SizedBox(height: AppSize.spaceXS),
        if (canInstallBrowserCa) ...[
          Button(title: s.lan_browsers_install, action: _install),
          SizedBox(height: AppSize.gap),
        ],
        Button(title: s.lan_browsers_save, action: _save),
        if (_note != null) DeploymentNote(_note!, error: _failed)
      ])
    );
  }

  Uint8List get _certificate => base64.decode(_ca!["certificate"] as String);

  Future<void> _install() async {
    final installed = await installBrowserCa(_certificate);
    if (!mounted) return;

    setState(() {
      _failed = !installed;
      _note = installed ? S.of(context).lan_browsers_installed : S.of(context).lan_browsers_not_installed;
    });
  }

  Future<void> _save() async {
    try {
      if (!await saveBrowserCa(_certificate) || !mounted) return;
      setState(() {
        _failed = false;
        _note = S.of(context).lan_browsers_saved;
      });
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }
}
