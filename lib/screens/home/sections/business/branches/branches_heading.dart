import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// What the tab is, one line that says what it is for, and its one action.
///
/// Without [onAdd] no button is drawn: a list that could not be read does not
/// offer to grow.
class BranchesHeading extends StatelessWidget {
  const BranchesHeading({super.key, this.onAdd});

  final void Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextMedium(S.of(context).business_branches_title, bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              S.of(context).business_branches_subtitle,
              lines: 2,
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        )),
        if (onAdd != null) ...[
          SizedBox(width: AppSize.spaceS),
          Button(
            width: null,
            title: S.of(context).business_branches_add,
            leftIcon: Icon(CI.plus, color: scheme.button.text),
            action: onAdd!
          )
        ]
      ]
    );
  }
}
