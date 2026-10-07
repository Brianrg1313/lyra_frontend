import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// SERVICES


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
    final dot = AreaHandleDot(
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
class AreaHandleDot extends StatelessWidget {
  const AreaHandleDot({super.key, required this.color, required this.filled, required this.ring});

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
