import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The person's profile picture, round, with the side bar's gradient behind:
/// it shows while the image loads and when there is none, where the initial
/// of [name] goes.
class WelcomeAvatar extends StatelessWidget {
  const WelcomeAvatar({
    super.key,
    required this.name,
    this.picture,
    this.size = 96
  });

  final String name;
  final String? picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = picture;
    final hasImage = image != null && image.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(40)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(50), Colors.white.withAlpha(0)]
        ),
        image: hasImage
          ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
          : null
      ),
      child: hasImage ? null : Center(child: name.isEmpty
        ? Icon(CI.user, size: size * 0.4, color: ThemeColor.of(context).icon)
        : TextLarge(
            name.characters.first.toUpperCase(),
            multiplier: (size * 0.4) / AppSize.text
          ))
    );
  }
}
