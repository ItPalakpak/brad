import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/payment_chip.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../core/database/db_helper.dart';
import 'history_map_provider.dart';

class HistoryMapScreen extends ConsumerStatefulWidget {
  const HistoryMapScreen({super.key});

  @override
  ConsumerState<HistoryMapScreen> createState() => _HistoryMapScreenState();
}

class _HistoryMapScreenState extends ConsumerState<HistoryMapScreen> {
  late final MapController _mapController;
  bool _isMapReady = false;

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

  void _centerOnPoints(List<LatLng> points) {
    if (!_isMapReady || points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15.0);
      return;
    }

    // Find bounding box
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final pt in points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Fit bounds with padding
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(historyMapNotifierProvider);

    // Center map on route/package coordinates once they are loaded
    ref.listen<HistoryMapState>(historyMapNotifierProvider, (prev, next) {
      if (_isMapReady && !next.isLoading && next.routePoints.isNotEmpty) {
        final prevPoints = prev?.routePoints ?? [];
        if (prevPoints.length != next.routePoints.length) {
          _centerOnPoints(next.routePoints);
        }
      }
    });

    final formattedDate = DateFormat('MMM dd, yyyy').format(state.selectedDate);

    // Calculate details for telemetry
    final totalPackages = state.packages.length;
    final deliveredPackages = state.packages.where((p) => p.status == 'delivered').length;
    final distanceText = _formatDistance(state.distanceMeters);
    final durationText = _formatDuration(state.duration);
    final speedText = _calculateAvgSpeed(state.distanceMeters, state.duration);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RIDE TRACKING',
          style: TextStyle(
            color: tokens.text,
            fontFamily: 'Geist',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border(
                bottom: BorderSide(color: tokens.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: formattedDate,
                  icon: Icons.calendar_month_rounded,
                  onTap: () => _pickDate(context, ref, state.selectedDate),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: state.selectedRide == null
                      ? 'No Rides'
                      : 'Ride #${state.selectedRide!.rideNumber}',
                  icon: Icons.directions_bike_rounded,
                  onTap: state.availableRides.isEmpty
                      ? null
                      : () => _showRideSelectionDialog(context, ref, state),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Map layer
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state.selectedRide == null)
                  _buildNoRideState(tokens, formattedDate)
                else
                  RepaintBoundary(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: state.routePoints.isNotEmpty
                            ? state.routePoints.first
                            : const LatLng(8.6074, 124.8957), // Default Claveria
                        initialZoom: 13.0,
                        maxZoom: 18,
                        minZoom: 10,
                        onMapReady: () {
                          setState(() {
                            _isMapReady = true;
                          });
                          if (state.routePoints.isNotEmpty) {
                            _centerOnPoints(state.routePoints);
                          }
                        },
                      ),
                      children: [
                        // Tiles Layer with cache support
                        TileLayer(
                          urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          tileProvider: ref.read(mapCacheServiceProvider).offlineTileProvider,
                          userAgentPackageName: 'com.brad.brad',
                          errorTileCallback: (tile, error, stackTrace) {},
                        ),

                        // Polyline Route Path
                        if (state.routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: state.routePoints,
                                color: const Color(0xFFFC6100), // Strava orange!
                                strokeWidth: 4.5,
                              ),
                            ],
                          ),

                        // Package Markers
                        MarkerLayer(
                          markers: state.packages
                              .where((p) => p.lat != null && p.lng != null)
                              .map((p) {
                            Color markerColor;
                            switch (p.status) {
                              case 'delivered':
                                markerColor = AppStatusColors.success;
                                break;
                              case 'failed':
                                markerColor = AppStatusColors.error;
                                break;
                              case 'returned':
                                markerColor = AppStatusColors.info;
                                break;
                              case 'pending':
                              default:
                                markerColor = AppStatusColors.warning;
                                break;
                            }

                            return Marker(
                              point: LatLng(p.lat!, p.lng!),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showPackageMiniCard(context, p),
                                child: Icon(
                                  Icons.location_pin,
                                  color: markerColor,
                                  size: 40,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                // Strava-like Telemetry Dashboard Overlay
                if (state.selectedRide != null && !state.isLoading)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: OffsetShadowCard(
                      backgroundColor: tokens.surface,
                      shadowColor: tokens.border,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TELEMETRY SUMMARY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                  color: tokens.textSubtle,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFC6100).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFFFC6100), width: 1.0),
                                ),
                                child: const Text(
                                  'STRAVA STYLE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFC6100),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTelemetryStat(
                                label: 'DISTANCE',
                                value: distanceText,
                                valueColor: const Color(0xFFFC6100),
                              ),
                              _buildTelemetryDivider(tokens),
                              _buildTelemetryStat(
                                label: 'TIME',
                                value: durationText,
                                valueColor: tokens.text,
                              ),
                              _buildTelemetryDivider(tokens),
                              _buildTelemetryStat(
                                label: 'AVG PACE',
                                value: speedText,
                                valueColor: tokens.text,
                              ),
                              _buildTelemetryDivider(tokens),
                              _buildTelemetryStat(
                                label: 'DELIVERED',
                                value: '$deliveredPackages/$totalPackages',
                                valueColor: AppStatusColors.success,
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildTelemetryDivider(AppColorTokens tokens) {
    return Container(width: 1.5, height: 32, color: tokens.border);
  }

  Widget _buildTelemetryStat({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border.all(color: tokens.border, width: 1.5),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: tokens.shadowColor,
                offset: const Offset(1.5, 1.5),
                blurRadius: 0,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tokens.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: tokens.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 14,
                  color: tokens.textSubtle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoRideState(AppColorTokens tokens, String dateStr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run_rounded, size: 64, color: tokens.textSubtle),
          const SizedBox(height: 16),
          Text(
            'No rides recorded',
            style: TextStyle(fontSize: 16, color: tokens.text, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select another date or complete a ride on $dateStr',
            style: TextStyle(fontSize: 13, color: tokens.textSubtle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  String _calculateAvgSpeed(double meters, Duration d) {
    if (d.inSeconds == 0) return '0.0 km/h';
    final hours = d.inSeconds / 3600.0;
    final km = meters / 1000.0;
    return '${(km / hours).toStringAsFixed(1)} km/h';
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(historyMapNotifierProvider.notifier).loadForDate(picked);
    }
  }

  void _showRideSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    HistoryMapState state,
  ) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Ride',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tokens.text,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.availableRides.length,
                    itemBuilder: (context, index) {
                      final r = state.availableRides[index];
                      final isSelected = state.selectedRide?.id == r.id;

                      final startTimeStr = DateFormat('hh:mm a').format(r.startedAt);
                      final endTimeStr = r.endedAt != null
                          ? DateFormat('hh:mm a').format(r.endedAt!)
                          : 'Active';

                      return InkWell(
                        onTap: () {
                          ref.read(historyMapNotifierProvider.notifier).selectRide(r);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? tokens.accentSoft : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(color: tokens.border, width: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ride #${r.rideNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? tokens.accent : tokens.text,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '$startTimeStr - $endTimeStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppStatusColors.error,
                    ),
                    child: const Text(
                      'CANCEL',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPackageMiniCard(BuildContext context, Package package) {
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
                      [package.street, package.zone, package.barangay, package.city]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
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
                    child: OffsetShadowButton.outlined(
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
}
