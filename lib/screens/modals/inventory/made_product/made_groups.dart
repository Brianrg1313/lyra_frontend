import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/kitchen/modifier_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/modifiers/modifier_row.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// The modifier groups a product offers of one kind (`cocina-frontend.md` §6): what the customer
/// must choose (the dough: [ModifierGroup.required]) or may add (the extras). Each one a card
/// with its rule and its options; a tap opens it to edit, the cross stops offering it here.
class MadeGroupsBlock extends StatelessWidget {
  const MadeGroupsBlock({
    super.key,
    required this.title,
    required this.note,
    required this.choices,
    required this.onOpen,
    required this.onDetach,
    this.enabled = true
  });

  final String title;
  final String note;
  final List<MadeGroupChoice> choices;
  final void Function(MadeGroupChoice choice) onOpen;
  final void Function(MadeGroupChoice choice) onDetach;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SizedBox(height: AppSize.spaceM),
    TextMedium(title, bold: true),
    KitchenNote(text: note),
    for (final (index, choice) in choices.indexed) ...[
      if (index > 0) SizedBox(height: AppSize.gap),
      _GroupCard(
        key: ObjectKey(choice.group),
        group: choice.group,
        enabled: enabled,
        onOpen: () => onOpen(choice),
        onDetach: () => onDetach(choice)
      )
    ]
  ]);
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.group,
    required this.enabled,
    required this.onOpen,
    required this.onDetach
  });

  /// Its [ModifierGroup.products] are the others offering it.
  final ModifierGroup group;
  final bool enabled;
  final void Function() onOpen;
  final void Function() onDetach;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final others = group.products.length;

    return FeedbackButton(
      action: onOpen,
      message: s.made_product_group_edit,
      color: scheme.surfaceOver,
      radius: AppSize.corner,
      padding: EdgeInsets.fromLTRB(AppSize.spaceS, AppSize.spaceXS, AppSize.gap, AppSize.spaceXS),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: TextMedium(group.name, bold: true, ellipsis: true)),
            SizedBox(width: AppSize.spaceS),
            TextSmall(modifierRule(context, group), color: group.required ? scheme.accent : scheme.text.secondary)
          ]),
          SizedBox(height: AppSize.gap),
          if (group.options.isEmpty)
            TextSmall(s.made_product_group_options_none, color: scheme.text.secondary)
          else Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap / 2, children: [
            for (final option in group.options) _OptionTag(option: option)
          ]),
          if (others > 0) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: TextSmall(s.made_product_group_shared(others), color: scheme.text.secondary)
          )
        ])),
        if (enabled) FocusableWidget(
          action: onDetach,
          message: s.made_product_group_detach,
          child: Padding(
            padding: EdgeInsets.all(AppSize.gap),
            child: Icon(CI.delete, size: AppSize.text, color: scheme.text.secondary)
          )
        )
      ])
    );
  }
}

/// One option as the customer reads it: its name, and what it adds to the price.
class _OptionTag extends StatelessWidget {
  const _OptionTag({required this.option});

  final ModifierOption option;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.5, vertical: AppSize.gap / 2),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppSize.corner)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        TextSmall(option.name, color: option.paused ? scheme.text.secondary : null),
        if (option.price > 0) ...[
          SizedBox(width: AppSize.gap),
          TextSmall("+${kitchenMoney(option.price)}", bold: true, color: scheme.text.secondary)
        ]
      ])
    );
  }
}
