import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

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
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _dbHelper.getPackages(
        searchQuery: state.searchQuery,
        statusFilters: state.statusFilters,
        barangayFilters: state.barangayFilters,
        paymentTypeFilters: state.paymentTypeFilters,
      );

      final summary = await _dbHelper.getPaymentSummary();
      final barangays = await _dbHelper.getUniqueBarangays();
      final cities = await _dbHelper.getUniqueCities();
      final statuses = await _dbHelper.getUniqueStatuses();
      final paymentTypes = await _dbHelper.getUniquePaymentTypes();

      state = state.copyWith(
        packages: list,
        summary: summary,
        uniqueBarangays: barangays,
        uniqueCities: cities,
        uniqueStatuses: statuses,
        uniquePaymentTypes: paymentTypes,
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
    await _dbHelper.insertPackage(package);
    await refresh();
    // Trigger geofence resync
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

  Future<void> markDelivered(String id) async {
    final pkg = await _dbHelper.getPackageById(id);
    if (pkg == null) return;

    final updated = pkg.copyWith(
      status: 'delivered',
      deliveredAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

    // SQLite Persistence
    await _dbHelper.updateSortOrders(list.map((p) => p.id).toList());
    await refresh();
  }

  Future<void> clearDelivered() async {
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
      'Attempts'
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
