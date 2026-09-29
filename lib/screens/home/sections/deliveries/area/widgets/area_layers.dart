import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

import '../state/area_editor.dart';

/// Colour of the area at [index]: the chart palette, in order, so the list
/// and the map name each area with the same colour. A paused area is grey,
/// whatever its place.
Color areaColor(BuildContext context, int index, {bool active = true}) {
  final scheme = ThemeColor.of(context);

  if (!active) return scheme.text.secondary;

  final series = scheme.chart.series;

  return series.isEmpty ? scheme.primary : series[index % series.length];
}

/// What goes over the tiles and under the company's mark: every saved area,
/// and the shape being made.
///
/// The area being edited is left out of the saved ones, so the map shows the
/// shape as it is being changed and not the two on top of each other.
List<Widget> areaLayers(
  BuildContext context,
  List<DeliveryArea> areas,
  AreaEditor editor
) {
  final scheme = ThemeColor.of(context);
  final editing = editor.isOpen ? editor.editing?.id : null;
  final polygons = <Polygon>[];
  final circles = <CircleMarker>[];

  for (var i = 0; i < areas.length; i++) {
    final area = areas[i];

    if (area.id == editing) continue;

    final color = areaColor(context, i, active: area.active);
    // Faint while another one is shaped: the saved areas are the reference,
    // not what is being worked on.
    final fill = color.withValues(alpha: editor.isOpen ? 0.06 : 0.16);
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
    if (circles.isNotEmpty) CircleLayer(circles: circles),
    if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
    ...draft
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
        child: _Dot(color: scheme.text.primary, filled: true, ring: scheme.surface)
      ));
    }

    return [if (markers.isNotEmpty) MarkerLayer(markers: markers)];
  }

  final points = editor.points;
  final center = editor.center;
  final shaping = editor.method == AreaMethod.draw ||
    (editor.method == AreaMethod.travel && points.isNotEmpty);

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

/// A point of the shape that is touched and dragged over the map.
///
/// It takes the pointer **before the map does** ([EagerGestureRecognizer]):
/// the map's own drag would otherwise win the gesture and move the map under
/// a point that should be moving over it. The drag is followed in screen
/// pixels from where the point was drawn, and turned into a place with the
/// map's camera, so it keeps up with a rotated or zoomed map.
///
/// A press that did not move is a tap.
class AreaHandle extends StatefulWidget {
  const AreaHandle({
    super.key,
    required this.point,
    required this.color,
    this.filled = false,
    this.selected = false,
    this.onTap,
    this.onGrab,
    this.onMove
  });

  final LatLng point;
  final Color color;

  /// A corner of the shape is filled; the middle of a side is a ring.
  final bool filled;

  final bool selected;
  final void Function()? onTap;

  /// Once, when a drag starts.
  final void Function()? onGrab;

  final void Function(LatLng point)? onMove;

  @override
  State<AreaHandle> createState() => _AreaHandleState();
}

class _AreaHandleState extends State<AreaHandle> {
  /// Where the point is on screen while it is dragged.
  Offset? _at;

  /// Pixels travelled since the press: under a few is still a tap, a hand
  /// never holds perfectly still.
  double _travelled = 0;

  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final dot = _Dot(
      color: widget.color,
      filled: widget.filled,
      ring: widget.selected ? scheme.text.primary : scheme.surface
    );

    return MouseRegion(
      cursor: widget.onMove != null ? SystemMouseCursors.move : SystemMouseCursors.click,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
            EagerGestureRecognizer.new,
            (_) {}
          )
        },
        child: Listener(
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: (_) => _end(tap: true),
          onPointerCancel: (_) => _end(tap: false),
          child: dot
        )
      )
    );
  }

  void _down(PointerDownEvent event) {
    _at = MapCamera.of(context).latLngToScreenOffset(widget.point);
    _travelled = 0;
    _dragging = false;
  }

  void _move(PointerMoveEvent event) {
    final at = _at;
    final onMove = widget.onMove;

    if (at == null || onMove == null) return;

    _travelled += event.delta.distance;
    _at = at + event.delta;

    if (!_dragging) {
      if (_travelled < 3) return;

      _dragging = true;
      widget.onGrab?.call();
    }

    onMove(MapCamera.of(context).screenOffsetToLatLng(_at!));
  }

  void _end({required bool tap}) {
    if (tap && !_dragging) widget.onTap?.call();

    _at = null;
    _dragging = false;
  }
}

/// A round mark: filled for a point, a ring for the middle of a side.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled, required this.ring});

  final Color color;
  final bool filled;
  final Color ring;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? color : ThemeColor.of(context).surface,
      border: Border.all(color: filled ? ring : color, width: 2)
    )
  );
}
