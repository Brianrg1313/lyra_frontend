import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import './pairing_qr.dart';

/// An open pairing (`pairing.start`: `{qr, code, expires}`): the code to type on the new device,
/// large enough to read from across the counter, and the QR with the same lifetime for a phone.
/// The time left counts down from `expires` (the engine's clock, S-40), so an expired code says
/// so instead of failing on the other device; [onRenew] asks for another one.
class PairingPanel extends StatefulWidget {
  const PairingPanel({super.key, required this.pairing, required this.onRenew, required this.onClose});

  final Map<String, Object?> pairing;
  final VoidCallback onRenew;
  final VoidCallback onClose;

  @override
  State<PairingPanel> createState() => _PairingPanelState();
}

class _PairingPanelState extends State<PairingPanel> {
  late DateTime _expires;
  late Duration _lifetime;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(PairingPanel old) {
    super.didUpdateWidget(old);
    if (old.pairing != widget.pairing) _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// The bar's full length is the lifetime left when the code arrived: the two clocks may
  /// differ by a little, never by the whole lifetime.
  void _start() {
    _expires = DateTime.parse(widget.pairing["expires"] as String);
    _lifetime = _left;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_left == Duration.zero) _tick?.cancel();
    });
  }

  Duration get _left {
    final left = _expires.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final code = widget.pairing["code"] as String;
    final left = _left;
    final expired = left == Duration.zero;
    final share = _lifetime.inMilliseconds == 0 ? 0.0 : left.inMilliseconds / _lifetime.inMilliseconds;
    final time = "${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, "0")}";

    final codeBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextSmall(s.lan_pairing_code, color: scheme.subtitle),
      SizedBox(height: AppSize.gap),
      TextMedium(
        "${code.substring(0, 4)} ${code.substring(4)}",
        font: TextFont.bebas,
        multiplier: 4.4,
        selectable: !expired,
        color: expired ? scheme.subtitle : null
      ),
      SizedBox(height: AppSize.gap),
      ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Container(
          height: 2,
          color: scheme.line,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(widthFactor: share.clamp(0.0, 1.0), child: Container(color: scheme.primary))
        )
      ),
      SizedBox(height: AppSize.spaceXS),
      if (expired)
        TextSmall(s.lan_pairing_expired, lines: 2, color: scheme.accent)
      else
        TextSmall(s.lan_pairing_expires(time), lines: 2, color: scheme.subtitle),
      SizedBox(height: AppSize.spaceS),
      Wrap(spacing: AppSize.spaceXS, runSpacing: AppSize.spaceXS, children: [
        if (expired) MainButton(title: s.lan_pairing_new, action: widget.onRenew),
        Button(title: s.lan_pairing_close, width: null, action: widget.onClose)
      ])
    ]);

    final qrBlock = Opacity(
      opacity: expired ? 0.15 : 1,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        PairingQr(data: widget.pairing["qr"] as String, size: 168),
        SizedBox(height: AppSize.gap),
        SizedBox(width: 168, child: TextSmall(s.lan_pairing_scan, lines: 2, textAlign: TextAlign.center, color: scheme.subtitle))
      ])
    );

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceM),
        child: LayoutBuilder(builder: (context, box) => box.maxWidth >= 440
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: codeBlock),
              SizedBox(width: AppSize.spaceM),
              qrBlock
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              codeBlock,
              SizedBox(height: AppSize.spaceM),
              Center(child: qrBlock)
            ])
        )
      )
    );
  }
}
