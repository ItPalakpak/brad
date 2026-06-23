import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';

part 'history_map_provider.g.dart';

class HistoryMapState {
  final DateTime selectedDate;
  final List<Ride> availableRides;
  final Ride? selectedRide;
  final List<Package> packages;
  final List<LatLng> routePoints;
  final double distanceMeters;
  final Duration duration;
  final bool isLoading;

  HistoryMapState({
    required this.selectedDate,
    required this.availableRides,
    this.selectedRide,
    this.packages = const [],
    this.routePoints = const [],
    this.distanceMeters = 0.0,
    this.duration = Duration.zero,
    this.isLoading = false,
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

      // CHANGED: Load actual tracked GPS coordinates first (Strava style tracking)
      List<LatLng> points = await _dbHelper.getRideLocations(ride.id);

      // Fallback: If no location coordinates were recorded (e.g. for mock/seeded data),
      // connect package coordinates in delivery sequence.
      if (points.isEmpty) {
        final sortedPackages = packages.where((p) => p.lat != null && p.lng != null).toList();
        sortedPackages.sort((a, b) {
          if (a.deliveredAt != null && b.deliveredAt != null) {
            return a.deliveredAt!.compareTo(b.deliveredAt!);
          } else if (a.deliveredAt != null) {
            return -1; // delivered first
          } else if (b.deliveredAt != null) {
            return 1;
          } else {
            return a.sortOrder.compareTo(b.sortOrder);
          }
        });
        points = sortedPackages.map((p) => LatLng(p.lat!, p.lng!)).toList();
      }

      // Duration calculation
      Duration duration = Duration.zero;
      if (ride.endedAt != null) {
        duration = ride.endedAt!.difference(ride.startedAt);
      } else {
        duration = DateTime.now().difference(ride.startedAt);
      }

      if (points.length < 2) {
        state = HistoryMapState(
          selectedDate: date,
          availableRides: availableRides,
          selectedRide: ride,
          packages: packages,
          routePoints: points,
          distanceMeters: 0.0,
          duration: duration,
          isLoading: false,
        );
        return;
      }

      // Try fetching road route sequentially from OSRM
      final roadRoute = await _fetchRoadRoute(points);
      if (roadRoute != null) {
        state = HistoryMapState(
          selectedDate: date,
          availableRides: availableRides,
          selectedRide: ride,
          packages: packages,
          routePoints: roadRoute.points,
          distanceMeters: roadRoute.distance,
          duration: duration,
          isLoading: false,
        );
      } else {
        // Fallback: geodesic straight-line distance
        double dist = 0.0;
        for (int i = 0; i < points.length - 1; i++) {
          dist += _calculateDistance(points[i], points[i + 1]);
        }
        state = HistoryMapState(
          selectedDate: date,
          availableRides: availableRides,
          selectedRide: ride,
          packages: packages,
          routePoints: points,
          distanceMeters: dist,
          duration: duration,
          isLoading: false,
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

  Future<HistoryMapRouteData?> _fetchRoadRoute(List<LatLng> points) async {
    final client = HttpClient();
    try {
      final coordsString = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsString'
        '?overview=full&geometries=geojson'
      );
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (json['code'] == 'Ok' && json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0] as Map<String, dynamic>;
          final distance = (route['distance'] as num).toDouble();
          
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;
          
          final routePoints = coordinates.map((coord) {
            final list = coord as List<dynamic>;
            return LatLng(
              (list[1] as num).toDouble(),
              (list[0] as num).toDouble(),
            );
          }).toList();
          
          return HistoryMapRouteData(
            points: routePoints,
            distance: distance,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching history road route from OSRM: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
