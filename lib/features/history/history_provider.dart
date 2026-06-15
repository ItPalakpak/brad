import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';

part 'history_provider.g.dart';

class HistoryState {
  final DateTime startDate;
  final DateTime endDate;
  final String searchQuery;
  final List<String> statusFilters;
  final List<String> barangayFilters;
  final List<String> paymentTypeFilters;
  final List<Package> packages;
  final PaymentSummary summary;
  final List<String> uniqueBarangays;
  final List<String> uniqueCities;
  final List<String> uniqueStatuses;
  final List<String> uniquePaymentTypes;
  final bool isLoading;

  HistoryState({
    required this.startDate,
    required this.endDate,
    this.searchQuery = '',
    this.statusFilters = const [],
    this.barangayFilters = const [],
    this.paymentTypeFilters = const [],
    required this.packages,
    required this.summary,
    required this.uniqueBarangays,
    required this.uniqueCities,
    this.uniqueStatuses = const [],
    this.uniquePaymentTypes = const [],
    this.isLoading = false,
  });

  HistoryState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    List<String>? statusFilters,
    List<String>? barangayFilters,
    List<String>? paymentTypeFilters,
    List<Package>? packages,
    PaymentSummary? summary,
    List<String>? uniqueBarangays,
    List<String>? uniqueCities,
    List<String>? uniqueStatuses,
    List<String>? uniquePaymentTypes,
    bool? isLoading,
  }) {
    return HistoryState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilters: statusFilters ?? this.statusFilters,
      barangayFilters: barangayFilters ?? this.barangayFilters,
      paymentTypeFilters: paymentTypeFilters ?? this.paymentTypeFilters,
      packages: packages ?? this.packages,
      summary: summary ?? this.summary,
      uniqueBarangays: uniqueBarangays ?? this.uniqueBarangays,
      uniqueCities: uniqueCities ?? this.uniqueCities,
      uniqueStatuses: uniqueStatuses ?? this.uniqueStatuses,
      uniquePaymentTypes: uniquePaymentTypes ?? this.uniquePaymentTypes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  final DbHelper _dbHelper = DbHelper.instance;

  @override
  HistoryState build() {
    final now = DateTime.now();
    Future.microtask(() => refresh());
    return HistoryState(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day),
      packages: [],
      summary: PaymentSummary.empty(),
      uniqueBarangays: [],
      uniqueCities: [],
      isLoading: true,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _dbHelper.getPackagesInDateRange(
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
        statusFilters: state.statusFilters,
        barangayFilters: state.barangayFilters,
        paymentTypeFilters: state.paymentTypeFilters,
      );

      double codCash = 0;
      double codDigital = 0;
      double tips = 0;
      double extraAmount = 0;

      for (final p in list) {
        if (p.status == 'delivered') {
          codCash += p.codCash;
          codDigital += p.codDigital;
          tips += p.tips;
          extraAmount += p.extraAmount;
        }
      }
      final rangeSummary = PaymentSummary(
        codCash: codCash,
        codDigital: codDigital,
        tips: tips,
        extraAmount: extraAmount,
      );

      final barangays = await _dbHelper.getUniqueBarangays();
      final cities = await _dbHelper.getUniqueCities();
      final statuses = await _dbHelper.getUniqueStatuses();
      final paymentTypes = await _dbHelper.getUniquePaymentTypes();

      state = state.copyWith(
        packages: list,
        summary: rangeSummary,
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

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    refresh();
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

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      statusFilters: const [],
      barangayFilters: const [],
      paymentTypeFilters: const [],
    );
    refresh();
  }
}
