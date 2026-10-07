import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/summary/stock_summary_service.dart';

// WIDGETS
import 'package:core/button.dart';

/// The end of the list: what's happening with the next stretch.
///
/// While more rows come down you see they're coming, and if the stretch didn't
/// arrive retrying is offered. With everything read it takes up nothing: a list
/// that already ended doesn't have to say so.
class SummaryFooter extends StatelessWidget {
  const SummaryFooter({super.key, required this.service});

  final StockSummaryService service;

  @override
  Widget build(BuildContext context) {
    if (service.moreFailed) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
        child: Center(child: SizedBox(
          width: AppSize.action * 4,
          child: Button(
            title: S.of(context).stock_summary_retry,
            action: service.retryMore
          )
        ))
      );
    }

    if (!service.hasMore) return SizedBox(height: AppSize.spaceS);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
      child: const Center(child: Loading())
    );
  }
}
