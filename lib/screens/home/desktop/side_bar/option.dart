import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

class Option extends StatelessWidget {
  const Option({
    required this.icon,
    required this.title,
    required this.action,
    required this.isExpanded,
    this.isActive = false,
    this.isLocked = false,
    this.badge = 0,
    super.key
  });

  final IconData icon;
  final String title;
  final void Function() action;
  final bool isExpanded;
  final bool isActive;

  /// The option is shown but cannot be opened: the section needs an active
  /// business and there is none yet (see `HomeSection.needsBusiness`).
  ///
  /// It is still displayed, dimmed and with a lock, instead of being removed
  /// from the list: that way everything the platform offers is visible from
  /// day one, and the side bar keeps its shape when the first business is
  /// created.
  final bool isLocked;

  final int badge;

  /// The whole set —indicator, icon, text and counter— is dimmed so nothing
  /// in this option competes with the ones that can be opened. It is the only
  /// thing needed besides disabling the gesture: the colors inside remain the
  /// usual ones.
  @override
  Widget build(BuildContext context) => isLocked
    ? Opacity(opacity: 0.4, child: _option(context))
    : _option(context);

  Widget _option(BuildContext context) => Row(children: [
    Row(children: [
      // The indicator always takes up its space, active or not, so the icons
      // of every option line up in the same column.
      Container(
        height: AppSize.action,
        width: 3,
        decoration: BoxDecoration(
          color: isActive
            ? ThemeColor.of(context).accent
            : Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSize.corner),
            bottomRight: Radius.circular(AppSize.corner)
          ),
          // The glow simulates the bar emitting light toward the active option.
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: ThemeColor.of(context).accent.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 1
                ),
                BoxShadow(
                  color: ThemeColor.of(context).accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 3
                )
              ]
            : null
        )
      ),
      SizedBox(
        width: AppSize.padding - 3,
      )
    ]),
    Expanded(child: FeedbackButton(
      // Locked it goes nowhere, and without an action there is no reason for
      // it to respond to the mouse either: the cursor warns that it cannot be
      // opened before the click, and the feedback color is flattened against
      // the background so hovering does not light it up like the others.
      action: isLocked ? null : action,
      mouseCursor: isLocked ? SystemMouseCursors.basic : null,
      message: isLocked ? S.of(context).section_no_business_subtitle : title,
      feedbackColor: isLocked
        ? Colors.transparent
        : ThemeColor.of(context).line,
      // Both ends of the animation must be opaque. `line` is translucent and
      // `Color.lerp` interpolates alpha and RGB separately, so animating the
      // opaque background of a dimmed option toward it goes through mid-alpha
      // colors: the jump seen when clicking. Flattening `line` against the
      // side bar background gives exactly the same color at rest, but keeps
      // the transition moving only in RGB.
      color: isActive
        ? Color.alphaBlend(
            ThemeColor.of(context).line,
            ThemeColor.of(context).navBar
          )
        : ThemeColor.of(context).navBar,
      child: Row(children: [
        SizedBox(
          width: AppSize.action,
          height: AppSize.action,
          child: Center(child: Icon(
            icon,
            color: isActive
              ? ThemeColor.of(context).primary
              : ThemeColor.of(context).text.secondary
          ))
        ),
        if (isExpanded) ...[
          Expanded(child: TextMedium(title, ellipsis: true)),
          // The lock goes where the counter would: they are mutually
          // exclusive, an option that cannot be opened has nothing pending to
          // show.
          if (isLocked) Padding(
            padding: EdgeInsets.only(right: AppSize.spaceXS),
            child: Icon(
              Icons.lock_outline,
              size: AppSize.text * 1.2,
              color: ThemeColor.of(context).text.secondary
            )
          )
          else if (badge > 0) Container(
            margin: EdgeInsets.only(right: AppSize.spaceXS),
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.gap,
              vertical: AppSize.gap / 2
            ),
            decoration: BoxDecoration(
              color: ThemeColor.of(context).primary,
              borderRadius: BorderRadius.circular(AppSize.corner)
            ),
            child: TextSmall("$badge", color: Colors.white)
          )
        ]
      ])
    )),
    SizedBox(width: AppSize.padding)
  ]);
}
