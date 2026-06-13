import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/db_helper.dart';
import 'notification_service.dart';

part 'geofence_manager.g.dart';

@riverpod
GeofenceManager geofenceManager(Ref ref) {
  final db = DbHelper.instance;
  final notifications = ref.watch(notificationServiceProvider);
  final manager = GeofenceManager(db: db, notifications: notifications);
  return manager;
}

class GeofenceManager {
  final DbHelper db;
  final NotificationService notifications;
  final GeofenceService _service = GeofenceService.instance;
  
  double _alertRadiusMeters = 500.0; // default 500m
  bool _isInitialized = false;
  bool _isShiftActive = true;

  GeofenceManager({required this.db, required this.notifications});

  void setAlertRadius(double radiusMeters) {
    if (_alertRadiusMeters != radiusMeters) {
      _alertRadiusMeters = radiusMeters;
      if (_isShiftActive) {
        syncGeofences();
      }
    }
  }

  void setShiftActive(bool active) {
    _isShiftActive = active;
    if (active) {
      syncGeofences();
    } else {
      stopMonitoring();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _service.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: false, // Turn off activity recognition to save battery
      allowMockLocations: false,
      printDevLog: false,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
    );

    // Register listeners
    _service.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _service.addStreamErrorListener(_onError);

    _isInitialized = true;
  }

  Future<void> syncGeofences() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isShiftActive) return;

    final packages = await db.getPendingPackagesWithLocation();
    
    // Convert packages to geofences
    // geofence_service package caps at 100 geofences on Android background
    // We filter top 100 packages (ordered by sort_order)
    final limitedPackages = packages.take(100).toList();

    final geofenceList = limitedPackages.map((p) {
      return Geofence(
        id: p.id,
        latitude: p.lat!,
        longitude: p.lng!,
        radius: [
          GeofenceRadius(id: 'r_main', length: _alertRadiusMeters.toDouble()),
        ],
      );
    }).toList();

    await _service.stop();
    if (geofenceList.isNotEmpty) {
      try {
        await _service.start(geofenceList);
      } catch (e) {
        _onError(e);
      }
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _service.stop();
    } catch (_) {}
  }

  Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    if (geofenceStatus == GeofenceStatus.ENTER) {
      final pkg = await db.getPackageById(geofence.id);
      if (pkg != null && pkg.status == 'pending') {
        final title = '📦 Delivery nearby!';
        final receiver = pkg.receiverName ?? 'Package';
        final address = [pkg.street, pkg.barangay, pkg.city].where((s) => s != null && s.isNotEmpty).join(', ');
        
        await notifications.showProximityAlert(
          title: title,
          body: '$receiver — $address',
          packageId: pkg.id,
        );
      }
    }
  }

  void _onError(dynamic error) {
    // Fail silently without crash, log error
    debugPrint('Geofence error: $error');
  }

  void dispose() {
    _service.removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _service.removeStreamErrorListener(_onError);
    _service.clearAllListeners();
    _service.stop();
  }
}
