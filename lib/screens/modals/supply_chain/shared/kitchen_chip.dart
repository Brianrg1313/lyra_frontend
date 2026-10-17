import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A picked product, with the cross that takes it off (none when read only).
class KitchenChip extends StatelessWidget {
  const KitchenChip({super.key, required this.label, this.onRemove});

  final String label;
  final void Function()? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: TextSmall(label, ellipsis: true)),
      if (onRemove != null) ...[
        SizedBox(width: AppSize.gap),
        Icon(CI.delete, size: AppSize.text * 0.9, color: scheme.text.secondary)
      ]
    ]);
    final padding = EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap);

    if (onRemove == null) return Surface.over(padding: padding, child: content);

    return FeedbackButton(action: onRemove!, color: scheme.surfaceOver, padding: padding, child: content);
  }
}
