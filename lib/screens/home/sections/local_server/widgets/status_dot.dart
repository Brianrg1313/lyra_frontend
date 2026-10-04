import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Whether something answers now: filled in `primary` when it does, an outline when it
/// doesn't. The same mark for a device of the list and for the session's online side, so the
/// section reads its states one way.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? scheme.primary : null,
        border: on ? null : Border.all(color: scheme.subtitle, width: 1.5)
      )
    );
  }
}
