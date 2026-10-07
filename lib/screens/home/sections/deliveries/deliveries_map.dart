import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';
import 'package:app/toolkit/api.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/deliveries/widgets/map_zoom_buttons.dart';

/// Right panel: the map the deliveries are followed on.
///
/// Tiles drawn by the company's own tile server (`/scorpius`, MapLibre with
/// the Protomaps style) in the app's brightness, shown by `flutter_map` (it
/// runs on Windows, the primary target). The server holds maps cut to
/// regions; the one holding the company's point is shown.
///
/// It opens on the company's map point, marked; without one (or until it is
/// read) it opens on the center of the map the server holds. The map is keyed
/// by that point and the tileset because `initialCenter` is only read when the
/// map mounts.
///
/// The delivery area page draws on this same map: [layers] go over the tiles
/// and under the company's mark, [overlays] over it (handles, pins), and
/// [onTap] receives where the map was touched.
class DeliveriesMap extends StatelessWidget {
  const DeliveriesMap({
    super.key,
    required this.controller,
    this.layers = const [],
    this.overlays = const [],
    this.onTap,
    this.center,
    this.zoomButtons = false
  });

  /// Owned by the section, so its header can move the map.
  final MapController controller;

  final List<Widget> layers;
  final List<Widget> overlays;
  final void Function(LatLng point)? onTap;

  /// Where to open instead of the company's point: the branch form opens on
  /// the branch being edited. Read only when the map mounts, like the rest.
  final LatLng? center;

  /// Zoom by +/- buttons instead of the mouse wheel: a map inside a scrolling
  /// view (the branch form) would otherwise take the wheel and stop the view
  /// from scrolling while the pointer is over it.
  final bool zoomButtons;

  static const double businessZoom = 14;

  /// The server draws past the archive's last zoom by enlarging the vectors,
  /// so the map can get to street level; it stops drawing at 20.
  static const double _maxZoom = 19;

  @override
  Widget build(BuildContext context) {
    final tiles = context.watch<MapTilesService>();
    final location = context.select<BusinessLocationService, BusinessLocationModel?>(
      (service) => service.location
    );
    final point = location != null && location.hasPoint
      ? LatLng(location.latitude!, location.longitude!)
      : null;

    switch (tiles.status) {
      case MapTilesStatus.idle:
      case MapTilesStatus.loading:
        return const Surface(child: Center(child: Loading()));
      case MapTilesStatus.error:
        return Surface(child: SectionMessage(
          icon: CI.info,
          title: S.of(context).deliveries_map_error_title,
          subtitle: S.of(context).deliveries_map_error_subtitle,
          action: tiles.retry,
          actionLabel: S.of(context).deliveries_map_retry
        ));
      case MapTilesStatus.empty:
        return Surface(child: SectionMessage(
          icon: CI.globe_shopping,
          title: S.of(context).coming_soon,
          subtitle: S.of(context).deliveries_map_soon
        ));
      case MapTilesStatus.ready:
        break;
    }

    final opening = center ?? point;
    final tileset = tiles.tilesetFor(opening?.latitude, opening?.longitude)!;
    final colors = ThemeColor.of(context);
    final style = Theme.of(context).brightness == Brightness.dark ? "dark" : "light";

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSize.corner),
      child: FlutterMap(
        key: ValueKey((opening, tileset.name)),
        mapController: controller,
        options: MapOptions(
          initialCenter: opening ?? LatLng(tileset.centerLatitude, tileset.centerLongitude),
          initialZoom: businessZoom,
          minZoom: tileset.minZoom.toDouble(),
          maxZoom: _maxZoom,
          backgroundColor: colors.surface,
          interactionOptions: InteractionOptions(
            flags: zoomButtons
              ? InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom
              : InteractiveFlag.all
          ),
          onTap: onTap == null ? null : (_, point) => onTap!(point)
        ),
        children: [
          TileLayer(
            // Keyed by style: a new template alone does not drop the tiles
            // already drawn in the other brightness.
            key: ValueKey(style),
            urlTemplate: mapTilesUrl(tileset.name, style),
            retinaMode: RetinaMode.isHighDensity(context),
            maxZoom: _maxZoom,
            userAgentPackageName: "com.andromeda.lyra"
          ),
          ...layers,
          if (point != null) MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: AppSize.action,
                height: AppSize.action,
                alignment: Alignment.topCenter,
                child: Icon(CI.store, color: colors.primary, size: AppSize.action)
              )
            ]
          ),
          ...overlays,
          if (zoomButtons) Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(AppSize.spaceS),
              child: const MapZoomButtons()
            )
          ),
          // OSM's license (ODbL) requires the credit on the map. Drawn by hand:
          // `SimpleAttributionWidget` only takes a raw `Text`.
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(AppSize.spaceS),
              child: Surface(
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
                child: TextSmall(S.of(context).deliveries_map_attribution)
              )
            )
          )
        ]
      )
    );
  }
}
