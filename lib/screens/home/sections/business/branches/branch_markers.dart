import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';

/// The company's branches on the map, each with the list's icon (shop or
/// warehouse); tapping one does what tapping its row does.
///
/// The main branch is left out: the map already draws the company's point,
/// which is the main branch's. A branch without a point is not drawn.
class BranchMarkers extends StatelessWidget {
  const BranchMarkers({super.key, required this.onSelect});

  final void Function(BusinessBranchModel branch) onSelect;

  @override
  Widget build(BuildContext context) {
    final branches = context.select<BusinessBranchesService, List<BusinessBranchModel>>(
      (service) => service.branches
    );
    final scheme = ThemeColor.of(context);

    return MarkerLayer(
      markers: [
        for (final branch in branches)
          if (branch case BusinessBranchModel(main: false, :final double latitude, :final double longitude))
            Marker(
              point: LatLng(latitude, longitude),
              width: AppSize.action,
              height: AppSize.action,
              alignment: Alignment.topCenter,
              child: FocusableWidget(
                action: () => onSelect(branch),
                message: branch.name,
                child: Icon(
                  branch.storefront ? CI.store : CI.warehouse,
                  color: scheme.primary,
                  size: AppSize.action
                )
              )
            )
      ]
    );
  }
}
