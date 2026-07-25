import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';
import '../../shared/utils/route_smoother.dart';

part 'history_map_provider.g.dart';

// CHANGED: Added DeliveryTraceStats to store distance, interval and timestamp for delivered packages on a ride
class DeliveryTraceStats {
  final String packageId;
  final DateTime deliveredAt;
  final double distanceMeters;
  final Duration interval;

  DeliveryTraceStats({
    required this.packageId,
    required this.deliveredAt,
    required this.distanceMeters,
    required this.interval,
  });
}

class TimedCoordinate {
  final LatLng coordinate;
  final DateTime timestamp;
  final bool isPackageDelivery;

  TimedCoordinate({
    required this.coordinate,
    required this.timestamp,
    this.isPackageDelivery = false,
  });
}

class HistoryMapState {
  final DateTime selectedDate;
  final List<Ride> availableRides;
  final Ride? selectedRide;
  final List<Package> packages;
  final List<LatLng> routePoints;
  final double distanceMeters;
  final Duration duration;
  final bool isLoading;
  // CHANGED: Add deliveryStats map to associate delivered packages with their true route telemetry
  final Map<String, DeliveryTraceStats> deliveryStats;
  // CHANGED: Add deliverySequence map (packageId -> 1-based index)
  final Map<String, int> deliverySequence;

  HistoryMapState({
    required this.selectedDate,
    required this.availableRides,
    this.selectedRide,
    this.packages = const [],
    this.routePoints = const [],
    this.distanceMeters = 0.0,
    this.duration = Duration.zero,
    this.isLoading = false,
    this.deliveryStats = const {},
    this.deliverySequence = const {},
  });

  HistoryMapState copyWith({
    DateTime? selectedDate,
    List<Ride>? availableRides,
    Ride? selectedRide,
    List<Package>? packages,
    List<LatLng>? routePoints,
    double? distanceMeters,
    Duration? duration,
    bool? isLoading,
    Map<String, DeliveryTraceStats>? deliveryStats,
    Map<String, int>? deliverySequence,
  }) {
    return HistoryMapState(
      selectedDate: selectedDate ?? this.selectedDate,
      availableRides: availableRides ?? this.availableRides,
      selectedRide: selectedRide, // We allow setting to null or a new value
      packages: packages ?? this.packages,
      routePoints: routePoints ?? this.routePoints,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
      deliveryStats: deliveryStats ?? this.deliveryStats,
      deliverySequence: deliverySequence ?? this.deliverySequence,
    );
  }
}

class HistoryMapRouteData {
  final List<LatLng> points;
  final double distance;

  HistoryMapRouteData({required this.points, required this.distance});
}

@riverpod
class HistoryMapNotifier extends _$HistoryMapNotifier {
  final DbHelper _dbHelper = DbHelper.instance;

