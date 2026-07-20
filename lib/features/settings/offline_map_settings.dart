import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
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

  List<String> _barangays = ['My Location'];
  String _selectedTarget = 'My Location';
  double _selectedRadius = 5.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadBarangays();
  }

  Future<void> _loadBarangays() async {
    try {
      final list = await DbHelper.instance.getUniqueBarangays();
      if (mounted) {
        setState(() {
          _barangays = ['My Location', ...list];
        });
      }
    } catch (e) {
      debugPrint('Error loading barangays for map: $e');
    }
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

  Future<void> _downloadOfflineMap() async {
    final isOnline = ref.read(connectivityNotifierProvider);
    if (!isOnline) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      LatLng center = const LatLng(8.6074, 124.8957); // default Claveria
      
      if (_selectedTarget == 'My Location') {
        final pos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
        if (pos != null) {
          center = LatLng(pos.latitude, pos.longitude);
        }
      } else {
        final db = await DbHelper.instance.database;
        final res = await db.query(
          'packages',
          columns: ['lat', 'lng'],
          where: 'barangay = ? AND lat IS NOT NULL AND lng IS NOT NULL',
          limit: 1,
        );
        if (res.isNotEmpty) {
          final lat = (res.first['lat'] as num).toDouble();
          final lng = (res.first['lng'] as num).toDouble();
          center = LatLng(lat, lng);
        }
      }

      final cacheService = ref.read(mapCacheServiceProvider);
      
      // Download selected radius over zoom 12-16
      await cacheService.downloadRegion(
        center: center,
        radiusKm: _selectedRadius,
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
                style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
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
                    style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
                    child: const Text('CANCEL', textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  OffsetShadowButton.elevated(
                    backgroundColor: AppStatusColors.error,
                    foregroundColor: Colors.white,
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('CLEAR'),
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
              const Text('Downloading tiles for selected area...', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _downloadProgress, color: tokens.accent, backgroundColor: tokens.surfaceAlt),
              const SizedBox(height: 4),
              Text('${(_downloadProgress * 100).toStringAsFixed(0)}% Completed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ] else ...[
              // Delivery Zone Target Selector
              Text(
                'TARGET ZONE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.textSubtle,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border.all(color: tokens.border, width: 2.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTarget,
                    isExpanded: true,
                    dropdownColor: tokens.surface,
                    style: TextStyle(color: tokens.text, fontWeight: FontWeight.bold),
                    items: _barangays.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTarget = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Radius Selector
              Text(
                'DOWNLOAD RADIUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.textSubtle,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border.all(color: tokens.border, width: 2.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _selectedRadius,
                    isExpanded: true,
                    dropdownColor: tokens.surface,
                    style: TextStyle(color: tokens.text, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 2.0, child: Text('2 KM Radius (approx 200 tiles)')),
                      DropdownMenuItem(value: 5.0, child: Text('5 KM Radius (approx 1200 tiles)')),
                      DropdownMenuItem(value: 10.0, child: Text('10 KM Radius (approx 5000 tiles)')),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRadius = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gated download button
              Tooltip(
                message: isOnline ? '' : 'Connect to mobile data to download tiles.',
                child: OffsetShadowButton.icon(
                  onPressed: isOnline ? _downloadOfflineMap : null,
                  icon: const Icon(Icons.download_rounded),
                  label: Text('DOWNLOAD ZONE TILES'),
                ),
              ),
              const SizedBox(height: 8),
              OffsetShadowButton.icon(
                variant: OffsetButtonVariant.outlined,
                onPressed: _tileCount > 0 ? _clearCache : null,
                foregroundColor: AppStatusColors.error,
                borderColor: tokens.border,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('CLEAR TILE CACHE'),
              ),
            ]
          ],
        ],
      ),
    );
  }
}
