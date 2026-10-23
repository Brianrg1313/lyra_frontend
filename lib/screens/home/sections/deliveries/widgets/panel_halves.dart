import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One control split in equal parts, the one on filled: what the desk's panel
/// shows (shipments or areas).
///
/// [onChanged] `null` shows it without letting it change.
class PanelHalves<T> extends StatelessWidget {
  const PanelHalves({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.icon
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final IconData Function(T value)? icon;
  final void Function(T value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.all(AppSize.gap * 0.5),
      decoration: BoxDecoration(
        color: scheme.surfaceOver,
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(children: [
        for (final value in values)
          Expanded(child: _Half(
            label: label(value),
            icon: icon?.call(value),
            on: value == selected,
            onTap: onChanged == null || value == selected ? null : () => onChanged!(value)
          ))
      ])
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({required this.label, required this.icon, required this.on, required this.onTap});

  final String label;
  final IconData? icon;
  final bool on;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = on ? scheme.button.text : scheme.text.primary;

    return FeedbackButton(
      action: onTap,
      mouseCursor: onTap == null ? SystemMouseCursors.basic : null,
      height: AppSize.button * 0.85,
      radius: AppSize.corner - AppSize.gap * 0.5,
      color: on ? scheme.primary : Colors.transparent,
      feedbackColor: on ? scheme.primary : scheme.surfaceFeedback,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSize.text, color: color),
            SizedBox(width: AppSize.gap)
          ],
          Flexible(child: TextSmall(label, bold: on, ellipsis: true, color: color))
        ]
      )
    );
  }
}
