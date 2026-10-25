import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/maps/map_tileset_model.dart';
import 'package:app/toolkit/backend/api.dart';

enum MapTilesStatus { idle, loading, ready, empty, error }

/// Which maps the tile server holds (`GET /scorpius/v1/tilesets`), and which
/// of them shows a given point.
///
/// Created and provided by the screen that shows a map. The tiles themselves
/// are drawn by the server (`/scorpius/v1/raster`, see `mapTilesUrl`); this
/// only chooses the region.
class MapTilesService extends ChangeNotifier {
  MapTilesStatus _status = MapTilesStatus.idle;
  List<MapTilesetModel> _tilesets = const [];

  bool _disposed = false;

  MapTilesStatus get status => _status;

  /// The maps on the server. Empty until read.
  List<MapTilesetModel> get tilesets => _tilesets;

  /// Reads the list. Without [force] it is read once.
  Future<void> load({bool force = false}) async {
    if (_status == MapTilesStatus.loading) return;
    if (!force && (_status == MapTilesStatus.ready || _status == MapTilesStatus.empty)) return;

    _status = MapTilesStatus.loading;
    notifyListeners();

    try {
      final data = await scorpius.get(path: "/tilesets", version: "v1");

      _tilesets = data is List
        ? data.whereType<Map>().map(MapTilesetModel.fromJson).where((t) => t.isVector).toList()
        : const [];
      _status = _tilesets.isEmpty ? MapTilesStatus.empty : MapTilesStatus.ready;
    } catch (error) {
      if (kDebugMode) print("loadMapTiles failed: $error");

      _status = MapTilesStatus.error;
    }

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// The map to show a point on: the one whose box holds it, else the first.
  /// Null only while nothing is loaded.
  MapTilesetModel? tilesetFor(double? latitude, double? longitude) {
    if (_tilesets.isEmpty) return null;
    if (latitude == null || longitude == null) return _tilesets.first;

    return _tilesets.firstWhere(
      (tileset) => tileset.contains(latitude, longitude),
      orElse: () => _tilesets.first
    );
  }

  /// A read can answer after the screen that asked for it is gone, and
  /// notifying a disposed notifier throws.
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
