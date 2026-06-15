import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';


import '../../core/database/db_helper.dart';
import '../../core/services/geofence_manager.dart';

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
    Ride? activeRide,
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
      activeRide: activeRide ?? this.activeRide,
      todayRides: todayRides ?? this.todayRides,
    );
  }
}

@riverpod
class PackagesNotifier extends _$PackagesNotifier {
  final DbHelper _dbHelper = DbHelper.instance;

  @override
  PackagesState build() {
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
      final barangays = await _dbHelper.getUniqueBarangays();
      final cities = await _dbHelper.getUniqueCities();
      final statuses = await _dbHelper.getUniqueStatuses();
      final paymentTypes = await _dbHelper.getUniquePaymentTypes();
      final streets = await _dbHelper.getUniqueStreets();
      final zones = await _dbHelper.getUniqueZones();

      final allRides = await _dbHelper.getAllRides();
      debugPrint('=== ALL RIDES IN DB:');
      for (final r in allRides) {
        debugPrint('  Ride id: ${r.id}, num: ${r.rideNumber}, date: ${r.date}, started: ${r.startedAt}, ended: ${r.endedAt}');
      }

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
    } catch (_) {
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

    final todayPackages = await _dbHelper.getTodayPackages();
    for (final pkg in todayPackages) {
      if (pkg.rideId == null && (pkg.status == 'pending' || pkg.status == 'failed')) {
        await _dbHelper.updatePackage(pkg.copyWith(rideId: newRide.id));
      }
    }

    await refresh();
  }

  Future<void> endRide() async {
    final active = state.activeRide;
    if (active == null) {
      debugPrint('=== END RIDE: activeRide is null');
      return;
    }

    try {
      final now = DateTime.now();
      final updated = active.copyWith(endedAt: now);
      final affected = await _dbHelper.updateRide(updated);
      debugPrint('=== END RIDE: updated ride ${active.id}, rows affected: $affected');

      final ridePackages = await _dbHelper.getPackagesForRide(active.id);
      debugPrint('=== END RIDE: found ${ridePackages.length} packages for ride');
      for (final pkg in ridePackages) {
        if (pkg.status != 'delivered') {
          final updatedPkg = pkg.copyWith(rideId: null);
          await _dbHelper.updatePackage(updatedPkg);
          debugPrint('=== END RIDE: released package ${pkg.trackingNumber} to unassigned');
        }
      }
    } catch (e, stack) {
      debugPrint('=== END RIDE ERROR: $e');
      debugPrint('$stack');
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

    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state.packages];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Optimistic UI update
    state = state.copyWith(packages: list);

    // SQLite Persistence - Map the relative reordered list back to the full list
    final allPackages = await _dbHelper.getPackages();
    final filteredIds = list.map((p) => p.id).toSet();

    final newAllPackages = <Package>[];
    int filteredIdx = 0;
    for (final p in allPackages) {
      if (filteredIds.contains(p.id)) {
        newAllPackages.add(list[filteredIdx]);
        filteredIdx++;
      } else {
        newAllPackages.add(p);
      }
    }

    await _dbHelper.updateSortOrders(newAllPackages.map((p) => p.id).toList());
    await refresh();
  }

  Future<void> clearDelivered() async {
    try {
      await exportToXlsx();
    } catch (e) {
      debugPrint('Auto-backup before clear failed: $e');
    }
    await _dbHelper.clearDeliveredPackages();
    await refresh();
    ref.read(geofenceManagerProvider).syncGeofences();
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
      'Delivery Photo'
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
}
