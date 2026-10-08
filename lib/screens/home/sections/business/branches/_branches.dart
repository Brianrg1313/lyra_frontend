import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/deliveries/deliveries_map.dart';
import 'package:app/screens/modals/business/branch_form/_branch_form.dart';

import './branch_markers.dart';
import './branches_panel.dart';

/// Branches tab: the map is the sheet, and the branches float over its left
/// side in a panel (title, search, list), with the add button on its right.
/// Every branch with a point is marked on the map; tapping one, there or in
/// the list, centers the map on it and opens its form. It opens on the
/// company's point (the main branch's) and, without one, on the center of the
/// map the tile server holds for the region.
///
/// The map is the deliveries one, with its own location and tiles: they are
/// read once per visit to the tab, like the deliveries section does.
class BusinessBranchesTab extends StatefulWidget {
  const BusinessBranchesTab({super.key});

  @override
  State<BusinessBranchesTab> createState() => _BusinessBranchesTabState();
}

class _BusinessBranchesTabState extends State<BusinessBranchesTab> {
  final BusinessLocationService _location = BusinessLocationService();
  final MapTilesService _tiles = MapTilesService();
  final MapController _map = MapController();

  @override
  void initState() {
    super.initState();

    // Deferred: the read notifies, and notifying while mounting rebuilds mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _location.load();
      _tiles.load();
    });
  }

  @override
  void dispose() {
    _location.dispose();
    _tiles.dispose();
    _map.dispose();

    super.dispose();
  }

  /// Share of the sheet's width the panel takes: more on smaller screens,
  /// where a quarter would not fit a branch's name.
  double _panelShare(BuildContext context) {
    final device = Responsive.of(context);

    if (device.isPhone) return 0.36;
    if (device.isTablet) return 0.3;
    return 0.25;
  }

  /// Below this a share leaves the rows too narrow to read a name and its
  /// place, so the panel stops shrinking there.
  static double get _panelMinWidth => AppSize.action * 6.5;

  /// The panel's width: its share of the sheet, never under
  /// [_panelMinWidth], and never wider than the sheet minus its margins.
  double _panelWidth(BuildContext context, double sheet) {
    final room = sheet - AppSize.spaceS * 2;
    final width = sheet * _panelShare(context);

    if (width < _panelMinWidth) return _panelMinWidth.clamp(0, room < 0 ? 0 : room);
    return width;
  }

  /// A new branch. The country is the company's: every branch is in it.
  Future<void> _add(BuildContext context) => showBranchForm(
    context,
    branches: context.read<BusinessBranchesService>(),
    country: context.read<BusinessService>().profile?.country ?? ""
  );

  /// A branch tapped in the list: the map goes to it and its form opens.
  /// A branch without a point leaves the map where it is. The map is only
  /// moved once drawn: its controller throws before the tiles are ready.
  Future<void> _open(BuildContext context, BusinessBranchModel branch) {
    if (branch case BusinessBranchModel(:final double latitude, :final double longitude)
        when _tiles.status == MapTilesStatus.ready) {
      _map.move(LatLng(latitude, longitude), DeliveriesMap.businessZoom);
    }

    return showBranchForm(
      context,
      branches: context.read<BusinessBranchesService>(),
      country: context.read<BusinessService>().profile?.country ?? "",
      branch: branch
    );
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles)
    ],
    child: LayoutBuilder(builder: (context, constraints) => Stack(
      children: [
        Positioned.fill(child: DeliveriesMap(
          controller: _map,
          layers: [BranchMarkers(onSelect: (branch) => _open(context, branch))]
        )),
        Positioned(
          top: AppSize.spaceS,
          bottom: AppSize.spaceS,
          left: AppSize.spaceS,
          width: _panelWidth(context, constraints.maxWidth),
          child: BranchesPanel(onSelect: (branch) => _open(context, branch))
        ),
        Positioned(
          top: AppSize.spaceS,
          right: AppSize.spaceS,
          // A list that could not be read does not offer to grow.
          child: Consumer<BusinessBranchesService>(builder: (context, service, _) =>
            service.status == BusinessBranchesStatus.error
              ? const SizedBox.shrink()
              : Button(
                  width: null,
                  title: S.of(context).business_branches_add,
                  leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
                  action: () => _add(context)
                )
          )
        )
      ]
    ))
  );
}
