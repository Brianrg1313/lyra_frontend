import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';

import './area_handle.dart';

/// Colour of the area at [index]: the chart palette, in order, so the list
/// and the map name each area with the same colour. A paused area is grey,
/// whatever its place.
Color areaColor(BuildContext context, int index, {bool active = true}) {
  final scheme = ThemeColor.of(context);

  if (!active) return scheme.text.secondary;

  final series = scheme.chart.series;

  return series.isEmpty ? scheme.primary : series[index % series.length];
}

/// What goes over the tiles and under the company's mark: every saved area
/// of the map being edited, the other branches' areas in force under it
/// ([others], grey: what this branch's map sits beside), and the shape being
/// made.
///
/// The area being edited is left out of the saved ones, so the map shows the
/// shape as it is being changed and not the two on top of each other.
List<Widget> areaLayers(
  BuildContext context,
  List<DeliveryArea> areas,
  AreaEditor editor, {
  List<DeliveryArea> others = const []
}) {
  final scheme = ThemeColor.of(context);
  final editing = editor.isOpen ? editor.editing?.id : null;

  final draft = <Widget>[];

  if (editor.isOpen) {
    final color = scheme.primary;
    final fill = color.withValues(alpha: 0.2);
    final center = editor.center;
    final points = editor.points;

    if (editor.method == AreaMethod.radius && center != null) {
      draft.add(CircleLayer(circles: [
        CircleMarker(
          point: center,
          radius: editor.radius * 1000,
          useRadiusInMeter: true,
          color: fill,
          borderColor: color,
          borderStrokeWidth: 2.5
        )
      ]));
    } else if (points.length >= 3) {
      draft.add(PolygonLayer(polygons: [
        Polygon(points: points, color: fill, borderColor: color, borderStrokeWidth: 2.5)
      ]));
    } else if (points.length == 2) {
      draft.add(PolylineLayer(polylines: [
        Polyline(points: points, color: color, strokeWidth: 2.5)
      ]));
    }
  }

  return [
    ...savedAreaLayers(context, others, colorOf: (_) => scheme.text.secondary, faint: true),
    ...savedAreaLayers(
      context,
      [for (final area in areas) if (area.id != editing) area],
      colorOf: (area) => areaColor(context, areas.indexOf(area), active: area.active),
      faint: editor.isOpen
    ),
    ...draft
  ];
}

/// Saved areas as map layers, each in [colorOf]'s colour. [faint] while
/// another shape is being made: the saved areas are the reference, not what is
/// being worked on.
List<Widget> savedAreaLayers(
  BuildContext context,
  List<DeliveryArea> areas, {
  required Color Function(DeliveryArea area) colorOf,
  bool faint = false
}) {
  final polygons = <Polygon>[];
  final circles = <CircleMarker>[];

  for (final area in areas) {
    final color = colorOf(area);
    final fill = color.withValues(alpha: faint ? 0.06 : 0.16);
    // A paused area keeps its outline, broken: it is there, and it reaches nobody.
    final pattern = area.active
      ? const StrokePattern.solid()
      : StrokePattern.dashed(segments: const [8, 6]);

    switch (area.kind) {
      case DeliveryAreaKind.polygon when area.points.length >= 3:
        polygons.add(Polygon(
          points: area.points,
          color: fill,
          borderColor: color,
          borderStrokeWidth: 2,
          pattern: pattern
        ));
      case DeliveryAreaKind.radius when area.center != null && area.radius != null:
        circles.add(CircleMarker(
          point: area.center!,
          radius: area.radius! * 1000,
          useRadiusInMeter: true,
          color: fill,
          borderColor: color,
          borderStrokeWidth: 2
        ));
      default:
        break;
    }
  }

  return [
    if (circles.isNotEmpty) CircleLayer(circles: circles),
    if (polygons.isNotEmpty) PolygonLayer(polygons: polygons)
  ];
}

/// What goes over the company's mark: the handles of the shape being made,
/// and the probed point while looking.
List<Widget> areaOverlays(BuildContext context, AreaEditor editor) {
  final scheme = ThemeColor.of(context);
  final size = AppSize.text * 1.1;
  final markers = <Marker>[];

  if (!editor.isOpen) {
    final probe = editor.probe;

    if (probe != null) {
      markers.add(Marker(
        point: probe,
        width: size * 1.4,
        height: size * 1.4,
        child: AreaHandleDot(color: scheme.text.primary, filled: true, ring: scheme.surface)
      ));
    }

    return [if (markers.isNotEmpty) MarkerLayer(markers: markers)];
  }

  final points = editor.points;
  final center = editor.center;
  final shaping = editor.method == AreaMethod.draw ||
    (editor.method.routed && points.isNotEmpty);

  if (shaping) {
    // The middle of each side, to bend it from there. The closing side only
    // exists once there is a shape.
    final sides = points.length >= 3 ? points.length : points.length - 1;

    for (var i = 0; i < sides; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      final middle = LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);

      markers.add(Marker(
        point: middle,
        width: size * 0.8,
        height: size * 0.8,
        child: AreaHandle(
          point: middle,
          color: scheme.primary,
          onTap: () => editor.insertPoint(i, middle)
        )
      ));
    }

    for (var i = 0; i < points.length; i++) {
      markers.add(Marker(
        point: points[i],
        width: size,
        height: size,
        child: AreaHandle(
          point: points[i],
          color: scheme.primary,
          filled: true,
          selected: editor.selected == i,
          onTap: () => editor.select(i),
          onGrab: () => editor.grab(i),
          onMove: (point) => editor.movePoint(i, point)
        )
      ));
    }
  } else if (center != null) {
    markers.add(Marker(
      point: center,
      width: size * 1.3,
      height: size * 1.3,
      child: AreaHandle(
        point: center,
        color: scheme.primary,
        filled: true,
        selected: true,
        onMove: editor.moveCenter
      )
    ));
  }

  return [MarkerLayer(markers: markers)];
}
