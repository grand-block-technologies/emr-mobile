import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import 'tile_math.dart';
import 'tile_store.dart';

/// Progress of a region download.
class RegionProgress {
  const RegionProgress({this.done = 0, this.total = 0, this.failed = 0, this.running = false});
  final int done;
  final int total;
  final int failed;
  final bool running;

  double get fraction => total == 0 ? 0 : done / total;
}

/// Offline OpenStreetMap: every viewed tile is cached; a whole region (Khartoum first) can be
/// downloaded ahead when the tile server allows it (never from the public OSM servers).
class OfflineMapService extends GetxService {
  OfflineMapService({required this.store, required this.urlTemplate, this.concurrency = 4});

  final TileStore store;
  final String urlTemplate;
  final int concurrency;

  static const regionMinZoom = 10;
  static const regionMaxZoom = 16;

  final progress = const RegionProgress().obs;
  bool _cancel = false;

  bool get canDownloadRegions => bulkDownloadAllowed(urlTemplate);

  int estimate(GeoBounds b, {int minZoom = regionMinZoom, int maxZoom = regionMaxZoom}) => tileCount(b, minZoom, maxZoom);

  /// Downloads every missing tile of [b]. Resumable: cached tiles are skipped.
  /// Throws [StateError] when the tile server forbids bulk downloads.
  Future<RegionProgress> downloadRegion(GeoBounds b, {int minZoom = regionMinZoom, int maxZoom = regionMaxZoom}) async {
    if (!canDownloadRegions) {
      throw StateError('Bulk download is not allowed from $urlTemplate (OSM tile usage policy)');
    }
    if (progress.value.running) return progress.value;
    _cancel = false;
    final total = tileCount(b, minZoom, maxZoom);
    var done = 0, failed = 0;
    progress.value = RegionProgress(total: total, running: true);

    final tiles = tilesIn(b, minZoom, maxZoom).iterator;
    Future<void> worker() async {
      while (!_cancel) {
        final TileId t;
        if (!tiles.moveNext()) return;
        t = tiles.current;
        try {
          await store.ensure(t, urlTemplate);
        } on Object {
          failed++;
        }
        done++;
        progress.value = RegionProgress(done: done, total: total, failed: failed, running: true);
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    return progress.value = RegionProgress(done: done, total: total, failed: failed);
  }

  void cancel() => _cancel = true;

  Future<int> cacheBytes() => store.sizeBytes();

  Future<void> clear() => store.clear();

  /// Default on-device location for cached tiles.
  static Directory dirIn(Directory support) => Directory('${support.path}/map_tiles');
}
