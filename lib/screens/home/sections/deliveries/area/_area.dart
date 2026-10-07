import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/add_area_button.dart';
import 'package:app/screens/home/sections/deliveries/settings/_settings.dart';
import 'package:app/screens/home/sections/deliveries/sub_page.dart';

import './area_body.dart';

/// **Delivery area**: sub-page of the `deliveries` section
/// (`/home/deliveries/area`), opened from the delivery settings, beside
/// whether the company delivers.
///
/// Where the company delivers, drawn on the map: every area with its own fee
/// and minimum order, made as a radius around the business, a shape drawn by
/// hand, or as far as a courier gets in some minutes. "All of Caracas" is one
/// shape around the city; "only Chacao and Altamira" is one per part.
///
/// It is a page and not a panel over the settings because it is a map to draw
/// on, and a map needs the whole content area. Its arrow goes back to the
/// settings, which is where it is opened from.
///
/// It owns everything its parts share: the areas, the company's point (where
/// a radius starts), the maps list, the map's controller and the
/// [AreaEditor]. Like the settings, the URL carries no id: what it reads
/// answers for the active company, and a business switch remounts the home
/// content.
class DeliveryAreaSection extends StatefulWidget {
  const DeliveryAreaSection({super.key});

  /// Key of its route. The only source: the route table and the shell use it.
  static const String routeKey = "deliveries_area";

  static const String path = "/home/deliveries/area";

  @override
  State<DeliveryAreaSection> createState() => _DeliveryAreaSectionState();
}

class _DeliveryAreaSectionState extends State<DeliveryAreaSection> {
  final DeliveryAreasService _areas = DeliveryAreasService();
  final BusinessLocationService _location = BusinessLocationService();
  final MapTilesService _tiles = MapTilesService();
  final MapController _map = MapController();
  late final AreaEditor _editor = AreaEditor(map: _map);

  @override
  void initState() {
    super.initState();

    // Deferred: the reads notify, and notifying while mounting rebuilds mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _areas.load();
      _location.load();
      _tiles.load();
    });
  }

  @override
  void dispose() {
    _editor.dispose();
    _areas.dispose();
    _location.dispose();
    _tiles.dispose();
    _map.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<DeliveryAreasService>.value(value: _areas),
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles)
    ],
    child: DeliveriesSubPage(
      title: S.of(context).deliveries_area_title,
      backPath: DeliverySettingsSection.path,
      backLabel: S.of(context).deliveries_settings_title,
      actions: [AddAreaButton(onPick: _start)],
      child: DeliveryAreaBody(editor: _editor, map: _map, origin: _origin)
    )
  );

  /// Starts a new area, unless the list is not there to add it to, or full.
  void _start(AreaMethod method) {
    final areas = _areas.areas;

    if (_areas.status != DeliveryAreasStatus.ready || areas == null) {
      FloatFlag.of(context).alert(message: S.of(context).deliveries_area_not_ready);
      return;
    }

    if (areas.areas.length >= DeliveryAreasService.limit) {
      FloatFlag.of(context).alert(
        message: S.of(context).deliveries_area_limit(DeliveryAreasService.limit)
      );
      return;
    }

    _editor.start(method, _origin());
  }

  /// Where an area starts: the company's point, else the middle of the map on
  /// screen, else the middle of the map the server holds.
  LatLng _origin() {
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
