import 'dart:math';

/// One slippy-map tile (OpenStreetMap / Web Mercator scheme).
class TileId {
  const TileId(this.z, this.x, this.y);
  final int z;
  final int x;
  final int y;

  String url(String template) =>
      template.replaceAll('{z}', '$z').replaceAll('{x}', '$x').replaceAll('{y}', '$y').replaceAll('{s}', 'a');

  /// Relative cache path: `z/x/y.png`.
  String get path => '$z/$x/$y.png';

  @override
  bool operator ==(Object other) => other is TileId && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => 'TileId($z/$x/$y)';
}

/// Lat/lon box (south-west to north-east).
class GeoBounds {
  const GeoBounds({required this.south, required this.west, required this.north, required this.east});

  /// Greater Khartoum (Khartoum, Omdurman, Khartoum North) — first offline region (NFR-06).
  static const khartoum = GeoBounds(south: 15.40, west: 32.40, north: 15.75, east: 32.70);

  final double south;
  final double west;
  final double north;
  final double east;

  /// A box of roughly [radiusM] around a point (for prefetching a job area).
  factory GeoBounds.around(double lat, double lon, double radiusM) {
    final dLat = radiusM / 111320;
    final dLon = radiusM / (111320 * cos(lat * pi / 180));
    return GeoBounds(south: lat - dLat, west: lon - dLon, north: lat + dLat, east: lon + dLon);
  }
}

int lonToTileX(double lon, int z) => (((lon + 180) / 360) * (1 << z)).floor().clamp(0, (1 << z) - 1);

int latToTileY(double lat, int z) {
  final r = lat.clamp(-85.05112878, 85.05112878) * pi / 180;
  return ((1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * (1 << z)).floor().clamp(0, (1 << z) - 1);
}

/// Every tile covering [b] for zooms [minZoom]..[maxZoom], low zooms first.
Iterable<TileId> tilesIn(GeoBounds b, int minZoom, int maxZoom) sync* {
  for (var z = minZoom; z <= maxZoom; z++) {
    final x0 = lonToTileX(b.west, z), x1 = lonToTileX(b.east, z);
    final y0 = latToTileY(b.north, z), y1 = latToTileY(b.south, z);
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        yield TileId(z, x, y);
      }
    }
  }
}

int tileCount(GeoBounds b, int minZoom, int maxZoom) {
  var n = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    n += (lonToTileX(b.east, z) - lonToTileX(b.west, z) + 1) * (latToTileY(b.south, z) - latToTileY(b.north, z) + 1);
  }
  return n;
}
