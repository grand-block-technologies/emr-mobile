import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'tile_math.dart';

/// Downloads one tile. Abstract so tests never touch the network.
typedef TileFetcher = Future<Uint8List> Function(String url);

/// OSM tile usage policy: a valid User-Agent, no auth headers, and caching of what was fetched.
/// A separate Dio from the API client, so the bearer token never goes to a tile server.
TileFetcher dioTileFetcher({
  String userAgent = 'EMR-MR-crew/1.0 (sd.gov.emr.crew)',
}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.bytes,
      headers: {'User-Agent': userAgent},
    ),
  );
  return (url) async =>
      Uint8List.fromList((await dio.get<List<int>>(url)).data!);
}

/// The public OpenStreetMap servers forbid bulk downloads and prefetching unviewed tiles.
/// Region downloads are allowed only from a tile server we control or one that permits it.
bool bulkDownloadAllowed(String urlTemplate) {
  final host =
      Uri.tryParse(urlTemplate.replaceAll(RegExp(r'\{[a-z]\}'), 'a'))?.host ??
      '';
  return host.isNotEmpty &&
      !host.endsWith('openstreetmap.org') &&
      !host.endsWith('openstreetmap.fr');
}

/// Disk cache for map tiles: cache first, network to refresh old tiles, and any cached copy
/// (however old) when the network is gone. Size-capped with oldest-first eviction.
class TileStore {
  TileStore({
    required this.dir,
    required TileFetcher fetch,
    this.maxBytes = 300 * 1024 * 1024,
    this.freshFor = const Duration(days: 30),
    DateTime Function()? now,
  }) : _fetch = fetch,
       _now = now ?? DateTime.now;

  final Directory dir;
  final TileFetcher _fetch;
  final int maxBytes;
  final Duration freshFor;
  final DateTime Function() _now;

  int? _bytes;
  final _inFlight = <TileId, Future<Uint8List?>>{};

  File _file(TileId t) => File('${dir.path}/${t.path}');

  Future<bool> has(TileId t) => _file(t).exists();

  /// Removes one unusable cache entry. This is used when a proxy returned an
  /// HTML/error body with a successful HTTP status instead of a tile image.
  Future<void> remove(TileId t) async {
    final f = _file(t);
    if (!await f.exists()) return;
    final length = await f.length();
    await f.delete();
    if (_bytes != null) _bytes = (_bytes! - length).clamp(0, maxBytes);
  }

  /// Bytes for [t]: fresh cache, else network (then cached), else stale cache, else null.
  Future<Uint8List?> load(
    TileId t,
    String urlTemplate,
  ) => _inFlight[t] ??= _load(t, urlTemplate).whenComplete(() {
    // A block body on purpose: `=> _inFlight.remove(t)` would return this very future
    // to whenComplete, which would then wait on itself forever.
    _inFlight.remove(t);
  });

  Future<Uint8List?> _load(TileId t, String urlTemplate) async {
    final f = _file(t);
    final cached = await f.exists();
    if (cached && _now().difference(await f.lastModified()) < freshFor) {
      return f.readAsBytes();
    }
    try {
      final bytes = await _fetch(t.url(urlTemplate));
      await _write(f, bytes);
      return bytes;
    } on Object {
      return cached ? f.readAsBytes() : null;
    }
  }

  /// Downloads [t] if it is not cached yet. Returns true when a download happened.
  Future<bool> ensure(TileId t, String urlTemplate) async {
    if (await has(t)) {
      return false;
    }
    final bytes = await _fetch(t.url(urlTemplate));
    await _write(_file(t), bytes);
    return true;
  }

  Future<void> _write(File f, Uint8List bytes) async {
    final before = await sizeBytes();
    await f.parent.create(recursive: true);
    final old = await f.exists() ? await f.length() : 0;
    await f.writeAsBytes(bytes, flush: true);
    await f.setLastModified(_now());
    _bytes = before - old + bytes.length;
    if (_bytes! > maxBytes) await _evict();
  }

  Future<int> sizeBytes() async {
    if (_bytes != null) return _bytes!;
    var n = 0;
    if (await dir.exists()) {
      await for (final e in dir.list(recursive: true)) {
        if (e is File) n += await e.length();
      }
    }
    return _bytes = n;
  }

  /// Deletes the oldest tiles until the cache is at 80 % of [maxBytes].
  Future<void> _evict() async {
    final files = <(File, DateTime, int)>[];
    await for (final e in dir.list(recursive: true)) {
      if (e is File) files.add((e, await e.lastModified(), await e.length()));
    }
    files.sort((a, b) => a.$2.compareTo(b.$2));
    var total = files.fold<int>(0, (s, f) => s + f.$3);
    final target = (maxBytes * 0.8).floor();
    for (final (file, _, len) in files) {
      if (total <= target) break;
      await file.delete();
      total -= len;
    }
    _bytes = total;
  }

  Future<void> clear() async {
    if (await dir.exists()) await dir.delete(recursive: true);
    _bytes = 0;
  }
}
