import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';
import '../packages/packages_provider.dart';

part 'scan_provider.g.dart';

class ScanState {
  final List<String> batchQueue;
  final bool isBatchMode;
  final bool isChecking;

  const ScanState({
    this.batchQueue = const [],
    this.isBatchMode = false,
    this.isChecking = false,
  });

  ScanState copyWith({
    List<String>? batchQueue,
    bool? isBatchMode,
    bool? isChecking,
  }) {
    return ScanState(
      batchQueue: batchQueue ?? this.batchQueue,
      isBatchMode: isBatchMode ?? this.isBatchMode,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

@riverpod
class ScanStateNotifier extends _$ScanStateNotifier {
  final DbHelper _dbHelper = DbHelper.instance;

  @override
  ScanState build() {
    return const ScanState();
  }

  void toggleBatchMode() {
    state = state.copyWith(isBatchMode: !state.isBatchMode);
  }

  void setBatchMode(bool enabled) {
    state = state.copyWith(isBatchMode: enabled);
  }

  void addToQueue(String code) {
    if (!state.batchQueue.contains(code)) {
      state = state.copyWith(batchQueue: [...state.batchQueue, code]);
    }
  }

  void removeFromQueue(String code) {
    state = state.copyWith(
      batchQueue: state.batchQueue.where((item) => item != code).toList(),
    );
  }

  void clearQueue() {
    state = state.copyWith(batchQueue: const []);
  }

  Future<bool> checkTrackingNumber(String trackingNumber) async {
    state = state.copyWith(isChecking: true);
    try {
      final package = await _dbHelper.getPackageByTrackingNumber(trackingNumber);
      state = state.copyWith(isChecking: false);
      return package != null;
    } catch (_) {
      state = state.copyWith(isChecking: false);
      return false;
    }
  }

  Future<void> commitBatch() async {
    if (state.batchQueue.isEmpty) return;
    
    final notifier = ref.read(packagesNotifierProvider.notifier);
    await notifier.bulkInsertPackages(state.batchQueue);
    clearQueue();
  }
}
