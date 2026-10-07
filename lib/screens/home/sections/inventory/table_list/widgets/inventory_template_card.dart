import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_template_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/table_dot.dart';

import './inventory_start_card.dart';

/// One starting table: its colour, name, what it's for, and the columns it comes with.
class InventoryTemplateCard extends StatelessWidget {
  const InventoryTemplateCard({super.key, required this.template, required this.loading, required this.action});

  final TableTemplateModel template;
  final bool loading;
  final void Function()? action;

  /// How many columns the card names before "and N more".
  static const _shown = 5;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final names = template.fields.map((field) => field.name).toList();
    final extra = names.length - _shown;

    return InventoryStartCard(
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TableDot(color: template.color),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(template.name, bold: true, ellipsis: true)),
            if (loading) SizedBox(
              width: AppSize.text,
              height: AppSize.text,
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.text.secondary)
            )
          ]),
          if (template.description.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(template.description, color: scheme.text.secondary, lines: 2, ellipsis: true)
          ],
          if (names.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceS),
            TextSmall(
              extra > 0
                ? S.of(context).inventory_template_columns_more(names.take(_shown).join(" · "), extra)
                : names.join(" · "),
              lines: 2,
              ellipsis: true
            )
          ]
        ]
      )
    );
  }
}