  @override
  HistoryMapState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Future.microtask(() => loadForDate(today));
    return HistoryMapState(
      selectedDate: today,
      availableRides: const [],
      isLoading: true,
    );
  }

  Future<void> loadForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, selectedDate: date);
    try {
      final rides = await _dbHelper.getRidesForDate(date);
      if (rides.isEmpty) {
        state = HistoryMapState(
          selectedDate: date,
          availableRides: const [],
          selectedRide: null,
          packages: const [],
          routePoints: const [],
          distanceMeters: 0.0,
          duration: Duration.zero,
          isLoading: false,
        );
        return;
      }

      // Auto-select the first ride
      final selectedRide = rides.first;
      await _loadRideData(selectedRide, rides, date);
    } catch (e) {
      debugPrint('Error loading history map date: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectRide(Ride ride) async {
    state = state.copyWith(isLoading: true);
    await _loadRideData(ride, state.availableRides, state.selectedDate);
  }

  Future<void> _loadRideData(Ride ride, List<Ride> availableRides, DateTime date) async {
    try {
      // Query packages for this ride
      final packages = await _dbHelper.getPackagesForRide(ride.id);

      // Load actual tracked GPS coordinates logged during the ride (startRide -> endRide)
      final rawLocations = await _dbHelper.getRideLocationsWithTimestamps(ride.id);

      List<LatLng> rawPoints = [];
      for (final loc in rawLocations) {
        final lat = loc['lat'] as double?;
        final lng = loc['lng'] as double?;
        if (lat != null && lng != null) {
          rawPoints.add(LatLng(lat, lng));
        }
      }

      // Compute delivery sequence numbers for delivered packages (1, 2, 3...)
      final Map<String, int> deliverySequence = {};
      final Map<String, DeliveryTraceStats> deliveryStats = {};
      final deliveredPkgs = packages
          .where((p) => p.status == 'delivered' && p.deliveredAt != null)
          .toList()
        ..sort((a, b) => a.deliveredAt!.compareTo(b.deliveredAt!));

      for (int i = 0; i < deliveredPkgs.length; i++) {
        final pkg = deliveredPkgs[i];
        deliverySequence[pkg.id] = i + 1;
      }

      DateTime lastTime = ride.startedAt;
      LatLng? lastLatLng = rawPoints.isNotEmpty ? rawPoints.first : null;

      for (int i = 0; i < deliveredPkgs.length; i++) {
        final pkg = deliveredPkgs[i];
        final pkgTime = pkg.deliveredAt!;

        final segmentPoints = rawLocations.where((loc) {
          final tsStr = loc['timestamp'] as String?;
          if (tsStr == null) return false;
          final t = DateTime.tryParse(tsStr);
          if (t == null) return false;
          return t.isAfter(lastTime) && !t.isAfter(pkgTime);
        }).toList();

        double segmentDistance = 0.0;
        LatLng? currentLatLng = lastLatLng;

        for (final loc in segmentPoints) {
          final nextPt = LatLng(loc['lat'] as double, loc['lng'] as double);
          if (currentLatLng != null) {
            segmentDistance += _calculateDistance(currentLatLng, nextPt);
          }
          currentLatLng = nextPt;
        }

        if (pkg.lat != null && pkg.lng != null) {
          final pkgPt = LatLng(pkg.lat!, pkg.lng!);
          if (currentLatLng != null) {
            segmentDistance += _calculateDistance(currentLatLng, pkgPt);
          }
          currentLatLng = pkgPt;
        }

        if (segmentDistance == 0.0 && pkg.lat != null && pkg.lng != null) {
          if (i > 0) {
            final prevPkg = deliveredPkgs[i - 1];
            if (prevPkg.lat != null && prevPkg.lng != null) {
              segmentDistance = _calculateDistance(LatLng(prevPkg.lat!, prevPkg.lng!), LatLng(pkg.lat!, pkg.lng!));
            }
          } else if (lastLatLng != null) {
            segmentDistance = _calculateDistance(lastLatLng, LatLng(pkg.lat!, pkg.lng!));
          }
        }

        final interval = pkgTime.difference(lastTime);

        deliveryStats[pkg.id] = DeliveryTraceStats(
          packageId: pkg.id,
          deliveredAt: pkgTime,
          distanceMeters: segmentDistance,
          interval: interval,
        );

        lastTime = pkgTime;
        lastLatLng = currentLatLng;
      }

      // Fallback: If no location coordinates were recorded (e.g. for mock/seeded data),
      // connect package coordinates in delivery sequence.
      if (rawPoints.isEmpty) {
        final sortedPackages = packages.where((p) => p.lat != null && p.lng != null).toList();
        sortedPackages.sort((a, b) {
          if (a.deliveredAt != null && b.deliveredAt != null) {
            return a.deliveredAt!.compareTo(b.deliveredAt!);
          } else if (a.deliveredAt != null) {
            return -1;
          } else if (b.deliveredAt != null) {
            return 1;
          } else {
            return a.sortOrder.compareTo(b.sortOrder);
          }
        });
        rawPoints = sortedPackages.map((p) => LatLng(p.lat!, p.lng!)).toList();
      }

      // Duration calculation
      Duration duration = Duration.zero;
      if (ride.endedAt != null) {
        duration = ride.endedAt!.difference(ride.startedAt);
      } else {
        duration = DateTime.now().difference(ride.startedAt);
      }

      if (rawPoints.isEmpty) {
        state = HistoryMapState(
          selectedDate: date,
          availableRides: availableRides,
          selectedRide: ride,
          packages: packages,
          routePoints: const [],
          distanceMeters: 0.0,
          duration: duration,
          isLoading: false,
          deliveryStats: deliveryStats,
          deliverySequence: deliverySequence,
        );
        return;
      }

      // Apply offline noise reduction & Douglas-Peucker simplification
      final List<LatLng> offlineSmoothed = RouteSmoother.smoothRoute(rawPoints);

      // Try fetching map-matched road route from OSRM (online upgrade)
      final mapMatchedRoute = await _fetchMapMatchedRoute(offlineSmoothed);
      
      if (mapMatchedRoute != null && mapMatchedRoute.points.isNotEmpty) {
        state = HistoryMapState(
          selectedDate: date,
          availableRides: availableRides,
          selectedRide: ride,
          packages: packages,
          routePoints: mapMatchedRoute.points,
          distanceMeters: mapMatchedRoute.distance,
          duration: duration,
          isLoading: false,
          deliveryStats: deliveryStats,
          deliverySequence: deliverySequence,
        );
      } else {
        // Offline primary fallback: calculate distance along offline smoothed trace
        double dist = 0.0;
        for (int i = 0; i < offlineSmoothed.length - 1; i++) {
          dist += _calculateDistance(offlineSmoothed[i], offlineSmoothed[i + 1]);
        }
        state = HistoryMapState(
          selectedDate: date,
          availableRides: availableRides,
          selectedRide: ride,
          packages: packages,
          routePoints: offlineSmoothed,
          distanceMeters: dist,
          duration: duration,
          isLoading: false,
          deliveryStats: deliveryStats,
          deliverySequence: deliverySequence,
        );
      }
    } catch (e) {
      debugPrint('Error loading ride data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // in meters
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadius * c;
  }

  Future<HistoryMapRouteData?> _fetchMapMatchedRoute(List<LatLng> points) async {
    if (points.length < 2) return null;
    final client = HttpClient();
    try {
      // OSRM match API has a ~100 waypoint limit per request, batch into chunks if needed
      const chunkSize = 80;
      List<LatLng> matchedPoints = [];
      double totalDistance = 0.0;

      for (int i = 0; i < points.length; i += chunkSize - 1) {
        final end = math.min(i + chunkSize, points.length);
        final chunk = points.sublist(i, end);
        if (chunk.length < 2) break;

        final coordsString = chunk.map((p) => '${p.longitude},${p.latitude}').join(';');
        final uri = Uri.parse(
          'https://router.project-osrm.org/match/v1/driving/$coordsString'
          '?overview=full&geometries=geojson'
        );
        final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
        final response = await request.close();

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(responseBody) as Map<String, dynamic>;

          if (json['code'] == 'Ok' && json['matchings'] != null && json['matchings'].isNotEmpty) {
            final matchings = json['matchings'] as List<dynamic>;
            for (final m in matchings) {
              final matchMap = m as Map<String, dynamic>;
              totalDistance += (matchMap['distance'] as num? ?? 0.0).toDouble();

              final geometry = matchMap['geometry'] as Map<String, dynamic>;
              final coordinates = geometry['coordinates'] as List<dynamic>;

              final pts = coordinates.map((coord) {
                final list = coord as List<dynamic>;
                return LatLng(
                  (list[1] as num).toDouble(),
                  (list[0] as num).toDouble(),
                );
              }).toList();

              matchedPoints.addAll(pts);
            }
          }
        }
      }

      if (matchedPoints.isNotEmpty) {
        return HistoryMapRouteData(
          points: matchedPoints,
          distance: totalDistance,
        );
      }
    } catch (e) {
      debugPrint('Error fetching map-matched route from OSRM: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
