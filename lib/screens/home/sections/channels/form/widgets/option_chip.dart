import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One option of a [ChannelFormRow]: an icon and its name, a button tall and
/// as wide as its words, so a row of them reads in one sweep.
///
/// What tells options apart is no longer written on each one: the row's note
/// explains the chosen one. [detail] is for the case a name alone cannot
/// settle — two payment accounts of the same rail.
///
/// Selected, it takes the primary colour on its fill, border and icon; with
/// [multiple] the icon turns into a check, the only clue that picking it keeps
/// the others. Disabled ([enabled] false) it fades and carries [badge]
/// ("Soon"): an option that is coming is shown so nobody builds it twice.
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.detail,
    this.enabled = true,
    this.badge,
    this.multiple = false
  });

  final IconData icon;
  final String title;
  final String? detail;
  final bool selected;
  final bool enabled;
  final String? badge;
  final bool multiple;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = selected && enabled;
    final tint = !enabled
      ? scheme.text.secondary
      : active ? scheme.primary : scheme.icon;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: FeedbackButton(
        action: enabled ? action : null,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        color: active
          ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.12), scheme.surfaceOver)
          : scheme.surfaceOver,
        height: AppSize.button,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? scheme.primary : scheme.line,
              width: 1.5
            ),
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active && multiple ? CI.check : icon, size: AppSize.text * 1.2, color: tint),
              SizedBox(width: AppSize.gap),
              Flexible(child: TextSmall(title, bold: active, ellipsis: true)),
              if (detail != null && detail!.isNotEmpty) ...[
                SizedBox(width: AppSize.gap),
                Flexible(child: TextSmall(detail!, ellipsis: true, color: scheme.text.secondary))
              ],
              if (badge != null) ...[
                SizedBox(width: AppSize.gap),
                TextSmall(badge!, color: scheme.text.secondary)
              ]
            ]
          )
        )
      )
    );
  }
}

/// The chips of a row, wrapping onto as many lines as they need.
class OptionChips extends StatelessWidget {
  const OptionChips({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSize.gap,
    runSpacing: AppSize.gap,
    children: children
  );
}
