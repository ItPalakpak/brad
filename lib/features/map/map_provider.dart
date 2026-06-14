import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../packages/packages_provider.dart';
import '../../core/database/db_helper.dart';
import '../../core/theme/tokens.dart';

part 'map_provider.g.dart';

class MapState {
  final List<PackageMarker> markers;
  final LatLng? userPosition;
  final List<LatLng> routePoints;
  final double? roadDistance;
  final int? roadEta;
  final Package? nearestPackage;

  MapState({
    required this.markers,
    this.userPosition,
    this.routePoints = const [],
    this.roadDistance,
    this.roadEta,
    this.nearestPackage,
  });
}

class MapRoute {
  final List<LatLng> points;
  final double distance;
  final int durationMinutes;

  MapRoute({
    required this.points,
    required this.distance,
    required this.durationMinutes,
  });
}

@riverpod
class MapStateNotifier extends _$MapStateNotifier {
  LatLng? _userPosition;
  bool _isFetchingRoute = false;

  @override
  MapState build() {
    final packagesState = ref.watch(packagesNotifierProvider);
    final markers = _generateMarkers(packagesState.packages);
    final nearest = _findNearestPending(markers, _userPosition);

    final userPos = _userPosition;
    if (userPos != null && nearest != null) {
      Future.microtask(() => _updateRoadRoute(userPos, nearest));
    }

    // Preserve previous route points and distance if the nearest package is unchanged
    final previousState = stateOrNull;
    final samePackage = previousState != null && previousState.nearestPackage?.id == nearest?.id;
    final routePoints = samePackage ? previousState.routePoints : const <LatLng>[];
    final roadDistance = samePackage ? previousState.roadDistance : null;
    final roadEta = samePackage ? previousState.roadEta : null;

    return MapState(
      markers: markers,
      userPosition: _userPosition,
      routePoints: routePoints,
      roadDistance: roadDistance,
      roadEta: roadEta,
      nearestPackage: nearest,
    );
  }

  void updateUserPosition(LatLng pos) {
    if (_userPosition?.latitude == pos.latitude && _userPosition?.longitude == pos.longitude) {
      return;
    }
    _userPosition = pos;

    final nearest = _findNearestPending(state.markers, pos);
    
    // Immediately update userPosition in state so the UI reflects location updates instantly
    final previousState = state;
    final samePackage = previousState.nearestPackage?.id == nearest?.id;
    final routePoints = samePackage ? previousState.routePoints : const <LatLng>[];
    final roadDistance = samePackage ? previousState.roadDistance : null;
    final roadEta = samePackage ? previousState.roadEta : null;

    state = MapState(
      markers: state.markers,
      userPosition: pos,
      routePoints: routePoints,
      roadDistance: roadDistance,
      roadEta: roadEta,
      nearestPackage: nearest,
    );
    
    if (nearest != null) {
      _updateRoadRoute(pos, nearest);
    }
  }

  Package? _findNearestPending(List<PackageMarker> markers, LatLng? userPos) {
    if (userPos == null) return null;
    Package? nearest;
    double minDistance = double.infinity;
    for (final pm in markers) {
      final p = pm.package;
      if (p.status == 'pending' && p.lat != null && p.lng != null) {
        final dist = _calculateDistance(userPos, LatLng(p.lat ?? 0.0, p.lng ?? 0.0));
        if (dist < minDistance) {
          minDistance = dist;
          nearest = p;
        }
      }
    }
    return nearest;
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

  Future<MapRoute?> _fetchRoadRoute(LatLng start, LatLng end) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson'
      );
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (json['code'] == 'Ok' && json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0] as Map<String, dynamic>;
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toDouble();
          
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;
          
          final points = coordinates.map((coord) {
            final list = coord as List<dynamic>;
            return LatLng(
              (list[1] as num).toDouble(),
              (list[0] as num).toDouble(),
            );
          }).toList();
          
          return MapRoute(
            points: points,
            distance: distance,
            durationMinutes: (duration / 60.0).round(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching road route: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<void> _updateRoadRoute(LatLng start, Package nearestPkg) async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;
    
    final end = LatLng(nearestPkg.lat ?? 0.0, nearestPkg.lng ?? 0.0);
    final roadRoute = await _fetchRoadRoute(start, end);
    
    _isFetchingRoute = false;
    
    // Check if userPosition or nearestPackage changed in the meantime
    if (_userPosition != start || state.nearestPackage?.id != nearestPkg.id) {
      return;
    }

    if (roadRoute != null) {
      state = MapState(
        markers: state.markers,
        userPosition: start,
        routePoints: roadRoute.points,
        roadDistance: roadRoute.distance,
        roadEta: roadRoute.durationMinutes,
        nearestPackage: nearestPkg,
      );
    } else {
      // Fallback to straight-line distance if API fails/offline
      final dist = _calculateDistance(start, end);
      state = MapState(
        markers: state.markers,
        userPosition: start,
        routePoints: [start, end],
        roadDistance: dist,
        roadEta: (dist / 500.0).round(), // 30 km/h fallback
        nearestPackage: nearestPkg,
      );
    }
  }

  List<PackageMarker> _generateMarkers(List<Package> packages) {
    return packages
        .where((p) => p.lat != null && p.lng != null)
        .map((p) {
          final latLng = LatLng(p.lat ?? 0.0, p.lng ?? 0.0);
          
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

          final marker = Marker(
            point: latLng,
            width: 40,
            height: 40,
            child: Icon(
              Icons.location_pin,
              color: markerColor,
              size: 40,
            ),
          );

          return PackageMarker(package: p, marker: marker);
        })
        .toList();
  }
}

class PackageMarker {
  final Package package;
  final Marker marker;

  PackageMarker({required this.package, required this.marker});
}
