import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/lan_image.dart';

/// The image of a business: its logo if it has one, and otherwise the
/// gradient avatar with the initial of its name.
///
/// It lives up here and not inside the selector or the card because a business
/// is drawn the same in both, only bigger in one than in the other. When a
/// business's avatar changes —another shape, another gradient— it has to
/// change everywhere at once, and that only happens if it is the same widget.
///
/// [url] is the already built address of the logo: the one that has the file
/// builds it, putting its id after the base that `/init` delivered (see
/// `FileModel`). Without it —empty because the business did not upload any, or
/// because the base has not arrived yet— and also if it cannot be downloaded,
/// the avatar is drawn.
class BusinessAvatar extends StatelessWidget {
  const BusinessAvatar({
    super.key,
    required this.name,
    required this.size,
    this.url
  });

  final String name;
  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final logo = url;

    if (logo == null || logo.isEmpty) return _fallback(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSize.corner),
      child: Image(
        image: mediaImage(logo),
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A logo that does not download is not an error worth a banner: the business
        // is still recognized by its initial, just like before uploading it.
        errorBuilder: (context, error, stack) => _fallback(context)
      )
    );
  }

  /// The gradient avatar with the initial. Without a name —a newly created
  /// business that has not been read yet— the store icon goes.
  Widget _fallback(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSize.corner),
      border: Border(
        top: BorderSide(color: Colors.white.withAlpha(40)),
        left: BorderSide(color: Colors.white.withAlpha(40))
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withAlpha(50), Colors.white.withAlpha(0)]
      )
    ),
    child: Center(child: name.isEmpty
      ? Icon(CI.store, size: size * 0.4, color: ThemeColor.of(context).icon)
      // The initial is measured against the avatar and not against the app text:
      // the same widget is drawn at 44 in a row and 72 in the profile, and with
      // a fixed body it would look tiny in the big one.
      : TextLarge(
        name.characters.first.toUpperCase(),
        multiplier: (size * 0.4) / AppSize.text
      ))
  );
}
