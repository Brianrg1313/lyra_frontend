import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './coverage_block.dart';
import './pending_list.dart';

/// The panel over the desk's map: what the section is, where the company
/// delivers (`CoverageBlock`, scrolling when the branches are many), and the
/// deliveries still on their way at its foot.
class DeliveriesPanel extends StatelessWidget {
  const DeliveriesPanel({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextLarge(S.of(context).deliveries, ellipsis: true),
      SizedBox(height: AppSize.gap * 0.5),
      TextSmall(
        S.of(context).deliveries_subtitle,
        lines: 2,
        ellipsis: true,
        color: ThemeColor.of(context).text.secondary
      ),
      SizedBox(height: AppSize.spaceS),
      const Expanded(child: ScrollableWidget(
        showBar: false,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [CoverageBlock()]
      )),
      Separator.horizontal(margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)),
      const PendingDeliveries()
    ]
  );
}
