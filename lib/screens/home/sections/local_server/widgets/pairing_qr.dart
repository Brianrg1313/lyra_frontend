import 'package:flutter/material.dart';

// PACKAGES
import 'package:qr/qr.dart';

/// The master's pairing QR (`PairingOffer`), for a phone's camera to read off this screen.
///
/// Always dark modules on a white quiet zone, whatever the theme: many scanners don't read an
/// inverted code, so these two colors are deliberately not `ThemeColor`s.
class PairingQr extends StatelessWidget {
  const PairingQr({super.key, required this.data, this.size = 220});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _QrPainter(QrImage(QrCode(payload: QrPayload.fromString(data)))))
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  /// Four modules of white around the code, as the QR standard asks.
  static const _quiet = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount + _quiet * 2;
    final module = size.shortestSide / count;
    final dark = Paint()..color = const Color(0xFF000000);

    canvas.drawRect(Offset.zero & Size.square(module * count), Paint()..color = const Color(0xFFFFFFFF));

    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (!image.isDark(row, col)) continue;
        // A hair wider than a module, so no seams show between neighbours.
        canvas.drawRect(Rect.fromLTWH((col + _quiet) * module, (row + _quiet) * module, module + 0.5, module + 0.5), dark);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}
