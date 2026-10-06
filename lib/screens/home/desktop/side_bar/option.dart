import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_mark.dart';

class Option extends StatelessWidget {
  const Option({
    required this.icon,
    required this.title,
    required this.action,
    required this.isExpanded,
    this.isActive = false,
    this.lockedMessage,
    this.opensLocked = false,
    this.badge,
    super.key
  });

  final IconData icon;
  final String title;
  final void Function() action;
  final bool isExpanded;
  final bool isActive;

  /// Why the option cannot be opened, shown as its tooltip; `null` = it can.
  /// Either the section needs an active business and there is none yet (see
  /// `HomeSection.needsBusiness`), or the person is not granted its `view` in
  /// the active one (`PermissionsService`).
  ///
  /// It is still displayed, dimmed and with a lock, instead of being removed
  /// from the list: that way everything the platform offers is visible from
  /// day one, and the side bar keeps its shape when the first business is
  /// created or the grant arrives.
  final String? lockedMessage;

  bool get isLocked => lockedMessage != null;

  /// A locked option that still opens: a missing permission leads to the
  /// section's `NoPermissionSection`, where access is requested. Without a
  /// business there is nothing to open, so that lock stays closed.
  final bool opensLocked;

  bool get _isDisabled => isLocked && !opensLocked;

  /// What it has pending (`BadgesService`): a number or a dot after the title, a dot on the
  /// icon while the bar is collapsed.
  final BadgePlace? badge;

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
      action: _isDisabled ? null : action,
      mouseCursor: _isDisabled ? SystemMouseCursors.basic : null,
      message: lockedMessage ?? title,
      feedbackColor: _isDisabled
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
        _icon(context),
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
          else if (badge != null) Padding(
            padding: EdgeInsets.only(right: AppSize.spaceXS),
            child: BadgeMark(place: badge!)
          )
        ]
      ])
    )),
    SizedBox(width: AppSize.padding)
  ]);

  /// Collapsed, the icon is all there is: what is pending goes on it as a dot.
  Widget _icon(BuildContext context) {
    final icon = SizedBox(
      width: AppSize.action,
      height: AppSize.action,
      child: Center(child: Icon(
        this.icon,
        color: isActive
          ? ThemeColor.of(context).primary
          : ThemeColor.of(context).text.secondary
      ))
    );

    if (isExpanded || isLocked || badge == null) return icon;

    return BadgeCorner(place: badge!, dot: true, child: icon);
  }
}
