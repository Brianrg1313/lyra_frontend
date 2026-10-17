import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/modifier_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';

/// One group: its name, how many a line must and may take, its options with their price, and
/// how many products offer it.
class ModifierRow extends StatelessWidget {
  const ModifierRow({super.key, required this.group, required this.onTap});

  final ModifierGroup group;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

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
          SizedBox(height: AppSize.gap),
          TextSmall(
            group.options.map((option) => option.price > 0 ? "${option.name} +${kitchenMoney(option.price)}" : option.name).join(" · "),
            ellipsis: true,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.gap / 2),
          TextSmall(s.supply_chain_modifiers_products(group.products.length), color: scheme.text.secondary)
        ])),
        Icon(CI.arrow_right, size: AppSize.text, color: scheme.text.secondary)
      ])
    );
  }
}

/// How many options a line must and may take, in words: «Choose one», «Up to 3», «Optional».
String modifierRule(BuildContext context, ModifierGroup group) {
  final s = S.of(context);
  final max = group.max;

  if (group.min == 1 && max == 1) return s.supply_chain_modifiers_choose_one;
  if (group.min > 0) return max == null ? s.supply_chain_modifiers_at_least(group.min) : s.supply_chain_modifiers_between(group.min, max);

  return max == null ? s.supply_chain_modifiers_optional : s.supply_chain_modifiers_up_to(max);
}
