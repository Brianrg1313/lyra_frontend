import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// An eligible service of a connection's form: its icon, what it is, and a
/// line on what the account is for once connected.
///
/// It's a card and not a dropdown because choosing the service **is** the
/// screen's decision: a dropdown forces opening it to see what's there, and
/// what's there is exactly what's being decided.
///
/// It goes inside [OptionGrid], which is the one that decides how many fit
/// per row. That's why the card is **small and of fixed height** ([height]):
/// two lines of text and nothing else. What doesn't fit is cut with an
/// ellipsis, and that's fine —the subtitle breaks ties between two similar
/// services, it doesn't document them.
///
/// [enabled] in `false` is the other reason it exists. There are services
/// that **can't be configured yet** —the ones that aren't Meta's— and they're
/// shown anyway, dimmed and with their caption: whoever is connecting an
/// account needs to know that's going to exist. A dimmed option doesn't
/// respond to the tap and reads at a glance as unavailable.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.subtitle,
    this.enabled = true,
    this.badge
  });

  /// Height of all the cards, chosen so the title and two lines of subtitle
  /// fit. It's fixed on purpose: in a grid, cards of different heights in the
  /// same row read as an error.
  static double get height => AppSize.action * 1.7;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// `true` if it's the chosen service. It's just one: the stored credentials
  /// belong to one service, not two.
  final bool selected;

  /// `false` for what can't be chosen yet.
  final bool enabled;

  /// Short caption ("Coming soon"), to say **why** an option is dimmed.
  /// Without this, a grey option looks like an error. It takes the place of
  /// the selected mark, which says nothing in an option that can't be chosen.
  final String? badge;

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = selected && enabled;

    // When dimmed it's drawn with the secondary color in everything, not just
    // the text: the icon and the border have to go with it, or the card will
    // still look eligible.
    final tint = !enabled
      ? scheme.text.secondary
      : selected ? scheme.primary : scheme.icon;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: FeedbackButton(
        // Without an action the widget stops responding to tap and keyboard,
        // which is exactly what has to happen with an unavailable option.
        action: enabled ? action : null,
        mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
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
          // The padding goes here and not in the button: they're the card's only
          // two measures, and together they're where you see if there's air to
          // spare.
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
                if (badge != null) _Badge(text: badge!) else _Mark(selected: active)
              ]),
              if (subtitle != null) ...[
                SizedBox(height: AppSize.gap),
                // Expanded and not a calculated height: the card already measures
                // what it measures, and this way the text keeps whatever's left
                // over without pushing.
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

/// The caption of a dimmed option.
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

/// The selected mark, to the right of the title. Round, which is the
/// convention for "one of these".
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
