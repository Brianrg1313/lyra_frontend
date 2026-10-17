import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One thing a product can be given: a description, a choice, extras, a column.
typedef MadeAddItem = ({IconData icon, String label, String note, void Function(BuildContext anchor) action});

/// What the form can still hold and doesn't, as a row of tags under the product's name and price: a product starts as a
/// name, a price and what it is made of, and grows only by what is picked here, so the form is
/// never a list of empty fields to skip. A picked tag leaves the row for its section, and comes
/// back when that section is taken off.
class MadeAddBar extends StatelessWidget {
  const MadeAddBar({super.key, required this.title, required this.items});

  final String title;
  final List<MadeAddItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceM),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextSmall(title, bold: true, color: ThemeColor.of(context).text.secondary),
        SizedBox(height: AppSize.gap),
        Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
          for (final item in items) _AddTag(item: item)
        ])
      ])
    );
  }
}

class _AddTag extends StatelessWidget {
  const _AddTag({required this.item});

  final MadeAddItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Builder(builder: (anchor) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner * 2),
        border: Border.all(color: scheme.line)
      ),
      child: FeedbackButton(
        action: () => item.action(anchor),
        message: item.note,
        color: scheme.surface,
        radius: AppSize.corner * 2,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CI.plus, size: AppSize.text * 0.85, color: scheme.primary),
          SizedBox(width: AppSize.gap / 2),
          Icon(item.icon, size: AppSize.text * 0.95, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          TextSmall(item.label)
        ])
      )
    ));
  }
}

/// A section the person added: its title, with the cross that takes it off (and empties it).
class MadeSection extends StatelessWidget {
  const MadeSection({super.key, required this.title, required this.child, this.onRemove});

  final String title;
  final Widget child;
  final void Function()? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: TextSmall(title, bold: true)),
          if (onRemove != null) FocusableWidget(
            action: onRemove,
            message: S.of(context).made_product_section_remove,
            child: Padding(
              padding: EdgeInsets.all(AppSize.gap / 2),
              child: Icon(CI.delete, size: AppSize.text * 0.9, color: scheme.text.secondary)
            )
          )
        ]),
        SizedBox(height: AppSize.gap / 2),
        child
      ])
    );
  }
}
