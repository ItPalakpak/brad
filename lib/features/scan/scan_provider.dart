import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';
import '../../shared/utils/ocr_parser.dart';
import '../packages/packages_provider.dart';

part 'scan_provider.g.dart';

class ScanState {
  final List<String> batchQueue;
  final bool isBatchMode;
  final bool isChecking;
  final Map<String, OcrParsedResult> batchOcrResults;
  final bool isProcessingOcr;

  const ScanState({
    this.batchQueue = const [],
    this.isBatchMode = false,
    this.isChecking = false,
    this.batchOcrResults = const {},
    this.isProcessingOcr = false,
  });

  ScanState copyWith({
    List<String>? batchQueue,
    bool? isBatchMode,
    bool? isChecking,
    Map<String, OcrParsedResult>? batchOcrResults,
    bool? isProcessingOcr,
  }) {
    return ScanState(
      batchQueue: batchQueue ?? this.batchQueue,
      isBatchMode: isBatchMode ?? this.isBatchMode,
      isChecking: isChecking ?? this.isChecking,
      batchOcrResults: batchOcrResults ?? this.batchOcrResults,
      isProcessingOcr: isProcessingOcr ?? this.isProcessingOcr,
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
    final newOcr = Map<String, OcrParsedResult>.from(state.batchOcrResults)..remove(code);
    state = state.copyWith(
      batchQueue: state.batchQueue.where((item) => item != code).toList(),
      batchOcrResults: newOcr,
    );
  }

  void clearQueue() {
    state = state.copyWith(
      batchQueue: const [],
      batchOcrResults: const {},
    );
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

  Future<int> processBatchOcr(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return 0;
    state = state.copyWith(isProcessingOcr: true);

    final packagesState = ref.read(packagesNotifierProvider);
    final Map<String, OcrParsedResult> updatedOcrResults = Map.from(state.batchOcrResults);
    int matchedCount = 0;

    for (final path in imagePaths) {
      final result = await OcrParser.parseFromImages(
        [path],
        knownBarangays: packagesState.uniqueBarangays,
        knownCities: packagesState.uniqueCities,
        candidateTrackingNumbers: state.batchQueue,
      );

      final matchedTrk = result.trackingNumber;
      if (matchedTrk != null && state.batchQueue.contains(matchedTrk)) {
        final existing = updatedOcrResults[matchedTrk];
        updatedOcrResults[matchedTrk] = existing != null ? existing.merge(result) : result;
        matchedCount++;
      }
    }

    state = state.copyWith(
      batchOcrResults: updatedOcrResults,
      isProcessingOcr: false,
    );

    return matchedCount;
  }

  Future<void> commitBatch() async {
    if (state.batchQueue.isEmpty) return;
    
    final notifier = ref.read(packagesNotifierProvider.notifier);
    if (state.batchOcrResults.isNotEmpty) {
      await notifier.bulkInsertPackagesWithDetails(state.batchQueue, state.batchOcrResults);
    } else {
      await notifier.bulkInsertPackages(state.batchQueue);
    }
    clearQueue();
  }
}
