import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show Fingerprint;

// SERVICES
import 'package:app/toolkit/lan.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';

import './lan_address.dart';

/// The browsers' root of the installation (plan §5.3), on a native device: a browser opens the
/// master's web build only where it is trusted. This device's channel to the master is pinned,
/// so what it installs or saves can't have been swapped on the network. Installed by hand, the
/// person compares the fingerprint the OS shows with the one here. The address to open is
/// [LanAddress], above it in the side column.
class LanBrowsers extends StatefulWidget {
  const LanBrowsers({super.key, required this.ca});

  /// `devices.browserCa`'s answer, read once by the section for this block and [LanAddress].
  final Map<String, Object?> ca;

  @override
  State<LanBrowsers> createState() => _LanBrowsersState();
}

class _LanBrowsersState extends State<LanBrowsers> {
  String? _note;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final ca = widget.ca;
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextMedium(s.lan_browsers_title, bold: true),
      SizedBox(height: AppSize.gap),
      TextSmall(s.lan_browsers_subtitle, lines: 5, color: scheme.subtitle),
      SizedBox(height: AppSize.spaceS),
      TextSmall(s.lan_browsers_fingerprint, color: scheme.subtitle),
      TextSmall(Fingerprint.display(ca["fingerprint"] as String), lines: 4, selectable: true),
      SizedBox(height: AppSize.gap),
      TextSmall(s.lan_browsers_thumbprint, color: scheme.subtitle),
      TextSmall(Fingerprint.display(ca["thumbprint"] as String), lines: 2, selectable: true),
      SizedBox(height: AppSize.spaceS),
      if (canInstallBrowserCa) ...[
        Button(title: s.lan_browsers_install, action: _install),
        SizedBox(height: AppSize.gap),
      ],
      Button(title: s.lan_browsers_save, action: _save),
      if (LanAddress.url(ca) != null) ...[
        SizedBox(height: AppSize.gap),
        TextSmall(s.lan_browsers_open, lines: 2, color: scheme.subtitle)
      ],
      if (_note != null) DeploymentNote(_note!, error: _failed)
    ]);
  }

  Uint8List get _certificate => base64.decode(widget.ca["certificate"] as String);

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
