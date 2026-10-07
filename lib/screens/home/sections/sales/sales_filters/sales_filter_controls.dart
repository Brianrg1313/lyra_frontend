import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/filter_chip.dart';

import './sales_channel_filter.dart';
import './sales_pending.dart';
import './sales_stage_filter.dart';

/// What narrows the board, at the right end of the bar.
///
/// **It scrolls from the right rather than wrapping or overflowing.** The bar
/// is one row, the labels are the backend's, and a window narrow enough turns
/// four controls into five when something is filtered — so the strip is
/// anchored at its right edge (`reverse`) and gives way leftwards. Where there
/// is room, which is every desktop, the scroll never moves and the controls sit
/// flush right.
class SalesFilterControls extends StatelessWidget {
  const SalesFilterControls({super.key, required this.service, required this.catalog});

  final SalesService service;
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    // Zero is the right end, which is both where the strip starts and where it
    // stays: the last control is the one that must never be the one cut off.
    reverse: true,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (service.pending > 0) ...[
        SalesPending(service: service),
        SizedBox(width: AppSize.gap)
      ],
      SalesStageFilter(service: service, catalog: catalog),
      SizedBox(width: AppSize.gap),
      SalesChannelFilter(service: service, catalog: catalog),
      SizedBox(width: AppSize.gap),
      SectionFilterChip(
        icon: service.mine ? CI.chekmark : CI.employee,
        title: S.of(context).sales_mine,
        isActive: service.mine,
        action: () => service.filterMine(!service.mine)
      ),
      if (service.isFiltered) ...[
        SizedBox(width: AppSize.gap),
        SectionFilterChip(
          icon: CI.delete,
          title: S.of(context).sales_clear,
          isActive: false,
          action: service.clearFilters
        )
      ],
      // The board still draws without the catalog —every row carries its own
      // label and colour— so a failed read is not an error state, it is a
      // missing control. It is offered back rather than retried on its own:
      // nothing on screen is wrong while it is gone.
      if (catalog.status == SalesCatalogStatus.error) ...[
        SizedBox(width: AppSize.gap),
        SectionFilterChip(
          icon: CI.info,
          title: S.of(context).sales_catalog_error,
          isActive: false,
          action: catalog.retry
        )
      ]
    ])
  );
}
