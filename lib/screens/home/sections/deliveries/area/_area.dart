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
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/add_area_button.dart';
import 'package:app/screens/home/sections/deliveries/sub_page.dart';

import './area_body.dart';

/// **Delivery area**: sub-page of the `deliveries` section
/// (`/home/deliveries/area`, or `/home/deliveries/area/:branch` on that
/// branch's map), opened from the desk's panel or pins and from the delivery
/// settings, beside whether the company delivers.
///
/// The company draws one map every branch serves, or one per branch (the
/// scope, switched at the top of the list); per branch, one branch's map is
/// open at a time, the others' areas drawn grey under it, and every branch is
/// pinned on the map — a pin opens its map.
///
/// Where the company delivers, drawn on the map: every area with its own fee
/// and minimum order, made as a radius around the business, a shape drawn by
/// hand, or as far as a courier gets in some minutes. "All of Caracas" is one
/// shape around the city; "only Chacao and Altamira" is one per part.
///
/// It is a page and not a panel over the settings because it is a map to draw
/// on, and a map needs the whole content area. Its arrow goes back to the
/// deliveries desk, whose map shows what it draws.
///
/// It owns everything its parts share: the areas, the branches, the company's
/// point (where a radius starts without a branch), the maps list, the map's
/// controller and the [AreaEditor]. The URL carries no company: what it reads
/// answers for the active one, and a business switch remounts the home
/// content.
class DeliveryAreaSection extends StatefulWidget {
  const DeliveryAreaSection({super.key, this.branch});

  /// The branch whose map opens first (`:branch`); read once, on mount. Under
  /// a shared map it is ignored: there is only one map to open.
  final String? branch;

  /// Key of its route. The only source: the route table and the shell use it.
  static const String routeKey = "deliveries_area";

  static const String path = "/home/deliveries/area";

  /// Key of the route that opens a branch's map.
  static const String branchRouteKey = "deliveries_area_branch";

  static String branchPath(String branch) => "/home/deliveries/area/$branch";

  @override
  State<DeliveryAreaSection> createState() => _DeliveryAreaSectionState();
}

class _DeliveryAreaSectionState extends State<DeliveryAreaSection> {
  final DeliveryAreasService _areas = DeliveryAreasService();
  final BusinessBranchesService _branches = BusinessBranchesService();
  final BusinessLocationService _location = BusinessLocationService();
  final MapTilesService _tiles = MapTilesService();
  final BranchesFocus _focus = BranchesFocus();
  final MapController _map = MapController();
  late final AreaEditor _editor = AreaEditor(map: _map);

  /// The branch whose map was asked for; [_owner] says which one is open.
  late String? _picked = widget.branch;

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

      _areas.load();
      _branches.load();
      _location.load();
      _tiles.load();
    });
  }

  @override
  void dispose() {
    _editor.dispose();
    _areas.dispose();
    _branches.dispose();
    _location.dispose();
    _tiles.dispose();
    _focus.dispose();
    _map.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<DeliveryAreasService>.value(value: _areas),
      ChangeNotifierProvider<BusinessBranchesService>.value(value: _branches),
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles),
      ChangeNotifierProvider<BranchesFocus>.value(value: _focus)
    ],
    child: DeliveriesSubPage(
      title: S.of(context).deliveries_area_title,
      backPath: "/home/deliveries",
      backLabel: S.of(context).deliveries,
      actions: [AddAreaButton(onPick: _start)],
      child: ListenableBuilder(
        listenable: Listenable.merge([_areas, _branches]),
        builder: (context, _) => DeliveryAreaBody(
          editor: _editor,
          map: _map,
          origin: _origin,
          owner: _owner,
          onOwner: _open
        )
      )
    )
  );

  /// Opens a branch's map, unless an area is being shaped on the one open.
  void _open(String branch) {
    if (_editor.isOpen) return;

    setState(() => _picked = branch);
    _focus.select(branch);
    _editor.clearProbe();

    final point = _point(branch);

    if (point != null && _tiles.status == MapTilesStatus.ready) {
      _map.move(point, _map.camera.zoom);
    }
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
}
