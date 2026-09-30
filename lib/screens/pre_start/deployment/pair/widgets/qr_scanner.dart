import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show PairingOffer;
import 'package:mobile_scanner/mobile_scanner.dart';

/// The camera, reading the QR on the master's screen (plan §5.3). The first Lyra pairing QR it
/// sees closes the modal and goes to [onOffer]; any other QR is said to be something else.
///
/// Phones only (`lanCanScan`): the scanner plugin has no Windows or Linux camera.
class QrScanner extends StatefulWidget {
  const QrScanner({super.key, required this.onOffer});

  final ValueChanged<PairingOffer> onOffer;

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;
  bool _foreign = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSize.corner),
          child: SizedBox(
            height: 320,
            child: MobileScanner(
              controller: _controller,
              onDetect: _detect,
              errorBuilder: (context, _) => Center(child: TextSmall(
                S.of(context).lan_scan_no_camera,
                lines: 3,
                textAlign: TextAlign.center,
                color: scheme.subtitle
              ))
            )
          )
        ),
        SizedBox(height: AppSize.spaceS),
        TextSmall(
          _foreign ? S.of(context).lan_scan_foreign : S.of(context).lan_scan_hint,
          lines: 3,
          textAlign: TextAlign.center,
          color: _foreign ? scheme.accent : scheme.subtitle
        )
      ])
    );
  }

  void _detect(BarcodeCapture capture) {
    if (_done) return;

    for (final barcode in capture.barcodes) {
      final text = barcode.rawValue;
      if (text == null) continue;

      final PairingOffer offer;
      try {
        offer = PairingOffer.parse(text);
      } on FormatException {
        if (!_foreign) setState(() => _foreign = true);
        continue;
      }

      _done = true;
      Navis.pop(context);
      widget.onOffer(offer);
      return;
    }
  }
}
