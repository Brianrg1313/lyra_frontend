import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A network to connect, as a square tile with its mark large.
///
/// The one large thing in the form on purpose: the network is the decision
/// everything else follows from (the credentials are its own), and it is
/// recognised by its logo faster than by its name. The rest of the rows are
/// [OptionChip]s, a button tall.
class NetworkTile extends StatelessWidget {
  const NetworkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.enabled = true
  });

  final IconData icon;
  final String title;
  final bool selected;

  /// False on edit: the network is shown, not offered.
  final bool enabled;
  final void Function() action;

  static double get width => AppSize.action * 2.6;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final tint = selected ? scheme.primary : scheme.icon;

    return FeedbackButton(
      action: enabled ? action : null,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      color: selected
        ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.12), scheme.surfaceOver)
        : scheme.surfaceOver,
      width: width,
      height: AppSize.action * 2.1,
      child: Container(
        padding: EdgeInsets.all(AppSize.gap * 1.5),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? scheme.primary : scheme.line,
            width: 1.5
          ),
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSize.action * 0.6, color: tint),
            SizedBox(height: AppSize.gap * 1.5),
            TextSmall(
              title,
              bold: selected,
              lines: 2,
              ellipsis: true,
              textAlign: TextAlign.center
            )
          ]
        )
      )
    );
  }
}
