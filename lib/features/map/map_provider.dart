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

  MapState({required this.markers, this.userPosition});
}

class PackageMarker {
  final Package package;
  final Marker marker;

  PackageMarker({required this.package, required this.marker});
}

@riverpod
class MapStateNotifier extends _$MapStateNotifier {
  @override
  MapState build() {
    final packagesState = ref.watch(packagesNotifierProvider);
    final markers = _generateMarkers(packagesState.packages);
    return MapState(markers: markers);
  }

  void updateUserPosition(LatLng pos) {
    state = MapState(markers: state.markers, userPosition: pos);
  }

  List<PackageMarker> _generateMarkers(List<Package> packages) {
    return packages
        .where((p) => p.lat != null && p.lng != null)
        .map((p) {
          final latLng = LatLng(p.lat!, p.lng!);
          
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
