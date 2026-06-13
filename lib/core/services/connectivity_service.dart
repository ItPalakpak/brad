import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@riverpod
Stream<bool> connectivityStream(Ref ref) async* {
  final connectivity = Connectivity();
  
  // Get initial connectivity
  final initialList = await connectivity.checkConnectivity();
  yield initialList.isNotEmpty && initialList.any((r) => r != ConnectivityResult.none);

  // Listen to connectivity changes
  yield* connectivity.onConnectivityChanged.map(
    (results) => results.isNotEmpty && results.any((r) => r != ConnectivityResult.none),
  );
}

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  @override
  bool build() {
    // Listen to the stream and update status
    ref.listen(connectivityStreamProvider, (_, next) {
      if (next.hasValue) {
        state = next.value ?? true;
      }
    });

    // Try to read initial value synchronously if stream already emitted
    final initial = ref.read(connectivityStreamProvider);
    return initial.value ?? true; // optimistic default
  }

  void updateStatus(bool isOnline) {
    state = isOnline;
  }
}
