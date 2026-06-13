import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/offset_shadow_card.dart';

class PinPickerSheet extends ConsumerStatefulWidget {
  final LatLng initialLocation;

  const PinPickerSheet({super.key, required this.initialLocation});

  @override
  ConsumerState<PinPickerSheet> createState() => _PinPickerSheetState();
}

class _PinPickerSheetState extends ConsumerState<PinPickerSheet> {
  late MapController _mapController;
  late LatLng _currentCenter;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnMe() async {
    setState(() {
      _isLocating = true;
    });

    final pos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
    
    if (pos != null && mounted) {
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController.move(target, 16.0);
      setState(() {
        _currentCenter = target;
      });
    }

    if (mounted) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.8,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.zero,
        border: Border(
          top: BorderSide(color: tokens.border, width: 2.0),
          left: BorderSide(color: tokens.border, width: 2.0),
          right: BorderSide(color: tokens.border, width: 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor,
            offset: const Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // FlutterMap
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialLocation,
                initialZoom: 15.0,
                maxZoom: 18,
                minZoom: 10,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _currentCenter = position.center;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  tileProvider: ref.read(mapCacheServiceProvider).offlineTileProvider,
                  userAgentPackageName: 'com.brad.brad',
                  errorTileCallback: (tile, error, stackTrace) {},
                ),
              ],
            ),
          ),
          
          // Central Marker Pin (Fixed in Center)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35), // Offset pin anchor point
              child: Icon(
                Icons.location_pin,
                color: tokens.accent,
                size: 44,
                shadows: [
                  Shadow(color: tokens.border, offset: const Offset(2.0, 2.0)),
                ],
              ),
            ),
          ),

          // Top Header Sheet Layout
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: OffsetShadowCard(
              backgroundColor: tokens.surface,
              shadowColor: tokens.border,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.pin_drop_outlined, color: tokens.accent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Drag the map to align the pin with the package location.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Buttons (Center on me) wrapped in offset shadow
          Positioned(
            bottom: 110,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
              ),
              child: FloatingActionButton(
                heroTag: 'picker-gps-fab',
                onPressed: _isLocating ? null : _centerOnMe,
                backgroundColor: tokens.surface,
                foregroundColor: tokens.accent,
                child: _isLocating
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          ),

          // Bottom Confirmation Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.border, width: 2.0)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'COORDINATES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lat: ${_currentCenter.latitude.toStringAsFixed(5)}, Lng: ${_currentCenter.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  OffsetShadowCard(
                    backgroundColor: tokens.accent,
                    shadowColor: tokens.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onTap: () {
                      Navigator.pop(context, _currentCenter);
                    },
                    child: Center(
                      child: Text(
                        'CONFIRM PIN LOCATION',
                        style: TextStyle(
                          color: tokens.textInvert,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
