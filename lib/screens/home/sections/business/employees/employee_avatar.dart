import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/files/file_model.dart';

/// A person's profile picture, round, and their initials when they have none
/// or it does not download.
///
/// [status] paints a dot on the lower edge: the list reads where everyone is
/// from it before reading any tag. A ring of the panel's color separates it
/// from the picture, which can be of any color.
class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.name,
    required this.size,
    this.picture,
    this.status,
    this.ring
  });

  final String name;
  final double size;
  final FileModel? picture;
  final Color? status;

  /// Color behind the avatar, for the dot's ring. Defaults to the sheet's.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    // A thumbnail covering twice the side: sharp on a dense screen without
    // downloading the original for a row.
    final url = picture?.sized((size * 2).round()) ?? "";
    final dot = size * 0.28;

    final face = url.isEmpty
      ? _Initials(name: name, size: size)
      : ClipOval(child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _Initials(name: name, size: size)
        ));

    if (status == null) return SizedBox(width: size, height: size, child: face);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        face,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: status,
              shape: BoxShape.circle,
              border: Border.all(color: ring ?? scheme.surface, width: dot * 0.2)
            )
          )
        )
      ])
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final initials = name
      .split(RegExp(r"\s+"))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
        ? Icon(CI.user, size: size * 0.45, color: scheme.primary)
        : TextMedium(
            initials,
            bold: true,
            multiplier: (size * 0.36) / AppSize.text,
            color: scheme.primary
          )
    );
  }
}
