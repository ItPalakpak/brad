import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';

part 'scan_provider.g.dart';

@riverpod
class ScanStateNotifier extends _$ScanStateNotifier {
  @override
  AsyncValue<Package?> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> checkTrackingNumber(String trackingNumber) async {
    state = const AsyncValue.loading();
    try {
      final package = await DbHelper.instance.getPackageByTrackingNumber(trackingNumber);
      if (package != null) {
        state = AsyncValue.data(package);
        return true; // Is a duplicate
      } else {
        state = const AsyncValue.data(null);
        return false; // Is not a duplicate, can proceed to add
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
