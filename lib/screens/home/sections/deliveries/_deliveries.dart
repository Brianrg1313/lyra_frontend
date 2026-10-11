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
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/branches/branch_markers.dart';
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/area/_area.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_layers.dart';

import './deliveries_header.dart';
import './deliveries_map.dart';
import './deliveries_panel.dart';
import './widgets/map_panel.dart';

/// **The deliveries desk**: the content of the `deliveries` section.
///
/// The map is the sheet, edge to edge, like the business's branches tab: the
/// panel floats over its left side (where the company delivers, then the
/// deliveries still pending) and the actions over its top right corner. On the
/// map, every branch is pinned and the areas in force are drawn: the shared
/// map, or each branch's in that branch's colour. A pin opens its branch's
/// areas when they are drawn per branch; otherwise it only moves the map.
///
/// The services live here and not app-wide, as on the business page: what
/// they read answers for the active company, and a business switch remounts
/// the section. [MapController] lives here so what floats over the map can
/// move it.
class DeliveriesSection extends StatefulWidget {
  const DeliveriesSection({super.key});

  @override
  State<DeliveriesSection> createState() => _DeliveriesSectionState();
}

class _DeliveriesSectionState extends State<DeliveriesSection> {
  final BusinessLocationService _location = BusinessLocationService();
  final MapTilesService _tiles = MapTilesService();
  final BusinessBranchesService _branches = BusinessBranchesService();
  final DeliveryAreasService _areas = DeliveryAreasService();
  final BranchesFocus _focus = BranchesFocus();
  final MapController _map = MapController();

  @override
  void initState() {
    super.initState();

    // Deferred: the reads notify, and notifying while mounting rebuilds mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _location.load();
      _tiles.load();
      _branches.load();
      _areas.load();
    });
  }

  @override
  void dispose() {
    _location.dispose();
    _tiles.dispose();
    _branches.dispose();
    _areas.dispose();
    _focus.dispose();
    _map.dispose();

    super.dispose();
  }

  /// A pin tapped: its branch's areas, when each branch draws its own;
  /// otherwise the map goes to it.
  void _open(BusinessBranchModel branch) {
    if (_areas.areas?.scope == DeliveryScope.branch) {
      Navis.push(context, DeliveryAreaSection.branchPath(branch.id));
      return;
    }

    _focus.select(branch.id);

    if (branch case BusinessBranchModel(:final double latitude, :final double longitude)
        when _tiles.status == MapTilesStatus.ready) {
      _map.move(LatLng(latitude, longitude), DeliveriesMap.businessZoom);
    }
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles),
      ChangeNotifierProvider<BusinessBranchesService>.value(value: _branches),
      ChangeNotifierProvider<DeliveryAreasService>.value(value: _areas),
      ChangeNotifierProvider<BranchesFocus>.value(value: _focus)
    ],
    child: Surface(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(child: ListenableBuilder(
            listenable: Listenable.merge([_areas, _branches]),
            builder: (context, _) => DeliveriesMap(
              controller: _map,
              // The main branch's pin stands there, with its star.
              businessMark: false,
              layers: [
                ..._coverage(context),
                BranchMarkers(onSelect: _open)
              ]
            )
          )),
          Positioned(
            top: AppSize.spaceS,
            bottom: AppSize.spaceS,
            left: AppSize.spaceS,
            width: MapPanel.width(context, constraints.maxWidth),
            child: const MapPanel(child: DeliveriesPanel())
          ),
          Positioned(
            top: AppSize.spaceS,
            right: AppSize.spaceS,
            child: const DeliveriesHeader()
          )
        ]
      ))
    )
  );

  /// The areas in force: the shared map in the area page's colours, or each
  /// branch's areas in one colour per branch, so the map reads as which branch
  /// covers what.
  List<Widget> _coverage(BuildContext context) {
    final areas = _areas.areas;

    if (areas == null) return const [];

    final branches = [for (final branch in _branches.branches) branch.id];
    final inForce = areas.inForce(branches);

    return savedAreaLayers(
      context,
      inForce,
      colorOf: (area) => areas.scope == DeliveryScope.global
        ? areaColor(context, inForce.indexOf(area), active: area.active)
        : areaColor(context, branches.indexOf(area.branch!), active: area.active)
    );
  }
}
