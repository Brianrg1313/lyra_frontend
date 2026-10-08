import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Body of the detail panel, under the person's bar: a person's index, or one
/// part of their card with the arrow back to it and its title. Whose card it
/// is, is the bar's, so a page names only itself.
///
/// The body keeps a reading width from the left, under the bar's name: rows of
/// settings stretched across a wide panel lose the eye between their name and
/// their arrow.
///
/// The panel's surface and bar are the section's, not this: they stay put
/// while its pages swap under them.
class EmployeePage extends StatelessWidget {
  const EmployeePage({
    super.key,
    required this.child,
    this.title,
    this.backLabel,
    this.onBack,
    this.scroll = true
  });

  /// Without it there is no arrow and no title: the body starts at the top.
  final String? title;

  /// Tooltip of the arrow: the name of where it goes.
  final String? backLabel;

  /// A navigation to a path and not a pop: the page may have been opened by
  /// its link, with nothing under it to go back to.
  final void Function()? onBack;

  final Widget child;

  /// Off for a body that scrolls a part of itself and keeps the rest put (the
  /// permissions' search and footer).
  final bool scroll;

  static double get width => AppSize.action * 20;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final heading = title != null;
    final inset = EdgeInsets.fromLTRB(AppSize.spaceM, heading ? AppSize.spaceXS : AppSize.spaceM, AppSize.spaceM, AppSize.spaceM);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (heading) Padding(
        // The arrow's own box insets its icon: pulled out by as much, the
        // icon lines up with the bar's picture above.
        padding: EdgeInsets.fromLTRB(AppSize.spaceM - AppSize.spaceXS, AppSize.spaceXS, AppSize.spaceM, 0),
        child: Row(children: [
          if (onBack != null) FeedbackButton(
            action: onBack!,
            width: AppSize.action,
            height: AppSize.action,
            message: backLabel,
            child: Center(child: Icon(CI.arrow_left, color: scheme.text.primary))
          ),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextLarge(title!, multiplier: 1.5, ellipsis: true))
        ])
      ),
      Expanded(child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: scroll
            ? ScrollableWidget(
                padding: inset,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [child]
              )
            : Padding(padding: inset, child: child)
        )
      ))
    ]);
  }
}
