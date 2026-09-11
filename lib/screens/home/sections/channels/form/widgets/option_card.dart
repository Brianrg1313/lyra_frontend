import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A selectable option of a channel's form: its icon, what it is and a line
/// about what it is for.
///
/// The page's four selectors use it (the network, the agent's role, the data
/// source and the tools) because the four choose the same kind of thing: one
/// item from a handful, with the subtitle doing the work of explaining the
/// difference. A dropdown would not work: it forces opening it to see what
/// there is, and what there is is exactly what is being decided.
///
/// It goes inside [OptionGrid], which decides how many fit per row. That is
/// why the card is **small and of fixed height** ([height]): two lines of text
/// and nothing more. What does not fit is cut with ellipsis, and it is fine
/// that it is cut —the subtitle breaks the tie between two options, it does
/// not document them.
///
/// [enabled] in `false` is the other reason it exists. There are options that
/// **are not made yet** —the services calendar, the knowledge base, the
/// networks that are not Meta's— and they are shown all the same, disabled and
/// with their caption: whoever is building a channel needs to know that is
/// going to exist so they do not build it twice. A disabled option does not
/// respond to tap and is read at a glance as unavailable.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.subtitle,
    this.enabled = true,
    this.badge,
    this.multiple = false
  });

  /// Height of all the cards, chosen so the title and two lines of subtitle
  /// fit. It is fixed on purpose: in a grid, cards of different heights in the
  /// same row read like an error.
  static double get height => AppSize.action * 1.7;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// `true` if it is selected. In the tools ([multiple]) there can be several
  /// at once; in the rest, a single one.
  final bool selected;

  /// `false` for what cannot be chosen yet.
  final bool enabled;

  /// Short caption ("Coming soon"), to say **why** an option is disabled.
  /// Without this, a grey option looks like an error. It takes the place of
  /// the selected mark, which in an option that cannot be chosen says nothing.
  final String? badge;

  /// Changes the mark: a check when several can be chosen, a dot when it is a
  /// single one. It is the only clue of whether choosing this one replaces
  /// the previous.
  final bool multiple;

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = selected && enabled;

    // Disabled is drawn with the secondary color everywhere, not only in the
    // text: the icon and the border have to go with it, or the card still
    // looks selectable.
    final tint = !enabled
      ? scheme.text.secondary
      : selected ? scheme.primary : scheme.icon;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: FeedbackButton(
        // Without an action the widget stops responding to tap and keyboard,
        // which is exactly what has to happen with an unavailable option.
        action: enabled ? action : null,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        color: scheme.surfaceOver,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? scheme.primary : Colors.transparent,
              width: 1.5
            ),
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          // The padding goes here and not on the button: they are the card's only
          // two measures, and together are where extra air shows.
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.spaceXS,
            vertical: AppSize.gap * 1.5
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: AppSize.text * 1.2, color: tint),
                SizedBox(width: AppSize.gap),
                Expanded(child: TextMedium(
                  title,
                  ellipsis: true,
                  bold: active
                )),
                SizedBox(width: AppSize.gap),
                if (badge != null)
                  _Badge(text: badge!)
                else
                  _Mark(selected: active, multiple: multiple)
              ]),
              if (subtitle != null) ...[
                SizedBox(height: AppSize.gap),
                // Expanded and not a computed height: the card already measures what it
                // measures, and so the text keeps what is left over without
                // pushing.
                Expanded(child: TextSmall(
                  subtitle!,
                  lines: 2,
                  ellipsis: true,
                  color: scheme.text.secondary
                ))
              ]
            ]
          )
        )
      )
    );
  }
}

/// The caption of a disabled option.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.3
      ),
      decoration: BoxDecoration(
        color: scheme.text.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(text, ellipsis: true, color: scheme.text.secondary)
    );
  }
}

/// The selected mark, to the right of the title.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.multiple});

  final bool selected;
  final bool multiple;

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
        // Squared with rounded corners for several, round for a single one: it
        // is the usual convention and is understood without reading anything.
        borderRadius: BorderRadius.circular(multiple ? AppSize.gap : size)
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
