import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One of the things that can happen to the units of a movement, drawn as an
/// selectable row.
///
/// It is a row and not a grid card (like the ones of a channel form) because
/// what breaks the tie between these options is the line below —that some
/// units leave, are set aside or come in as a return looks quite similar
/// written in two words— and a full sentence needs the width of the modal, not
/// a third of it.
///
/// A dropdown did not work either: it forces opening it to see what is there,
/// and what is there is precisely what is being decided.
///
/// [enabled] in `false` is for what cannot be done today: taking from a
/// counter that is at zero. The option is shown the same and dimmed, because
/// its absence would be read as if the system did not contemplate it.
class MovementOption extends StatelessWidget {
  const MovementOption({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.hint,
    this.enabled = true
  });

  final IconData icon;
  final String title;
  final String? hint;

  final bool selected;
  final bool enabled;

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = selected && enabled;

    // Dimmed it goes grey all over —icon, border and text—: with the icon
    // still in color, the option keeps looking selectable.
    final tint = !enabled
      ? scheme.text.secondary
      : selected ? scheme.primary : scheme.icon;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: FeedbackButton(
        // Without an action it stops responding to tap and keyboard, which is
        // what has to happen with an option that cannot be chosen.
        action: enabled ? action : null,
        mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
        color: scheme.surfaceOver,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? scheme.primary : Colors.transparent,
              width: 1.5
            ),
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.spaceXS,
            vertical: AppSize.gap * 1.5
          ),
          child: Row(children: [
            Icon(icon, size: AppSize.text * 1.2, color: tint),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextMedium(title, ellipsis: true, bold: active),
                if (hint != null) ...[
                  SizedBox(height: AppSize.gap * 0.5),
                  TextSmall(
                    hint!,
                    lines: 2,
                    ellipsis: true,
                    color: scheme.text.secondary
                  )
                ]
              ]
            )),
            SizedBox(width: AppSize.spaceXS),
            _Mark(selected: active)
          ])
        )
      )
    );
  }
}

/// The selected mark: round, which is the "one of these" convention.
///
/// It is the same one the option cards of a channel form carry and the same
/// checkbox the settings of a table use, with the only difference of the
/// curve: there each one turns on and off on its own and goes square.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 1.2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: selected ? scheme.primary : scheme.line,
          width: 1.5
        ),
        borderRadius: BorderRadius.circular(size)
      ),
      child: selected
        ? Center(child: Icon(
            CI.check,
            size: size * 0.65,
            color: scheme.button.text
          ))
        : null
    );
  }
}