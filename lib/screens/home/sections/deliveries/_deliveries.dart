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
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';
import 'package:app/toolkit/deployment.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/branches/branch_markers.dart';
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_layers.dart';
import 'package:app/screens/modals/deliveries/shipment/_shipment.dart';

import './deliveries_header.dart';
import './deliveries_map.dart';
import './deliveries_panel.dart';
import './shipments/shipment_markers.dart';
import './widgets/map_panel.dart';

/// **The deliveries desk**: the content of the `deliveries` section.
///
/// The map is the sheet, edge to edge, like the business's branches tab: the
/// panel floats over its left side and the actions over its top right corner.
/// Where the company delivers is drawn and edited here, on the one map: the
/// panel lists the open map's areas (the shared one, or per branch the one
/// picked) and "Add area" turns the map into where a new one is shaped. Per
/// branch, the other branches' areas in force are drawn grey under the open
/// map's, and a pin opens its branch's map; with one shared map a pin only
/// moves the map.
///
/// The branch's deliveries open first: the panel lists them and the map pins
/// where each goes (cloud only, [ShipmentsService]); a tile or a pin opens the
/// shipment's panel.
///
/// The services live here and not app-wide, as on the business page: what
/// they read answers for the active company (and the shipments for the branch
/// worked in), and a business or branch switch remounts the section. The [MapController] and the [AreaEditor] live here because
/// the panel, the map and its pins all move or read them.
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
  final ShipmentsService _shipments = ShipmentsService();
  final BranchesFocus _focus = BranchesFocus();
  final MapController _map = MapController();
  late final AreaEditor _editor = AreaEditor(map: _map);

  /// The branch whose map was asked for; [_owner] says which one is open.
  String? _picked;

  /// The board exists only in the cloud (see [DeliveriesPanel.shipments]).
  final bool _board = Deployment.mode == DeploymentMode.cloud;

  late DeliveriesView _view = _board ? DeliveriesView.shipments : DeliveriesView.areas;

  /// The shipment whose panel was opened last, named on its pin.
  String? _litShipment;

  /// The open map: `null` for the shared one; per branch, the one picked, or
  /// the first (the main one) when none was or it is gone.
  String? get _owner {
    if (_areas.areas?.scope != DeliveryScope.branch) return null;

    final branches = _branches.branches;

    for (final branch in branches) {
      if (branch.id == _picked) return branch.id;
    }

    return branches.firstOrNull?.id;
  }

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
      if (_board) _shipments.load();
    });
  }

  @override
  void dispose() {
    _editor.dispose();
    _location.dispose();
    _tiles.dispose();
    _branches.dispose();
    _areas.dispose();
    _shipments.dispose();
    _focus.dispose();
    _map.dispose();

    super.dispose();
  }

  /// A pin tapped, or a branch picked in the panel: per branch, its map opens
  /// (unless an area is being shaped on the one open); shared, the map only
  /// goes to it.
  void _open(String branch) {
    if (_editor.isOpen) return;

    final perBranch = _areas.areas?.scope == DeliveryScope.branch;

    if (perBranch) {
      setState(() => _picked = branch);
      _editor.clearProbe();
    }

    _focus.select(branch);

    final point = _point(branch);

    if (point != null && _tiles.status == MapTilesStatus.ready) {
      _map.move(point, perBranch ? _map.camera.zoom : DeliveriesMap.businessZoom);
    }
  }

  /// Shows [view]; the areas drop the probe a shipment view has no use for.
  void _show(DeliveriesView view) {
    if (view == _view) return;

    _editor.clearProbe();
    setState(() => _view = view);
  }

  /// Opens [shipment]'s panel, moving the map to where it goes.
  Future<void> _openShipment(Shipment shipment) async {
    setState(() => _litShipment = shipment.id);

    final destination = shipment.destination;

    if (destination case ShipmentDestination(:final double latitude, :final double longitude)
        when _tiles.status == MapTilesStatus.ready) {
      _map.move(LatLng(latitude, longitude), _map.camera.zoom);
    }

    await showShipment(context, service: _shipments, id: shipment.id);
  }

  /// Starts a new area, unless the list is not there to add it to, or full.
  void _start(AreaMethod method) {
    final areas = _areas.areas;
    final branches = _branches.status == BusinessBranchesStatus.ready;

    if (_areas.status != DeliveryAreasStatus.ready ||
        areas == null ||
        (areas.scope == DeliveryScope.branch && (!branches || _owner == null))) {
      FloatFlag.of(context).alert(message: S.of(context).deliveries_area_not_ready);
      return;
    }

    if (areas.of(_owner).length >= DeliveryAreasService.limit) {
      FloatFlag.of(context).alert(
        message: S.of(context).deliveries_area_limit(DeliveryAreasService.limit)
      );
      return;
    }

    _editor.start(method, _origin());
  }

  /// A branch's point, or `null` when it has none.
  LatLng? _point(String? id) {
    for (final branch in _branches.branches) {
      if (branch case BusinessBranchModel(:final double latitude, :final double longitude) when branch.id == id) {
        return LatLng(latitude, longitude);
      }
    }

    return null;
  }

  /// Where an area starts: the open branch's point, else the company's, else
  /// the middle of the map on screen, else the middle of the map the server
  /// holds.
  LatLng _origin() {
    final branch = _point(_owner);

    if (branch != null) return branch;

    final location = _location.location;

    if (location != null && location.hasPoint) {
      return LatLng(location.latitude!, location.longitude!);
    }

    try {
      return _map.camera.center;
    } catch (_) {
      final tileset = _tiles.tilesetFor(null, null);

      return tileset == null
        ? const LatLng(0, 0)
        : LatLng(tileset.centerLatitude, tileset.centerLongitude);
    }
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles),
      ChangeNotifierProvider<BusinessBranchesService>.value(value: _branches),
      ChangeNotifierProvider<DeliveryAreasService>.value(value: _areas),
      ChangeNotifierProvider<ShipmentsService>.value(value: _shipments),
      ChangeNotifierProvider<BranchesFocus>.value(value: _focus)
    ],
    child: Surface(
      padding: EdgeInsets.zero,
      child: ListenableBuilder(
        listenable: Listenable.merge([_areas, _branches, _editor]),
        builder: (context, _) => LayoutBuilder(builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: DeliveriesMap(
              controller: _map,
              // Every branch is pinned, the main one with its star at the company's point.
              businessMark: false,
              layers: [
                ..._layers(context),
                BranchMarkers(onSelect: (branch) => _open(branch.id)),
                if (_view == DeliveriesView.shipments && !_editor.isOpen)
                  ShipmentMarkers(onOpen: _openShipment, lit: _litShipment)
              ],
              overlays: areaOverlays(context, _editor),
              onTap: _view == DeliveriesView.areas || _editor.isOpen ? _editor.tap : null
            )),
            Positioned(
              top: AppSize.spaceS,
              bottom: AppSize.spaceS,
              left: AppSize.spaceS,
              width: MapPanel.width(context, constraints.maxWidth),
              child: MapPanel(child: DeliveriesPanel(
                editor: _editor,
                owner: _owner,
                origin: _origin,
                onOwner: _open,
                onAdd: _start,
                view: _view,
                onView: _show,
                shipments: _board,
                onShipment: _openShipment,
                litShipment: _litShipment
              ))
            ),
            Positioned(
              top: AppSize.spaceS,
              right: AppSize.spaceS,
              child: const DeliveriesHeader()
            )
          ]
        ))
      )
    )
  );

  /// The open map's areas in their colours (and the one being shaped), the
  /// other branches' in force grey under them.
  List<Widget> _layers(BuildContext context) {
    final areas = _areas.areas;

    if (areas == null) return areaLayers(context, const [], _editor);

    final owner = _owner;
    final inForce = areas.inForce([for (final branch in _branches.branches) branch.id]);

    return areaLayers(
      context,
      areas.of(owner),
      _editor,
      others: [for (final area in inForce) if (area.branch != owner) area]
    );
  }
}
