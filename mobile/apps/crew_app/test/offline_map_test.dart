import 'dart:io';
import 'dart:typed_data';

import 'package:crew_app/services/offline_map/offline_map_service.dart';
import 'package:crew_app/services/offline_map/tile_math.dart';
import 'package:crew_app/services/offline_map/tile_store.dart';
import 'package:flutter_test/flutter_test.dart';

const osm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const own = 'https://tiles.gbt.example/osm/{z}/{x}/{y}.png';

/// Fake tile server: records URLs, can go offline or fail specific tiles.
class FakeTiles {
  final urls = <String>[];
  bool offline = false;
  final failing = <String>{};
  int size = 100;

  Future<Uint8List> call(String url) async {
    if (offline) throw const SocketException('offline');
    urls.add(url);
    if (failing.contains(url)) throw const HttpException('500');
    return Uint8List.fromList(List.filled(size, url.length % 256));
  }
}

void main() {
  group('tile math', () {
    test('known tiles', () {
      expect(lonToTileX(0, 1), 1);
      expect(latToTileY(0, 1), 1);
      expect(lonToTileX(-180, 3), 0);
      expect(lonToTileX(180, 3), 7, reason: 'clamped to the last column');
      // Khartoum centre at zoom 15.
      expect((lonToTileX(32.5599, 15), latToTileY(15.5007, 15)), (19347, 14955));
    });

    test('tilesIn matches tileCount, low zooms first, no duplicates', () {
      const b = GeoBounds(south: 15.55, west: 32.50, north: 15.60, east: 32.56);
      final list = tilesIn(b, 12, 15).toList();
      expect(list.length, tileCount(b, 12, 15));
      expect(list.toSet().length, list.length);
      expect(list.first.z, 12);
      expect(list.last.z, 15);
    });

    test('Khartoum z10–16 is a sane size for a phone', () {
      final n = tileCount(GeoBounds.khartoum, 10, 16);
      expect(n, inInclusiveRange(1000, 20000));
    });

    test('GeoBounds.around covers the radius', () {
      final b = GeoBounds.around(15.58, 32.55, 1000);
      expect(b.north - b.south, closeTo(2000 / 111320, 1e-6));
      expect(b.east, greaterThan(b.west));
    });

    test('url substitution', () {
      expect(const TileId(15, 19347, 14955).url(osm), 'https://tile.openstreetmap.org/15/19347/14955.png');
    });
  });

  test('bulk downloads are refused for the public OSM servers', () {
    expect(bulkDownloadAllowed(osm), isFalse);
    expect(bulkDownloadAllowed('https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'), isFalse);
    expect(bulkDownloadAllowed(own), isTrue);
    expect(bulkDownloadAllowed('not a url'), isFalse);
  });

  group('TileStore', () {
    late Directory dir;
    late FakeTiles server;
    late DateTime now;
    late TileStore store;
    const t = TileId(15, 19347, 14955);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tiles');
      server = FakeTiles();
      now = DateTime(2026, 10, 15, 12);
      store = TileStore(dir: dir, fetch: server.call, now: () => now, maxBytes: 1000);
    });

    tearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test('miss downloads and caches; a fresh hit does not touch the network', () async {
      expect(await store.load(t, osm), hasLength(100));
      expect(await store.load(t, osm), hasLength(100));
      expect(server.urls, hasLength(1));
      expect(File('${dir.path}/15/19347/14955.png').existsSync(), isTrue);
    });

    test('an old tile is refreshed when online', () async {
      await store.load(t, osm);
      now = now.add(const Duration(days: 31));
      await store.load(t, osm);
      expect(server.urls, hasLength(2));
    });

    test('offline: an old tile is still shown; a never-seen tile is null', () async {
      await store.load(t, osm);
      now = now.add(const Duration(days: 365));
      server.offline = true;
      expect(await store.load(t, osm), isNotNull);
      expect(await store.load(const TileId(15, 1, 1), osm), isNull);
    });

    test('concurrent loads of one tile share a single download', () async {
      await Future.wait([store.load(t, osm), store.load(t, osm), store.load(t, osm)]);
      expect(server.urls, hasLength(1));
    });

    test('stays under the size cap by deleting the oldest tiles', () async {
      for (var i = 0; i < 15; i++) {
        now = now.add(const Duration(minutes: 1));
        await store.load(TileId(15, i, 0), osm);
      }
      expect(await store.sizeBytes(), lessThanOrEqualTo(1000));
      expect(await store.has(const TileId(15, 0, 0)), isFalse, reason: 'oldest evicted');
      expect(await store.has(const TileId(15, 14, 0)), isTrue, reason: 'newest kept');
    });

    test('size is counted once per tile', () async {
      await store.load(t, osm);
      expect(await store.sizeBytes(), 100);
      await TileStore(dir: dir, fetch: server.call).sizeBytes().then((n) => expect(n, 100));
    });

    test('clear removes everything', () async {
      await store.load(t, osm);
      await store.clear();
      expect(await store.has(t), isFalse);
      expect(await store.sizeBytes(), 0);
    });
  });

  group('OfflineMapService', () {
    late Directory dir;
    late FakeTiles server;
    const small = GeoBounds(south: 15.58, west: 32.55, north: 15.59, east: 32.56);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('region');
      server = FakeTiles();
    });

    tearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    OfflineMapService svc(String url) =>
        OfflineMapService(store: TileStore(dir: dir, fetch: server.call, maxBytes: 1 << 30), urlTemplate: url);

    test('refuses to bulk-download from tile.openstreetmap.org', () async {
      final s = svc(osm);
      expect(s.canDownloadRegions, isFalse);
      await expectLater(s.downloadRegion(small, minZoom: 14, maxZoom: 15), throwsStateError);
      expect(server.urls, isEmpty);
    });

    test('downloads every tile of the region from our own server', () async {
      final s = svc(own);
      final r = await s.downloadRegion(small, minZoom: 13, maxZoom: 16);
      final expected = tileCount(small, 13, 16);
      expect(r.done, expected);
      expect(r.failed, 0);
      expect(r.running, isFalse);
      expect(server.urls.toSet(), hasLength(expected));
      expect(server.urls.every((u) => u.startsWith('https://tiles.gbt.example/osm/')), isTrue);
    });

    test('is resumable: a second run downloads only what is missing', () async {
      final s = svc(own);
      final firstTile = tilesIn(small, 14, 15).first;
      server.failing.add(firstTile.url(own));
      final r1 = await s.downloadRegion(small, minZoom: 14, maxZoom: 15);
      expect(r1.failed, 1);

      server.failing.clear();
      server.urls.clear();
      final r2 = await s.downloadRegion(small, minZoom: 14, maxZoom: 15);
      expect(r2.failed, 0);
      expect(server.urls, [firstTile.url(own)]);
    });

    test('cancel stops the download early', () async {
      final s = svc(own);
      final f = s.downloadRegion(GeoBounds.khartoum, minZoom: 10, maxZoom: 16);
      await Future<void>.delayed(Duration.zero);
      s.cancel();
      final r = await f;
      expect(r.done, lessThan(tileCount(GeoBounds.khartoum, 10, 16)));
      expect(r.running, isFalse);
    });
  });
}
