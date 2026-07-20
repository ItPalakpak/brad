import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/database/db_helper.dart';
import '../../core/services/geofence_manager.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import 'package:sqflite/sqflite.dart';
import '../settings/badges_provider.dart';

part 'packages_provider.g.dart';

class PackagesState {
  final List<Package> packages;
  final String searchQuery;
  final List<String> statusFilters;
  final List<String> barangayFilters;
  final List<String> paymentTypeFilters;
  final bool isLoading;
  final PaymentSummary summary;
  final List<String> uniqueBarangays;
  final List<String> uniqueCities;
  final List<String> uniqueStatuses;
  final List<String> uniquePaymentTypes;
  final List<String> uniqueStreets;
  final List<String> uniqueZones;
  final Ride? activeRide;
  final List<Ride> todayRides;

  PackagesState({
    required this.packages,
    this.searchQuery = '',
    this.statusFilters = const [],
    this.barangayFilters = const [],
    this.paymentTypeFilters = const [],
    this.isLoading = false,
    required this.summary,
    required this.uniqueBarangays,
    required this.uniqueCities,
    this.uniqueStatuses = const [],
    this.uniquePaymentTypes = const [],
    this.uniqueStreets = const [],
    this.uniqueZones = const [],
    this.activeRide,
    this.todayRides = const [],
  });

  PackagesState copyWith({
    List<Package>? packages,
    String? searchQuery,
    List<String>? statusFilters,
    List<String>? barangayFilters,
    List<String>? paymentTypeFilters,
    bool? isLoading,
    PaymentSummary? summary,
    List<String>? uniqueBarangays,
    List<String>? uniqueCities,
    List<String>? uniqueStatuses,
    List<String>? uniquePaymentTypes,
    List<String>? uniqueStreets,
    List<String>? uniqueZones,
    Object? activeRide = const Object(),
    List<Ride>? todayRides,
  }) {
    return PackagesState(
      packages: packages ?? this.packages,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilters: statusFilters ?? this.statusFilters,
      barangayFilters: barangayFilters ?? this.barangayFilters,
      paymentTypeFilters: paymentTypeFilters ?? this.paymentTypeFilters,
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      uniqueBarangays: uniqueBarangays ?? this.uniqueBarangays,
      uniqueCities: uniqueCities ?? this.uniqueCities,
      uniqueStatuses: uniqueStatuses ?? this.uniqueStatuses,
      uniquePaymentTypes: uniquePaymentTypes ?? this.uniquePaymentTypes,
      uniqueStreets: uniqueStreets ?? this.uniqueStreets,
      uniqueZones: uniqueZones ?? this.uniqueZones,
      activeRide: activeRide == const Object() ? this.activeRide : (activeRide as Ride?),
      todayRides: todayRides ?? this.todayRides,
    );
  }
}

@riverpod
AsyncValue<Position>? activeRideLocation(Ref ref) {
  final activeRide = ref.watch(packagesNotifierProvider.select((s) => s.activeRide));
  if (activeRide == null) return null;
  return ref.watch(locationStreamProvider);
}

@riverpod
class PackagesNotifier extends _$PackagesNotifier {
  final DbHelper _dbHelper = DbHelper.instance;

