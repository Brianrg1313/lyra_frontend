import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/files/file_model.dart';

/// A person's profile picture, round, and their initials when they have none
/// or it does not download.
class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.name,
    required this.size,
    this.picture
  });

  final String name;
  final double size;
  final FileModel? picture;

  @override
  Widget build(BuildContext context) {
    // A thumbnail covering twice the side: sharp on a dense screen without
    // downloading the original for a row.
    final url = picture?.sized((size * 2).round()) ?? "";

    final face = url.isEmpty
      ? _Initials(name: name, size: size)
      : ClipOval(child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _Initials(name: name, size: size)
        ));

    return SizedBox(width: size, height: size, child: face);
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
