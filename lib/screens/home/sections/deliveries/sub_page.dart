import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Frame of the deliveries sub-pages (settings, area): back to where they are
/// opened from, the title and the page's actions, over a line and the page's
/// body, all on one surface.
class DeliveriesSubPage extends StatelessWidget {
  const DeliveriesSubPage({
    super.key,
    required this.title,
    required this.backPath,
    required this.backLabel,
    required this.child,
    this.actions = const []
  });

  final String title;

  /// Where the arrow goes. A path and not a pop: the page may have been opened
  /// by its link, with nothing under it to go back to.
  final String backPath;

  /// Tooltip of the arrow: the name of where it goes.
  final String backLabel;

  final Widget child;

  /// The page's own actions, right of the title ("Add area").
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      Row(children: [
        FeedbackButton(
          action: () => Navis.push(context, backPath),
          width: AppSize.action,
          height: AppSize.action,
          message: backLabel,
          child: Center(child: Icon(
            CI.arrow_left,
            color: ThemeColor.of(context).text.primary
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
        for (final action in actions) ...[
          SizedBox(width: AppSize.gap),
          action
        ]
      ]),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: child)
    ])
  );
}
