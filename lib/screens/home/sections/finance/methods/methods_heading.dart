import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// Width of every card of the tab, the accounts' and the currencies': the two
/// halves line up as one grid. Wide enough for a bank account number without
/// wrapping it, which is the one string on these cards that must be readable in
/// one piece.
const double kMoneyCardWidth = 320;

/// The heading of each half of the payment methods tab: what it is, one line
/// that says what it is for, and its one action.
///
/// The action sits on the heading and not at the bottom of the grid: the grid
/// grows, and a button that moves down with every card is one that has to be
/// looked for.
class MethodsHeading extends StatelessWidget {
  const MethodsHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction
  });

  final String title;
  final String subtitle;

  /// Without a label (or an action) no button is drawn: a half that cannot be
  /// added to right now —its read failed— does not offer it.
  final String? actionLabel;
  final void Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextMedium(title, bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              subtitle,
              lines: 2,
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        )),
        if (actionLabel != null && onAction != null) ...[
          SizedBox(width: AppSize.spaceS),
          Button(
            width: null,
            title: actionLabel,
            leftIcon: Icon(CI.plus, color: scheme.button.text),
            action: onAction!
          )
        ]
      ]
    );
  }
}
