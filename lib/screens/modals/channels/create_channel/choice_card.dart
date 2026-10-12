import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One answer of a create step, as a full-width card: its icon, its name and
/// one line saying what it means, with a mark on the right.
///
/// Larger than the form's `OptionChip` on purpose: on a page that asks a
/// single question there is room to explain each answer where it is picked,
/// which is what someone new to this needs. [multiple] draws a square mark
/// (several can be kept) instead of a round one; [enabled] false fades it and
/// shows [badge] ("Soon").
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.detail,
    this.multiple = false,
    this.enabled = true,
    this.badge
  });

  final IconData icon;
  final String title;
  final String? detail;
  final bool selected;
  final bool multiple;
  final bool enabled;
  final String? badge;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = selected && enabled;
    final tint = active ? scheme.primary : scheme.icon;
    final detail = this.detail;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap * 1.5),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: FeedbackButton(
          action: enabled ? action : null,
          mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          color: active
            ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.12), scheme.surfaceOver)
            : scheme.surfaceOver,
          width: double.infinity,
          child: Container(
            padding: EdgeInsets.all(AppSize.spaceXS),
            decoration: BoxDecoration(
              border: Border.all(color: active ? scheme.primary : scheme.line, width: 1.5),
              borderRadius: BorderRadius.circular(AppSize.corner)
            ),
            child: Row(children: [
              Container(
                width: AppSize.button,
                height: AppSize.button,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.spaceXS))
                ),
                child: Icon(icon, size: AppSize.text * 1.4, color: tint)
              ),
              SizedBox(width: AppSize.spaceXS),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextMedium(title, bold: true, ellipsis: true),
                  if (detail != null && detail.isNotEmpty) Padding(
                    padding: EdgeInsets.only(top: AppSize.gap * .5),
                    child: TextSmall(detail, lines: 2, ellipsis: true, color: scheme.text.secondary)
                  )
                ]
              )),
              SizedBox(width: AppSize.spaceXS),
              if (badge != null)
                TextSmall(badge!, color: scheme.text.secondary)
              else
                _Mark(selected: active, multiple: multiple)
            ])
          )
        )
      )
    );
  }
}

/// Round for one answer, square for several; filled with a check once picked.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.multiple});

  final bool selected;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 1.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : null,
        border: Border.all(color: selected ? scheme.primary : scheme.line, width: 1.5),
        borderRadius: BorderRadius.circular(multiple ? AppSize.gap : size)
      ),
      child: selected
        ? Icon(CI.check, size: size * .65, color: scheme.button.text)
        : null
    );
  }
}