  @override
  PackagesState build() {
    // BUG-21 FIX: Filter out low-accuracy GPS fixes before recording ride locations.
    // Positions with accuracy > 50m are likely cell-tower triangulation and produce noisy routes.
    ref.listen<AsyncValue<Position>?>(activeRideLocationProvider, (prev, next) {
      if (next != null) {
        next.whenData((pos) async {
          final active = state.activeRide;
          if (active != null && pos.accuracy <= 50.0) {
            await _dbHelper.insertRideLocation(
              active.id,
              pos.latitude,
              pos.longitude,
            );
          }
        });
      }
    });

    // Start initial loading
    Future.microtask(() => refresh());
    return PackagesState(
      packages: [],
      isLoading: true,
      summary: PaymentSummary.empty(),
      uniqueBarangays: [],
      uniqueCities: [],
      statusFilters: [],
      barangayFilters: [],
      paymentTypeFilters: [],
      uniqueStatuses: [],
      uniquePaymentTypes: [],
      uniqueStreets: [],
      uniqueZones: [],
      activeRide: null,
      todayRides: const [],
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _dbHelper.getTodayPackages(
        searchQuery: state.searchQuery,
        statusFilters: state.statusFilters,
        barangayFilters: state.barangayFilters,
        paymentTypeFilters: state.paymentTypeFilters,
      );

      final activeRide = await _dbHelper.getActiveRide();
      final todayRides = await _dbHelper.getRidesForDate(DateTime.now());
      final summary = await _dbHelper.getPaymentSummary();
      final barangays = await _dbHelper.getTodayUniqueBarangays();
      final cities = await _dbHelper.getTodayUniqueCities();
      final statuses = await _dbHelper.getTodayUniqueStatuses();
      final paymentTypes = await _dbHelper.getTodayUniquePaymentTypes();
      final streets = await _dbHelper.getTodayUniqueStreets();
      final zones = await _dbHelper.getTodayUniqueZones();



      state = state.copyWith(
        packages: list,
        summary: summary,
        uniqueBarangays: barangays,
        uniqueCities: cities,
        uniqueStatuses: statuses,
        uniquePaymentTypes: paymentTypes,
        uniqueStreets: streets,
        uniqueZones: zones,
        activeRide: activeRide,
        todayRides: todayRides,
        isLoading: false,
      );
      // CHANGED: Invalidate badges provider when package status or data updates
      ref.invalidate(badgesNotifierProvider);
    } catch (e, stack) {
      debugPrint('=== REFRESH ERROR: $e');
      debugPrint('$stack');
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query);
      refresh();
    }
  }

  void toggleStatusFilter(String status) {
    final list = [...state.statusFilters];
    if (list.contains(status)) {
      list.remove(status);
    } else {
      list.add(status);
    }
    state = state.copyWith(statusFilters: list);
    refresh();
  }

  void toggleBarangayFilter(String barangay) {
    final list = [...state.barangayFilters];
    if (list.contains(barangay)) {
      list.remove(barangay);
    } else {
      list.add(barangay);
    }
    state = state.copyWith(barangayFilters: list);
    refresh();
  }

  void togglePaymentTypeFilter(String type) {
    final list = [...state.paymentTypeFilters];
    if (list.contains(type)) {
      list.remove(type);
    } else {
      list.add(type);
    }
    state = state.copyWith(paymentTypeFilters: list);
    refresh();
  }

  void setStatusFilters(List<String> statuses) {
    state = state.copyWith(statusFilters: statuses);
    refresh();
  }

  void setBarangayFilters(List<String> barangays) {
    state = state.copyWith(barangayFilters: barangays);
    refresh();
  }

  void setPaymentTypeFilters(List<String> types) {
    state = state.copyWith(paymentTypeFilters: types);
    refresh();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      statusFilters: const [],
      barangayFilters: const [],
      paymentTypeFilters: const [],
    );
    refresh();
  }

  Future<void> addPackage(Package package) async {
    final active = state.activeRide;
    var pkg = package;
    if (active != null) {
      pkg = package.copyWith(rideId: active.id);
    }
    await _dbHelper.insertPackage(pkg);
    await refresh();
    // Trigger geofence resync
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> bulkInsertPackages(List<String> trackingNumbers) async {
    final active = state.activeRide;
    final now = DateTime.now();
    
    // We run the insertions inside a single database transaction for extreme speed and consistency
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final trk in trackingNumbers) {
        // Auto-calculate sort order inside the loop
        final maxOrderResult = await txn.rawQuery('SELECT MAX(sort_order) as max_order FROM packages');
        final maxOrder = Sqflite.firstIntValue(maxOrderResult) ?? -1;
        final newSortOrder = maxOrder + 1;

        final newPkg = Package(
          id: const Uuid().v4(),
          trackingNumber: trk,
          receiverName: null,
          receiverPhone: null,
          notes: null,
          lat: null,
          lng: null,
          street: null,
          zone: null,
          barangay: null,
          city: null,
          paymentType: 'prepaid',
          codCash: 0.0,
          codDigital: 0.0,
          tips: 0,
          extraAmount: 0,
          extraLabel: null,
          status: 'pending',
          sortOrder: newSortOrder,
          createdAt: now,
          updatedAt: now,
        );

        final finalPkg = active != null ? newPkg.copyWith(rideId: active.id) : newPkg;
        await txn.insert('packages', finalPkg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> startRide() async {
    final active = await _dbHelper.getActiveRide();
    if (active != null) return;

    final now = DateTime.now();
    final nextNum = await _dbHelper.getNextRideNumberForDate(now);
    final newRide = Ride(
      id: 'ride_${now.millisecondsSinceEpoch}',
      rideNumber: nextNum,
      date: now,
      startedAt: now,
    );
    await _dbHelper.insertRide(newRide);

    // CHANGED: Record starting location immediately to track route from start
    final startPos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
    if (startPos != null) {
      await _dbHelper.insertRideLocation(newRide.id, startPos.latitude, startPos.longitude);
    }

    final todayPackages = await _dbHelper.getTodayPackages();
    for (final pkg in todayPackages) {
      if (pkg.rideId == null && (pkg.status == 'pending' || pkg.status == 'failed')) {
        await _dbHelper.updatePackage(pkg.copyWith(rideId: newRide.id));
      }
    }

    await refresh();
  }

  Future<String?> exportAutoBackupSql() async {
    final sqlContent = await _dbHelper.exportDeliveredPackagesToSql();
    if (sqlContent.isEmpty) return null;
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/BRAD_backup_autosave_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.sql',
    );
    await file.create(recursive: true);
    await file.writeAsString(sqlContent);
    return file.path;
  }

  Future<void> endRide() async {
    final active = state.activeRide;
    if (active == null) return;

    try {
      final now = DateTime.now();
      final updated = active.copyWith(endedAt: now);
      await _dbHelper.updateRide(updated);

      // Record ending location immediately to track route to end
      final endPos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
      if (endPos != null) {
        await _dbHelper.insertRideLocation(active.id, endPos.latitude, endPos.longitude);
      }

      // FEATURE-07: Auto-Backup on Ride End
      try {
        final backupPath = await exportAutoBackupSql();
        if (backupPath != null) {
          debugPrint('Auto-backup saved on ride end to $backupPath');
          // Show local notification about auto-backup
          await ref.read(notificationServiceProvider).showAutoBackupComplete(backupPath);
        }
      } catch (e) {
        debugPrint('Auto-backup failed on ride end: $e');
      }

      final ridePackages = await _dbHelper.getPackagesForRide(active.id);
      for (final pkg in ridePackages) {
        if (pkg.status != 'delivered') {
          final updatedPkg = pkg.copyWith(rideId: null);
          await _dbHelper.updatePackage(updatedPkg);
        }
      }
    } catch (e) {
      debugPrint('EndRide error: $e');
    }

    await refresh();
  }

  Future<void> markRescheduled(String id, DateTime date) async {
    final pkg = await _dbHelper.getPackageById(id);
    if (pkg == null) return;

    final updated = pkg.copyWith(
      status: 'rescheduled',
      rescheduledDate: date,
      updatedAt: DateTime.now(),
    );
    await _dbHelper.updatePackage(updated);

    final attempt = DeliveryAttempt(
      packageId: id,
      status: 'failed',
      notes: 'Rescheduled to ${DateFormat('yyyy-MM-dd').format(date)}',
      attemptedAt: DateTime.now(),
    );
    await _dbHelper.insertAttempt(attempt);

    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> markRejected(String id, String reason) async {
    final pkg = await _dbHelper.getPackageById(id);
    if (pkg == null) return;

    final updated = pkg.copyWith(
      status: 'rejected',
      rejectionReason: reason,
      updatedAt: DateTime.now(),
    );
    await _dbHelper.updatePackage(updated);

    final attempt = DeliveryAttempt(
      packageId: id,
      status: 'failed',
      notes: 'Rejected: $reason',
      attemptedAt: DateTime.now(),
    );
    await _dbHelper.insertAttempt(attempt);

    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> updatePackage(Package package) async {
    await _dbHelper.updatePackage(package);
    await refresh();
    // Trigger geofence resync
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> deletePackage(String id) async {
    await _dbHelper.deletePackage(id);
    await refresh();
    // Trigger geofence resync
    ref.read(geofenceManagerProvider).syncGeofences();
  }



  Future<void> markDelivered(
    String id, {
    double tips = 0,
    double extraAmount = 0,
    String? extraLabel,
    String? deliveryPhotoPath,
    String? signaturePath,
  }) async {
    final pkg = await _dbHelper.getPackageById(id);
    if (pkg == null) return;

    final updated = pkg.copyWith(
      status: 'delivered',
      tips: tips,
      extraAmount: extraAmount,
      extraLabel: extraLabel,
      deliveredAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deliveryPhotoPath: deliveryPhotoPath,
      signaturePath: signaturePath,
    );

    // Write package updates
    await _dbHelper.updatePackage(updated);

    // Log the successful attempt
    final attempt = DeliveryAttempt(
      packageId: id,
      status: 'success',
      notes: 'Delivered successfully',
      attemptedAt: DateTime.now(),
    );
    await _dbHelper.insertAttempt(attempt);

    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> markFailed(String id, String status, String? reason) async {
    final pkg = await _dbHelper.getPackageById(id);
    if (pkg == null) return;

    // Log the failed attempt
    final attempt = DeliveryAttempt(
      packageId: id,
      status: status, // 'failed' | 'no_answer' | 'refused'
      notes: reason,
      attemptedAt: DateTime.now(),
    );
    await _dbHelper.insertAttempt(attempt);

    // If attempts exceed 3, maybe show warning or change status
    final attemptCount = pkg.attemptCount + 1;
    final updatedStatus = attemptCount >= 3 ? 'returned' : 'failed';

    final updated = pkg.copyWith(
      status: updatedStatus,
      updatedAt: DateTime.now(),
    );
    await _dbHelper.updatePackage(updated);

  }

  Future<void> undoStatus(Package oldPackage) async {
    await _dbHelper.updatePackage(oldPackage);
    await _dbHelper.deleteLastAttempt(oldPackage.id);
    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }


  Future<void> reorderPackages(List<Package> packagesList, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final list = [...packagesList];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // SQLite Persistence - Update the sort orders of all packages in this group
    await _dbHelper.updateSortOrders(list.map((p) => p.id).toList());
    await refresh();
  }

  Future<void> clearDelivered() async {
    try {
      await exportToXlsx();
      await exportToSql();
    } catch (e) {
      debugPrint('Auto-backup before clear failed: $e');
    }
    await _dbHelper.clearDeliveredPackages();
    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  // CHANGED: Added exportToSql to write delivered package records to an SQL backup file on local storage before purging
  Future<String> exportToSql() async {
    final sqlContent = await _dbHelper.exportDeliveredPackagesToSql();
    if (sqlContent.isEmpty) return '';
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/BRAD_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.sql',
    );
    await file.create(recursive: true);
    await file.writeAsString(sqlContent);
    return file.path;
  }

  // CHANGED: Expose listSqlBackups to retrieve available SQL backup files from the local documents directory
  Future<List<File>> listSqlBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!await dir.exists()) return [];
    
    final files = dir.listSync();
    final List<File> backupFiles = [];
    for (final f in files) {
      if (f is File && f.path.endsWith('.sql') && f.path.contains('BRAD_backup_')) {
        backupFiles.add(f);
      }
    }
    // Sort descending by date (most recent first)
    backupFiles.sort((a, b) => b.path.compareTo(a.path));
    return backupFiles;
  }

  // CHANGED: Expose restoreFromSqlBackup to read a backup file and execute its INSERT scripts
  Future<void> restoreFromSqlBackup(File file) async {
    state = state.copyWith(isLoading: true);
    try {
      final script = await file.readAsString();
      await _dbHelper.executeSqlScript(script);
    } finally {
      await refresh();
      ref.read(geofenceManagerProvider).syncGeofences();
    }
  }

  Future<String> exportToXlsx() async {
    // Read all packages from SQLite (without filters)
    final allPackages = await _dbHelper.getPackages();

    var excelObj = Excel.createExcel();
    // Default sheet is 'Sheet1'
    Sheet sheetObject = excelObj['Sheet1'];

    // Header row
    final headers = [
      'ID',
      'Tracking #',
      'Receiver Name',
      'Receiver Phone',
      'Street',
      'Zone',
      'Barangay',
      'City',
      'Payment Type',
      'COD Cash',
      'COD Digital',
      'Tips',
      'Extra Amount',
      'Extra Label',
      'Status',
      'Sort Order',
      'Created At',
      'Delivered At',
      'Attempts',
      'Delivery Photo',
      'Signature Path'
    ];

    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (final p in allPackages) {
      sheetObject.appendRow([
        TextCellValue(p.id),
        TextCellValue(p.trackingNumber),
        TextCellValue(p.receiverName ?? ''),
        TextCellValue(p.receiverPhone ?? ''),
        TextCellValue(p.street ?? ''),
        TextCellValue(p.zone ?? ''),
        TextCellValue(p.barangay ?? ''),
        TextCellValue(p.city ?? ''),
        TextCellValue(p.paymentType),
        DoubleCellValue(p.codCash),
        DoubleCellValue(p.codDigital),
        DoubleCellValue(p.tips),
        DoubleCellValue(p.extraAmount),
        TextCellValue(p.extraLabel ?? ''),
        TextCellValue(p.status),
        IntCellValue(p.sortOrder),
        TextCellValue(p.createdAt.toIso8601String()),
        TextCellValue(p.deliveredAt?.toIso8601String() ?? ''),
        IntCellValue(p.attemptCount),
        TextCellValue(p.deliveryPhotoPath ?? ''),
        TextCellValue(p.signaturePath ?? ''),
      ]);
    }

    final fileBytes = excelObj.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/BRAD_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx',
    );
    await file.create(recursive: true);
    await file.writeAsBytes(fileBytes!);
    return file.path;
  }

  Future<void> shareXlsx() async {
    final path = await exportToXlsx();
    final file = XFile(path);
    await Share.shareXFiles([file], text: 'BRAD Shift Package Export');
  }

  Future<void> optimizeRoute() async {
    state = state.copyWith(isLoading: true);
    try {
      final currentPos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
      if (currentPos == null) {
        state = state.copyWith(isLoading: false);
        return; // Handle null gracefully
      }

      final allPkgs = state.packages;
      
      // Separate packages:
      // 1. Undelivered packages with coordinates (candidates for optimization)
      final List<Package> candidates = allPkgs.where((p) => 
        p.status != 'delivered' && p.lat != null && p.lng != null
      ).toList();

      // 2. All other packages (already delivered, failed, or lacking coordinates)
      final List<Package> others = allPkgs.where((p) => 
        p.status == 'delivered' || p.lat == null || p.lng == null
      ).toList();

      final List<Package> optimizedList = [];
      double currentLat = currentPos.latitude;
      double currentLng = currentPos.longitude;

      while (candidates.isNotEmpty) {
        int bestIndex = 0;
        double bestDist = double.infinity;

        for (int i = 0; i < candidates.length; i++) {
          final p = candidates[i];
          final dist = _calculateDistance(currentLat, currentLng, p.lat!, p.lng!);
          if (dist < bestDist) {
            bestDist = dist;
            bestIndex = i;
          }
        }

        final nextPkg = candidates.removeAt(bestIndex);
        optimizedList.add(nextPkg);
        currentLat = nextPkg.lat!;
        currentLng = nextPkg.lng!;
      }

      // Combine optimized list with others at the end
      final finalOrder = [...optimizedList, ...others];
      final orderedIds = finalOrder.map((p) => p.id).toList();

      await _dbHelper.updateSortOrders(orderedIds);
      await refresh();
    } catch (e) {
      debugPrint('Error optimizing route: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    return dLat * dLat + dLng * dLng;
  }
}
