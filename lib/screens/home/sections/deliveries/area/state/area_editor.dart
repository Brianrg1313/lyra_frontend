import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

/// The three ways an area is started, the ones the delivery apps offer
/// (Uber Eats, Shopify, Square): a radius around the store, a shape drawn by
/// hand, and how far a courier gets in some minutes. The last one ends as a
/// drawn shape (see [DeliveryAreaKind]).
enum AreaMethod {
  radius,
  draw,
  travel;

  DeliveryAreaKind get kind => this == radius ? DeliveryAreaKind.radius : DeliveryAreaKind.polygon;
}

/// What the delivery area page is doing: looking at the areas (and probing a
/// point), or shaping one.
///
/// It is the one thing the header, the side panel and the map share —the
/// header starts an area, the panel names and prices it, the map shapes it— so
/// it lives in the page and not in any of them. It holds **only the shape**:
/// the name and the figures are the panel's inputs, read when it saves.
class AreaEditor extends ChangeNotifier {
  AreaEditor({required this.map});

  /// Owned by the page. The editor moves it to what it opens.
  final MapController map;

  bool _open = false;
  int _session = 0;
  AreaMethod _method = AreaMethod.draw;
  DeliveryArea? _editing;

  LatLng? _center;
  double _radius = defaultRadius;
  List<LatLng> _points = const [];
  int? _selected;

  DeliveryTravelMode _mode = DeliveryTravelMode.motorcycle;
  int _minutes = defaultMinutes;

  LatLng? _probe;

  /// Earlier outlines, to undo to. Only the polygon's: a radius is one figure
  /// and its field shows the last value.
  final List<List<LatLng>> _history = [];

  bool _disposed = false;

  static const double defaultRadius = 3;
  static const int defaultMinutes = 15;

  /// The backend's limits, to the figure (`DeliveryAreas` in lyra): a shape
  /// this refused would be a shape the company cannot draw and the server
  /// would have taken.
  static const double minRadius = 0.01;
  static const double maxRadius = 1000;
  static const int maxPoints = maxRingPoints;

  /// Whether an area is being shaped. Closed, the map probes points.
  bool get isOpen => _open;

  /// Grows each time an area is started or opened: the panel is keyed by it,
  /// so its inputs start again with the new area.
  int get session => _session;

  AreaMethod get method => _method;

  /// The area being changed, or `null` when one is being added.
  DeliveryArea? get editing => _editing;

  /// Middle of a radius, and where a travel time is measured from.
  LatLng? get center => _center;

  /// Kilometres of a radius.
  double get radius => _radius;

  /// The outline being drawn, open.
  List<LatLng> get points => _points;

  /// The point picked on the map, which "remove point" removes.
  int? get selected => _selected;

  DeliveryTravelMode get mode => _mode;
  int get minutes => _minutes;

  /// Where the map was touched while looking, to say which areas reach it.
  LatLng? get probe => _probe;

  bool get canUndo => _history.isNotEmpty;

  /// Whether the shape can be saved: a circle with a middle, or an outline of
  /// three points at least.
  bool get hasShape => switch (_method.kind) {
    DeliveryAreaKind.radius => _center != null && _radius > 0,
    DeliveryAreaKind.polygon => _points.length >= 3
  };

  /// Starts a new area by [method], around [origin] (the company's point, or
  /// the middle of the map without one). A radius and a travel time start
  /// from it; a drawing starts empty.
  void start(AreaMethod method, LatLng origin) {
    _open = true;
    _session++;
    _method = method;
    _editing = null;
    _center = origin;
    _radius = defaultRadius;
    _points = const [];
    _selected = null;
    _probe = null;
    _history.clear();

    notifyListeners();

    if (method == AreaMethod.radius) fitShape();
  }

  /// Opens [area] to change it, with its shape as it is saved.
  void edit(DeliveryArea area, LatLng origin) {
    _open = true;
    _session++;
    _method = area.kind == DeliveryAreaKind.radius ? AreaMethod.radius : AreaMethod.draw;
    _editing = area;
    _center = area.center ?? origin;
    _radius = area.radius ?? defaultRadius;
    _points = List.of(area.points);
    _selected = null;
    _probe = null;
    _history.clear();

    notifyListeners();
    fit(area.bounds);
  }

