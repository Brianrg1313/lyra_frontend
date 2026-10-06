import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// What the section puts in its bar whatever the view: the table selector (it takes what
/// is left, so a long name is cut and not the buttons) and the controls beside it (the
/// table's options, the summary/cells switch).
class InventoryBarParts {
  const InventoryBarParts({required this.selector, required this.controls});

  final Widget selector;
  final List<Widget> controls;
}

/// The inventory section's top bar, drawn by each view of the open table (the summary
/// and the sheet) because what goes on the right is theirs: [status] is what the view is
/// doing (a read, a count, an import) and [actions] what it offers, and both need the
/// view's own services, which live below the section.
class InventoryBar extends StatelessWidget {
  const InventoryBar({
    super.key,
    required this.parts,
    this.status = const [],
    this.actions = const []
  });

  final InventoryBarParts parts;
  final List<Widget> status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.gap),
    child: SizedBox(
      height: AppSize.action,
      child: Row(children: [
        Flexible(child: parts.selector),
        for (final control in parts.controls) ...[
          SizedBox(width: AppSize.gap),
          control
        ],
        Expanded(child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final widget in status) Flexible(child: Padding(
              padding: EdgeInsets.only(left: AppSize.gap),
              child: widget
            ))
          ]
        )),
        for (final action in actions) ...[
          SizedBox(width: AppSize.gap),
          action
        ]
      ])
    )
  );
}
