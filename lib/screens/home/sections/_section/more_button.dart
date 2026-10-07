import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// The end of a paged list (payments, receivables, sales): the button that
/// brings the next page, or retries it when it failed.
///
/// It is a button and not an infinite scroll because the tables virtualize
/// their own rows and do not report where their scroll is: asking for the next
/// page as the last row appears would mean reaching inside them for a position
/// they deliberately do not hand out.
class SectionMoreButton extends StatelessWidget {
  const SectionMoreButton({
    super.key,
    required this.label,
    required this.retryLabel,
    required this.failed,
    required this.onMore,
    required this.onRetry
  });

  /// What the next page brings ("12 more"), or just "more" where what is left
  /// is not known.
  final String label;
  final String retryLabel;

  /// The last page failed: the button retries it instead.
  final bool failed;

  final void Function() onMore;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSize.gap),
    child: Center(child: SizedBox(
      width: AppSize.action * 5,
      child: Button(
        title: failed ? retryLabel : label,
        action: failed ? onRetry : onMore
      )
    ))
  );
}
