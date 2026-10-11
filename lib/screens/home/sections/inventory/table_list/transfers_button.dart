import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/inventory/transfers/_transfers.dart';

/// The bar's way to the transfers between branches, with the count of shipments waiting to be
/// received here. Only with another branch to send to or receive from, and where the mode has
/// them (`inventory.transfers`, cloud only).
class TransfersButton extends StatelessWidget {
  const TransfersButton({super.key});

  /// Listens to the singleton itself: the bar is drawn in places (tests, the sheet) that don't
  /// provide it.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BranchService(),
    builder: (context, _) => _button(context)
  );

  Widget _button(BuildContext context) {
    if (!BranchService().choosable || !CapabilityService().shows("inventory.transfers")) return const SizedBox.shrink();

    return BadgeCorner(
      place: BadgePlace.inventoryTransfers,
      child: FeedbackButton(
        action: () => Navis.push(context, StockTransfersSection.path),
        height: AppSize.button,
        color: ThemeColor.of(context).surfaceOver,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
        message: S.of(context).inventory_transfers_open,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CI.store, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon),
          SizedBox(width: AppSize.gap),
          TextMedium(S.of(context).inventory_transfers_open)
        ])
      )
    );
  }
}
