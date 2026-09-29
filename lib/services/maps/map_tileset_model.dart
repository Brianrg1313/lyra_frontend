/// One map the tile server can draw, as `GET /scorpius/v1/tilesets` lists it:
/// a PMTiles archive on the server, cut to a region (a city, a country).
///
/// An archive covers only its box, so the app picks the one holding the point
/// it wants to show, and opens on the archive's own center when it has none.
class MapTilesetModel {
  const MapTilesetModel({
    required this.name,
    required this.type,
    required this.minZoom,
    required this.maxZoom,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
    required this.centerLatitude,
    required this.centerLongitude
  });

  /// What the tile URL addresses it by (`/raster/<name>/<style>/{z}/{x}/{y}`).
  final String name;

  /// Tile format: `mvt` for vector tiles, or an image type (`png`, `webp`…).
  final String type;

  /// Zooms the archive holds data for. The server draws past [maxZoom] by
  /// enlarging the vectors, so the map may go closer.
  final int minZoom;
  final int maxZoom;

  final double west;
  final double south;
  final double east;
  final double north;

  final double centerLatitude;
  final double centerLongitude;

  /// Only vector archives can be drawn: the server's style is written for the
  /// Protomaps vector schema.
  bool get isVector => type == "mvt";

  bool contains(double latitude, double longitude) =>
    latitude >= south && latitude <= north &&
    longitude >= west && longitude <= east;

  /// `bounds` and `center` arrive as `[minLon, minLat, maxLon, maxLat]` and
  /// `[lon, lat, zoom]`: longitude first, as TileJSON writes them.
  factory MapTilesetModel.fromJson(Map<dynamic, dynamic> json) {
    final bounds = _numbers(json["bounds"], 4);
    final center = _numbers(json["center"], 2);

    return MapTilesetModel(
      name: json["name"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      minZoom: (json["minzoom"] as num?)?.toInt() ?? 0,
      maxZoom: (json["maxzoom"] as num?)?.toInt() ?? 0,
      west: bounds[0],
      south: bounds[1],
      east: bounds[2],
      north: bounds[3],
      centerLatitude: center[1],
      centerLongitude: center[0]
    );
  }

  static List<double> _numbers(dynamic value, int length) {
    final list = value is List ? value.whereType<num>().map((n) => n.toDouble()).toList() : <double>[];

    return list.length >= length ? list : List.filled(length, 0);
  }
}
