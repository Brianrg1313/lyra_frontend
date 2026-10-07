import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/summary/stock_summary_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';

/// The section's bar, with how many products the summary has. While reading, how many
/// there are isn't said: during a search the previous number would still be there
/// counting something else.
class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key, required this.parts, required this.status});

  final InventoryBarParts parts;
  final List<Widget> status;

  @override
  Widget build(BuildContext context) {
    final (total, counted) = context.select<StockSummaryService, (int, bool)>(
      (service) => (
        service.total,
        service.status == StockSummaryStatus.ready || service.status == StockSummaryStatus.empty
      )
    );

    return InventoryBar(parts: parts, status: [
      ...status,
      if (counted) TextSmall(
        S.of(context).stock_summary_count(total),
        color: ThemeColor.of(context).text.secondary,
        ellipsis: true
      )
    ]);
  }
}
