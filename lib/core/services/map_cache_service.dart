import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';

part 'map_cache_service.g.dart';

@riverpod
MapCacheService mapCacheService(Ref ref) {
  return MapCacheService();
}

class MapCacheService {
  static const _storeName = 'ridertrack_tiles';

  Future<void> init() async {
    // CHANGED: Initialise map tile cache backend in app documents directory safely without requiring raw external storage permissions
    try {
      Directory? persistentDir;
      try {
        if (!kIsWeb) {
          final appDocDir = await getApplicationDocumentsDirectory();
          persistentDir = Directory('${appDocDir.path}/BRAD_map_tiles');
          if (!await persistentDir.exists()) {
            await persistentDir.create(recursive: true);
          }
        }
      } catch (e) {
        debugPrint('Error creating map tile directory: $e');
      }

      await FMTCObjectBoxBackend().initialise(
        rootDirectory: persistentDir?.path,
      );
      await FMTCStore(_storeName).manage.create();
    } catch (e) {
      debugPrint('FMTC map tile cache initialization error: $e');
    }
  }

  // Called from map screen TileLayer:
  TileProvider get offlineTileProvider {
    return FMTCStore(_storeName).getTileProvider(
      settings: FMTCTileProviderSettings(
        behavior: CacheBehavior.cacheFirst, // serve cache, fallback to network
        cachedValidDuration: const Duration(days: 30),
      ),
    );
  }

  // Download a region around a LatLng point
  Future<void> downloadRegion({
    required LatLng center,
    required double radiusKm,
    int minZoom = 12,
    int maxZoom = 17,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final region = CircleRegion(center, radiusKm);
    
    // Create download instance
    final downloadable = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
      ),
    );

    final stream = FMTCStore(_storeName).download.startForeground(
      region: downloadable,
      parallelThreads: 2,
      maxBufferLength: 100,
      skipExistingTiles: true,
    );

    await for (final progress in stream) {
      onProgress?.call(progress);
    }
  }

  Future<int> getCachedTileCount() async {
    try {
      return await FMTCStore(_storeName).stats.length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> getCacheStorageMB() async {
    try {
      final sizeKiB = await FMTCStore(_storeName).stats.size;
      return sizeKiB / 1024.0; // convert KiB to MB
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> clearCache() async {
    await FMTCStore(_storeName).manage.reset();
  }
}
