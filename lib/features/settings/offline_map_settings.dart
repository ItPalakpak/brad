import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/section_header.dart';

class OfflineMapSettingsSection extends ConsumerStatefulWidget {
  const OfflineMapSettingsSection({super.key});

  @override
  ConsumerState<OfflineMapSettingsSection> createState() => _OfflineMapSettingsSectionState();
}

class _OfflineMapSettingsSectionState extends ConsumerState<OfflineMapSettingsSection> {
  int _tileCount = 0;
  double _cacheMB = 0.0;
  bool _isLoadingStats = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    final cacheService = ref.read(mapCacheServiceProvider);
    final count = await cacheService.getCachedTileCount();
    final size = await cacheService.getCacheStorageMB();

    if (mounted) {
      setState(() {
        _tileCount = count;
        _cacheMB = size;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _downloadCurrentArea() async {
    final isOnline = ref.read(connectivityNotifierProvider);
    if (!isOnline) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Get current location
      final pos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
      final center = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(8.6074, 124.8957); // default Claveria

      final cacheService = ref.read(mapCacheServiceProvider);
      
      // Download 5km radius over zoom 12-16
      await cacheService.downloadRegion(
        center: center,
        radiusKm: 5.0,
        minZoom: 12,
        maxZoom: 16,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress.percentageProgress / 100.0;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline map tiles downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        _loadStats();
      }
    }
  }

  Future<void> _clearCache() async {
    final tokens = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: OffsetShadowCard(
          backgroundColor: tokens.surface,
          shadowColor: tokens.border,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Clear Cache?',
                style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to clear all offline map tiles? you will need internet to load these areas again.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppStatusColors.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('CLEAR', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(mapCacheServiceProvider).clearCache();
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline map tile cache cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityNotifierProvider);
    final tokens = context.tokens;

    return OffsetShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'OFFLINE MAPS', icon: Icons.map_outlined),
          const SizedBox(height: 16),
          
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text(
              'Stored Cache: $_tileCount tiles (${_cacheMB.toStringAsFixed(1)} MB)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            
            if (_isDownloading) ...[
              const Text('Downloading tiles around current area...', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _downloadProgress, color: tokens.accent, backgroundColor: tokens.surfaceAlt),
              const SizedBox(height: 4),
              Text('${(_downloadProgress * 100).toStringAsFixed(0)}% Completed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ] else ...[
              // Gated download button
              Tooltip(
                message: isOnline ? '' : 'Connect to mobile data to download tiles.',
                child: ElevatedButton.icon(
                  onPressed: isOnline ? _downloadCurrentArea : null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('DOWNLOAD TILES (5KM AREA)'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _tileCount > 0 ? _clearCache : null,
                icon: const Icon(Icons.delete_outline_rounded, color: AppStatusColors.error),
                label: const Text('CLEAR TILE CACHE', style: TextStyle(color: AppStatusColors.error)),
              ),
            ]
          ],
        ],
      ),
    );
  }
}
