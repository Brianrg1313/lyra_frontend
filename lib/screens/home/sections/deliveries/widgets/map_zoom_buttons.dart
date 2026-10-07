import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';

// SERVICES

// WIDGETS

/// The map's +/- pair, one step of zoom each, kept within the map's limits.
/// A child of the map, so it reads the camera and controller from it.
class MapZoomButtons extends StatelessWidget {
  const MapZoomButtons({super.key});

  void _zoom(BuildContext context, double step) {
    final camera = MapCamera.of(context);

    MapController.of(context).move(camera.center, camera.clampZoom(camera.zoom + step));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    Widget button(IconData icon, String message, double step) => FeedbackButton(
      action: () => _zoom(context, step),
      message: message,
      width: AppSize.action,
      height: AppSize.action,
      child: Center(child: Icon(icon, color: scheme.text.primary))
    );

    return Surface(
      radius: AppSize.corner,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.corner),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Icons.add, S.of(context).deliveries_map_zoom_in, 1),
            SizedBox(width: AppSize.action, child: Separator.horizontal(color: scheme.line)),
            button(Icons.remove, S.of(context).deliveries_map_zoom_out, -1)
          ]
        )
      )
    );
  }
}
