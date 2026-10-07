import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES


/// A column's title in the header, which orders the column when it can ([onTap]).
///
/// The arrow goes **beside** the title and not in place of anything: it says which
/// way the rows go (up: smallest first) and is the only mark of which column they
/// are ordered by. A long title gives way to it, not the other way round.
class SummarySortTitle extends StatelessWidget {
  const SummarySortTitle({
    super.key,
    required this.label,
    required this.align,
    this.descending,
    this.onTap
  });

  final String label;
  final TextAlign align;

  /// Which way the rows go by this column, or null if they aren't ordered by it.
  final bool? descending;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = descending != null;

    final title = Row(
      mainAxisAlignment: switch (align) {
        TextAlign.right => MainAxisAlignment.end,
        TextAlign.center => MainAxisAlignment.center,
        _ => MainAxisAlignment.start
      },
      children: [
        Flexible(child: TextSmall(
          label,
          ellipsis: true,
          textAlign: align,
          color: active ? scheme.text.primary : scheme.text.secondary
        )),
        if (active) ...[
          SizedBox(width: AppSize.spaceXS),
          Icon(
            descending! ? CI.arrow_down : CI.arrow_top,
            size: AppSize.text * 0.8,
            color: scheme.text.primary
          )
        ]
      ]
    );

    if (onTap == null) return title;

    return FocusableWidget(
      action: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: title
    );
  }
}
