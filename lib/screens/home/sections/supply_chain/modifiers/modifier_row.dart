import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/modifier_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';

/// One group: its name, how many a line must and may take, its options as the till offers them
/// (each a chip, its price beside its name), and at the right edge how many products offer it.
class ModifierRow extends StatelessWidget {
  const ModifierRow({super.key, required this.group, required this.onTap});

  /// Options drawn before «+N more»: a group's chips stay on one line at a desktop width.
  static const int _shown = 5;

  final ModifierGroup group;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final hidden = group.options.length - _shown;

    return FeedbackButton(
      action: onTap,
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: TextMedium(group.name, ellipsis: true, bold: true)),
            SizedBox(width: AppSize.spaceS),
            RecipeTag(text: modifierRule(context, group), color: group.required ? scheme.accent : scheme.text.secondary)
          ]),
          if (group.options.isNotEmpty) ...[
            SizedBox(height: AppSize.gap * 1.5),
            Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
              for (final option in group.options.take(_shown)) _OptionChip(option: option),
              if (hidden > 0) _Plate(child: TextSmall(s.made_product_lines_more(hidden), multiplier: 0.85, color: scheme.text.secondary))
            ])
          ]
        ])),
        SizedBox(width: AppSize.spaceS),
        TextSmall(
          s.supply_chain_modifiers_products(group.products.length),
          textAlign: TextAlign.end,
          color: group.products.isEmpty ? scheme.snackBar.alert : scheme.text.secondary
        ),
        SizedBox(width: AppSize.spaceS),
        Icon(CI.arrow_right, size: AppSize.text, color: scheme.text.secondary)
      ])
    );
  }
}

/// One option as the till offers it: its name, and what it adds to the price when it does.
class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.option});

  final ModifierOption option;

  @override
  Widget build(BuildContext context) => _Plate(child: Row(mainAxisSize: MainAxisSize.min, children: [
    Flexible(child: TextSmall(option.name, multiplier: 0.85, ellipsis: true)),
    if (option.price > 0) ...[
      SizedBox(width: AppSize.gap),
      TextSmall("+${kitchenMoney(option.price)}", multiplier: 0.85, bold: true, color: ThemeColor.of(context).accent)
    ]
  ]));
}

/// The plate an option (or the «+N more») sits on: the row's surface sunk, not a second card.
class _Plate extends StatelessWidget {
  const _Plate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.5, vertical: AppSize.gap / 2),
    decoration: BoxDecoration(
      color: ThemeColor.of(context).surface,
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: child
  );
}

/// How many options a line must and may take, in words: «Choose one», «Up to 3», «Optional».
String modifierRule(BuildContext context, ModifierGroup group) {
  final s = S.of(context);
  final max = group.max;

  if (group.min == 1 && max == 1) return s.supply_chain_modifiers_choose_one;
  if (group.min > 0) return max == null ? s.supply_chain_modifiers_at_least(group.min) : s.supply_chain_modifiers_between(group.min, max);

  return max == null ? s.supply_chain_modifiers_optional : s.supply_chain_modifiers_up_to(max);
}
