import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/toolkit/lan_image.dart';

/// The product's thumbnail, which is how a person recognizes it.
///
/// The thumbnail is drawn and not the photo: the backend renders a 320px one on
/// upload ([kProductImageWidth]) and this measures what an icon measures.
/// Asking for the big one would be downloading megabytes per row to draw a
/// little square.
///
/// A product without a photo —or a photo that no longer resolves— doesn't leave
/// a hole: the same box with the section's icon is seen, so the strip of photos
/// stays an even strip.
class SummaryPicture extends StatelessWidget {
  const SummaryPicture({super.key, required this.row});

  final StockSummaryRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final cover = row.cover;
    final radius = AppSize.cornerInset(AppSize.gap);

    return Surface(
      width: double.infinity,
      height: double.infinity,
      radius: radius,
      color: scheme.surface,
      child: cover == null
        ? _empty(scheme)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image(
              image: mediaImage(cover.thumbnail),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stack) => _empty(scheme)
            )
          )
    );
  }

  Widget _empty(SchemeColor scheme) => Center(child: Icon(
    CI.shop,
    size: AppSize.text * 1.1,
    color: scheme.text.secondary
  ));
}
