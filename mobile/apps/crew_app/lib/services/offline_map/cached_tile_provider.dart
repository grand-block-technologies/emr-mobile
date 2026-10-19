import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import 'tile_math.dart';
import 'tile_store.dart';

/// flutter_map tile provider backed by [TileStore]: works offline for every tile seen before.
class CachedTileProvider extends TileProvider {
  CachedTileProvider(this.store);
  final TileStore store;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _CachedTileImage(
        store,
        TileId(coordinates.z, coordinates.x, coordinates.y),
        options.urlTemplate ?? '',
      );
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage(this.store, this.tile, this.template);
  final TileStore store;
  final TileId tile;
  final String template;

  // A valid transparent 1 × 1 PNG. Returning it for a cache miss lets
  // flutter_map leave the tile area blank instead of reporting an image error.
  static final _transparentTile = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL5XQAAAABJRU5ErkJggg==',
  );

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_load(decode));

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    var bytes = await store.load(tile, template);
    // Some reverse proxies send a successful HTTP response containing HTML or
    // plain text while a tile is unavailable. Older versions cached that body.
    // Do not hand it to Android's image decoder; remove it and try once more.
    if (bytes != null && !_isPng(bytes)) {
      await store.remove(tile);
      bytes = await store.load(tile, template);
    }
    if (bytes != null && !_isPng(bytes)) {
      await store.remove(tile);
      bytes = null;
    }
    // A missing tile while offline is normal. Return a transparent image so
    // flutter_map shows its neutral background without logging an exception.
    final codec = await decode(
      await ui.ImmutableBuffer.fromUint8List(bytes ?? _transparentTile),
    );
    return ImageInfo(image: (await codec.getNextFrame()).image);
  }

  static bool _isPng(List<int> bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a;

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage &&
      other.tile == tile &&
      other.template == template;

  @override
  int get hashCode => Object.hash(tile, template);
}
