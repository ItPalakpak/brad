import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/payment_chip.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/barcode_scanner_dialog.dart';
import '../../shared/utils/currency_formatter.dart';
import '../packages/packages_provider.dart';
import '../../core/database/db_helper.dart';
import 'map_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late MapController _mapController;
  bool _isLocating = false;
  bool _isMapReady = false;
  
  // Pin Mode States
  bool _isPinMode = false;
  LatLng _mapCenter = const LatLng(8.6074, 124.8957); // Default Claveria Coords

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnMe() async {
    if (!_isMapReady) return;

    setState(() {
      _isLocating = true;
    });

    final pos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
    
    if (pos != null && mounted) {
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController.move(target, 15.0);
      ref.read(mapStateNotifierProvider.notifier).updateUserPosition(target);
    }

    if (mounted) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _showPackageMiniCard(Package package) {
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    package.trackingNumber,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StatusBadge(status: package.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                package.receiverName ?? 'Unnamed Receiver',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: tokens.textSubtle),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [package.street, package.zone, package.barangay, package.city].where((s) => s != null && s.isNotEmpty).join(', '),
                      style: TextStyle(color: tokens.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PaymentChip(type: package.paymentType),
                  if (package.paymentType != 'prepaid')
                    Text(
                      CurrencyFormatter.format(package.totalCod),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OffsetShadowCard(
                      backgroundColor: tokens.accent,
                      shadowColor: tokens.border,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/packages/${package.id}');
                      },
                      child: Center(
                        child: Text(
                          'VIEW DETAILS',
                          style: TextStyle(
                            color: tokens.textInvert,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  void _showNewPinForm(LatLng pos) {
    final trackingController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final tokens = context.tokens;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: OffsetShadowCard(
            backgroundColor: tokens.surface,
            shadowColor: tokens.border,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pin New Package Location',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                    ),
                    child: TextFormField(
                      controller: trackingController,
                      decoration: InputDecoration(
                        labelText: 'Tracking Number *',
                        hintText: 'e.g. TRK-481920',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          onPressed: () async {
                            final scanned = await BarcodeScannerDialog.scan(context);
                            if (scanned != null && scanned.isNotEmpty) {
                              trackingController.text = scanned;
                            }
                          },
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Tracking number is required';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                    ),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Receiver Name',
                        hintText: 'e.g. Maria Santos',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(context);

                          final tracking = trackingController.text.trim();
                          final name = nameController.text.trim();

                          String finalStreet = '';
                          String finalBarangay = '';
                          String finalCity = 'Claveria';
                          try {
                            final placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
                            if (placemarks.isNotEmpty) {
                              final place = placemarks.first;
                              finalBarangay = place.subLocality ?? '';
                              finalCity = place.locality ?? 'Claveria';
                              finalStreet = place.street ?? '';
                              if (finalStreet == finalBarangay || finalStreet == finalCity) {
                                finalStreet = place.thoroughfare ?? '';
                              }
                            }
                          } catch (e) {
                            debugPrint('Geocoding error in map pinning: $e');
                          }

                          final newPkg = Package(
                            id: const Uuid().v4(),
                            trackingNumber: tracking,
                            receiverName: name.isEmpty ? null : name,
                            lat: pos.latitude,
                            lng: pos.longitude,
                            street: finalStreet.isEmpty ? null : finalStreet,
                            barangay: finalBarangay.isEmpty ? null : finalBarangay,
                            city: finalCity,
                            paymentType: 'cod_cash',
                            codCash: 0.0,
                            codDigital: 0.0,
                            tips: 0.0,
                            extraAmount: 0.0,
                            status: 'pending',
                            sortOrder: 0,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          await ref.read(packagesNotifierProvider.notifier).addPackage(newPkg);
                          setState(() {
                            _isPinMode = false;
                          });
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Package registered and pinned successfully!'),
                              ),
                            );
                          }
                        },
                        child: const Text('PIN PACKAGE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time location stream and update user position
    ref.listen<AsyncValue<Position>>(locationStreamProvider, (prev, next) {
      next.whenData((pos) {
        final target = LatLng(pos.latitude, pos.longitude);
        ref.read(mapStateNotifierProvider.notifier).updateUserPosition(target);
        // Center the map on user location the first time it loads
        if (_isMapReady && (prev == null || !prev.hasValue)) {
          _mapController.move(target, 15.0);
        }
      });
    });

    final tokens = context.tokens;
    final mapState = ref.watch(mapStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(type: BrandLogoType.icon, height: 32),
            const SizedBox(width: 8),
            Text(
              'MAP OVERVIEW',
              style: TextStyle(
                color: tokens.text,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isPinMode ? Icons.close_rounded : Icons.add_location_alt_outlined),
            tooltip: _isPinMode ? 'Exit Pin Mode' : 'Pin Mode',
            onPressed: () {
              setState(() {
                _isPinMode = !_isPinMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: Stack(
              children: [
                // RepaintBoundary around Map for performance
                RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapState.userPosition ?? const LatLng(8.6074, 124.8957), // User Pos or Claveria Coords
                      initialZoom: 13.0,
                      maxZoom: 18,
                      minZoom: 10,
                      onPositionChanged: (position, hasGesture) {
                        if (hasGesture) {
                          _mapCenter = position.center;
                        }
                      },
                      onMapReady: () {
                        setState(() {
                          _isMapReady = true;
                        });
                        _centerOnMe();
                      },
                    ),
                    children: [
                      // Tile Layer using Google Maps
                      TileLayer(
                        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        tileProvider: ref.read(mapCacheServiceProvider).offlineTileProvider,
                        userAgentPackageName: 'com.brad.brad',
                        errorTileCallback: (tile, error, stackTrace) {
                          // Fail silently without crash
                        },
                      ),

                      // Route guidance: line to nearest pending package
                      if (mapState.userPosition != null && mapState.nearestPackage != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: mapState.routePoints.isNotEmpty
                                  ? mapState.routePoints
                                  : [
                                      mapState.userPosition!,
                                      LatLng(mapState.nearestPackage!.lat!, mapState.nearestPackage!.lng!),
                                    ],
                              color: tokens.accent,
                              strokeWidth: 3.5,
                              pattern: StrokePattern.dashed(segments: [6, 6]),
                            ),
                          ],
                        ),

                      // Package Markers
                      MarkerLayer(
                        markers: mapState.markers.map((pm) {
                          return Marker(
                            point: pm.marker.point,
                            width: pm.marker.width,
                            height: pm.marker.height,
                            child: GestureDetector(
                              onTap: () => _showPackageMiniCard(pm.package),
                              child: pm.marker.child,
                            ),
                          );
                        }).toList(),
                      ),

                      // User GPS position marker
                      if (mapState.userPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: mapState.userPosition!,
                              width: 30,
                              height: 30,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Map Offline warning overlay
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Center(
                        child: Text(
                          'Some map areas not cached — download in Settings',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),

                // Crosshair indicator (Fixed center - visible in Pin Mode)
                if (_isPinMode) ...[
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20), // offset
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        color: tokens.accent,
                        size: 40,
                        shadows: [
                          Shadow(color: tokens.border, offset: const Offset(1.5, 1.5)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 96,
                    left: 24,
                    right: 24,
                    child: OffsetShadowCard(
                      backgroundColor: tokens.surface,
                      shadowColor: tokens.border,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onTap: () {
                        _showNewPinForm(_mapCenter);
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pin_drop_rounded, color: tokens.accent, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'CONFIRM NEW PIN HERE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Nearest Pending Package Info Card (Bottom-left)
                if (!_isPinMode && mapState.userPosition != null && mapState.nearestPackage != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 80, // Leave space for center-on-me floating action button
                    child: OffsetShadowCard(
                      backgroundColor: tokens.surface,
                      shadowColor: tokens.border,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () {
                        _showPackageMiniCard(mapState.nearestPackage!);
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tokens.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Transform.rotate(
                              angle: 45 * 3.14159 / 180, // Point it towards top-right
                              child: Icon(Icons.navigation_outlined, color: tokens.accent, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'NEAREST:',
                                      style: TextStyle(
                                        color: tokens.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        mapState.nearestPackage!.trackingNumber,
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mapState.nearestPackage!.receiverName ?? 'Unnamed Receiver',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDistance(mapState.roadDistance ?? 0.0),
                                style: TextStyle(
                                  color: tokens.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                mapState.roadEta != null
                                    ? '~${mapState.roadEta} min'
                                    : '-- min',
                                style: TextStyle(
                                  color: tokens.textSubtle,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Centering GPS button wrapped in offset shadow
                if (!_isPinMode)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                      ),
                      child: FloatingActionButton(
                        heroTag: 'map-gps-fab',
                        onPressed: _isLocating ? null : _centerOnMe,
                        backgroundColor: tokens.surface,
                        foregroundColor: tokens.accent,
                        child: _isLocating
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
