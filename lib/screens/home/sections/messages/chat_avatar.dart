import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './chat_format.dart';

/// The customer's initials in a circle. WhatsApp does not hand the profile
/// picture over, so there is no image to show.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.title, this.size});

  final String title;

  /// Diameter; defaults to [AppSize.action].
  final double? size;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final side = size ?? AppSize.action;
    final initials = chatInitials(title);

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
        ? Icon(CI.user, size: side * 0.45, color: scheme.primary)
        : TextMedium(
            initials,
            bold: true,
            multiplier: side / AppSize.action,
            color: scheme.primary
          )
    );
  }
}