  /// Back to looking, dropping the shape.
  void close() {
    _open = false;
    _editing = null;
    _points = const [];
    _selected = null;
    _history.clear();

    notifyListeners();
  }

  /// A tap on the map: it moves the middle of a radius or a travel time, adds
  /// a point to a drawing, and while looking it probes the point.
  void tap(LatLng point) {
    if (!_open) {
      _probe = point;
      notifyListeners();
      return;
    }

    if (_method == AreaMethod.draw || (_method == AreaMethod.travel && _points.isNotEmpty)) {
      if (_points.length >= maxPoints) return;

      _remember();
      _points = [..._points, point];
      _selected = _points.length - 1;
    } else {
      _center = point;
    }

    notifyListeners();
  }

  void clearProbe() {
    _probe = null;
    notifyListeners();
  }

  /// Moves the middle, dragged by its handle.
  void moveCenter(LatLng point) {
    _center = point;
    notifyListeners();
  }

  void setRadius(double km) {
    final value = km.clamp(minRadius, maxRadius).toDouble();

    if (value == _radius) return;

    _radius = value;
    notifyListeners();
  }

  void setMode(DeliveryTravelMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setMinutes(int minutes) {
    _minutes = minutes;
    notifyListeners();
  }

  /// Takes the travel-time outline as the shape, which is then edited like a
  /// drawing.
  void useOutline(List<LatLng> outline) {
    _remember();
    // Only when it is over: an outline already within the ceiling is taken as
    // it is, since simplifying a shape somebody drew would move it.
    _points = outline.length > maxPoints
      ? simplifyRing(outline, limit: maxPoints)
      : List.of(outline);
    _selected = null;

    notifyListeners();
    fitShape();
  }

  /// Called once when a point starts being dragged, so the whole drag is one
  /// undo and not one per pixel.
  void grab(int index) {
    _remember();
    _selected = index;
    notifyListeners();
  }

  void movePoint(int index, LatLng point) {
    if (index < 0 || index >= _points.length) return;

    _points = [..._points]..[index] = point;
    notifyListeners();
  }

  /// Adds a point between [index] and the next one: where the outline is
  /// bent from the handle in the middle of a side.
  void insertPoint(int index, LatLng point) {
    if (_points.length >= maxPoints) return;

    _remember();
    _points = [..._points]..insert(index + 1, point);
    _selected = index + 1;
    notifyListeners();
  }

  void select(int index) {
    _selected = index;
    notifyListeners();
  }

  void removeSelected() {
    final index = _selected;

    if (index == null || index >= _points.length) return;

    _remember();
    _points = [..._points]..removeAt(index);
    _selected = null;
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return;

    _points = _history.removeLast();
    _selected = null;
    notifyListeners();
  }

  void clearPoints() {
    if (_points.isEmpty) return;

    _remember();
    _points = const [];
    _selected = null;
    notifyListeners();
  }

  void _remember() {
    _history.add(_points);

    if (_history.length > 50) _history.removeAt(0);
  }

  /// Fits the map to the shape being made.
  void fitShape() => fit(switch (_method.kind) {
    DeliveryAreaKind.radius => DeliveryArea(
      id: "",
      name: "",
      kind: DeliveryAreaKind.radius,
      center: _center,
      radius: _radius
    ).bounds,
    DeliveryAreaKind.polygon => _points
  });

  /// Moves the map so every one of [points] is on screen. A map not drawn yet
  /// (still loading its tiles list) has no camera to move, and is left.
  void fit(List<LatLng> points) {
    if (points.isEmpty) return;

    try {
      if (points.length == 1) {
        map.move(points.first, map.camera.zoom);
        return;
      }

      map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
        maxZoom: 17
      ));
    } catch (_) {
      // No map mounted to move yet.
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
