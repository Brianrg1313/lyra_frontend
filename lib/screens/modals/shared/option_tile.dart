import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One of a few options laid side by side that exclude each other, each saying what picking it
/// means before it is picked: how a made product is made (to order / by the batch), what a new
/// menu starts with.
class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.title, required this.note, required this.selected, required this.action});

  final String title;
  final String note;
  final bool selected;

  /// Null draws it read only.
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner),
        border: Border.all(color: selected ? scheme.primary : scheme.line, width: 1.5)
      ),
      child: FeedbackButton(
        action: action,
        color: selected ? scheme.surfaceOver : scheme.surface,
        radius: AppSize.corner,
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(selected ? CI.chack_circle : CI.circle, size: AppSize.text * 1.1, color: selected ? scheme.primary : scheme.text.secondary),
          SizedBox(width: AppSize.gap),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextSmall(title, bold: true),
            SizedBox(height: AppSize.gap / 2),
            TextSmall(note, lines: 4, color: scheme.text.secondary)
          ]))
        ])
      )
    );
  }
}
