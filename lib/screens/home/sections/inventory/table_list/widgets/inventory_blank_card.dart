import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './inventory_start_card.dart';

/// A table with no columns, named in the create modal.
class InventoryBlankCard extends StatelessWidget {
  const InventoryBlankCard({super.key, required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return InventoryStartCard(
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(CI.plus, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(S.of(context).inventory_start_blank, bold: true, ellipsis: true))
          ]),
          SizedBox(height: AppSize.gap),
          TextSmall(S.of(context).inventory_start_blank_hint, color: scheme.text.secondary, lines: 2, ellipsis: true)
        ]
      )
    );
  }
}
