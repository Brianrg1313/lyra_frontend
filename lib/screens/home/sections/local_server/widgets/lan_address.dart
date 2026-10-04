import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// Where a browser on the network opens Lyra (`devices.browserCa`'s `host`, `addresses` and
/// `port`), first in the server section's side column so nobody has to look up the computer's
/// address. Unframed: the column's surface frames it.
/// The master's `.local` name first: it stays when the computer's address changes. Its IP below,
/// for a network where the name doesn't resolve; alone when the engine has no name yet (no
/// company, or an older engine).
class LanAddress extends StatelessWidget {
  const LanAddress({super.key, required this.ca});

  final Map<String, Object?> ca;

  /// The address to open, by name when the master has one; `null` when it has none at all.
  static String? url(Map<String, Object?> ca) => _byName(ca) ?? _byIp(ca);

  static String? _byName(Map<String, Object?> ca) {
    final host = ca["host"] as String?;
    return host == null ? null : "https://$host:${ca["port"]}";
  }

  static String? _byIp(Map<String, Object?> ca) {
    final addresses = (ca["addresses"] as List).cast<String>();
    return addresses.isEmpty ? null : "https://${addresses.first}:${ca["port"]}";
  }

  @override
  Widget build(BuildContext context) {
    final address = url(ca);
    if (address == null) return const SizedBox.shrink();

    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final ip = _byName(ca) == null ? null : _byIp(ca);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextMedium(s.lan_address_title, bold: true, lines: 2),
      SizedBox(height: AppSize.gap),
      Row(children: [
        Expanded(child: TextInter(address, multiplier: 1.15, lines: 2, selectable: true, color: scheme.primary)),
        SizedBox(width: AppSize.gap),
        Button(
          title: s.lan_address_copy,
          width: null,
          leftIcon: Icon(CI.copy, color: scheme.button.text),
          action: () => _copy(context, address)
        )
      ]),
      if (ip != null) ...[
        SizedBox(height: AppSize.gap),
        TextSmall(s.lan_browsers_fallback(ip), lines: 2, selectable: true, color: scheme.subtitle)
      ]
    ]);
  }

  Future<void> _copy(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) return;

    FloatFlag.of(context).message(S.of(context).lan_address_copied);
  }
}
