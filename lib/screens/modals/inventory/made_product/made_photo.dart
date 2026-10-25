import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/files/image_file.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/toolkit/lan/image.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/image_viewer/_image_viewer.dart';

/// The product's photo, the first thing of the form: what it looks like is how a person finds it
/// in the till and in the catalog. A tap on an empty one picks a file; on one with a photo, it
/// offers to see it, change it or take it off.
///
/// It uploads nothing: what was picked is held as a [MadePhoto] until the form saves, since a
/// new product has no record to upload against yet.
class MadePhotoTile extends StatelessWidget {
  const MadePhotoTile({
    super.key,
    required this.cover,
    required this.photo,
    required this.onChanged,
    this.enabled = true
  });

  /// What it has saved.
  final ProductImage? cover;

  /// What the form will do with it.
  final MadePhoto photo;
  final void Function(MadePhoto photo) onChanged;
  final bool enabled;

  static const double size = 116;

  /// What the tile draws: the picked bytes, else the saved cover unless it is being removed.
  bool get _has => photo.bytes != null || (cover != null && !photo.remove);

  Future<void> _open(BuildContext anchor) async {
    if (!_has) return _pick(anchor);

    final s = S.of(anchor);
    final picked = await showSelectMenu(
      context: anchor,
      dense: true,
      options: [
        if (photo.bytes == null) SelectOption(value: "view", placeholder: s.product_table_view_image_view, icon: CI.eye),
        SelectOption(value: "change", placeholder: s.made_product_photo_change, icon: CI.edit_image),
        SelectOption(value: "remove", placeholder: s.made_product_photo_remove, icon: CI.remove_image)
      ]
    );

    if (picked == null || !anchor.mounted) return;

    switch (picked.value) {
      case "view":
        await showImageViewer(anchor, url: cover!.url);
      case "change":
        await _pick(anchor);
      case "remove":
        onChanged(cover == null ? const MadePhoto.keep() : const MadePhoto.remove());
    }
  }

  Future<void> _pick(BuildContext anchor) async {
    final s = S.of(anchor);
    final bytes = await pickImageBytes(label: s.made_product_photo_files);

    if (bytes == null || !anchor.mounted) return;

    // The limit is the backend's multipart one: said here, before the whole trip.
    if (bytes.length > kImageMaxBytes) {
      FloatFlag.of(anchor).error(message: s.made_product_photo_large);
      return;
    }

    onChanged(MadePhoto.replace(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final radius = AppSize.corner * 1.5;

    return Builder(builder: (anchor) => SizedBox(
      width: size,
      height: size,
      child: FeedbackButton(
        action: enabled ? () => _open(anchor) : null,
        message: _has ? s.made_product_photo_change : s.made_product_photo_add,
        color: scheme.surfaceOver,
        radius: radius,
        child: _has
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _Picture(bytes: photo.bytes, cover: cover, empty: _empty(context))
            )
          : _empty(context)
      )
    ));
  }

  Widget _empty(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner * 1.5),
        border: Border.all(color: scheme.line, width: 1.5)
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(CI.add_image, size: AppSize.text * 1.6, color: scheme.text.secondary),
        SizedBox(height: AppSize.gap),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
          child: TextSmall(S.of(context).made_product_photo_add, color: scheme.text.secondary, textAlign: TextAlign.center, lines: 2)
        )
      ])
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.bytes, required this.cover, required this.empty});

  final Uint8List? bytes;
  final ProductImage? cover;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final picked = bytes;

    if (picked != null) {
      return Image.memory(picked, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    return Image(
      image: mediaImage(cover!.thumbnail),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => empty
    );
  }
}
