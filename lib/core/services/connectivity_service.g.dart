// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectivityStreamHash() =>
    r'b7a337679a3b0e7a676290f151a3aac9e85c94a6';

/// See also [connectivityStream].
@ProviderFor(connectivityStream)
final connectivityStreamProvider = AutoDisposeStreamProvider<bool>.internal(
  connectivityStream,
  name: r'connectivityStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectivityStreamRef = AutoDisposeStreamProviderRef<bool>;
String _$connectivityNotifierHash() =>
    r'b74d949b162bc17611f85178117d740149593d4b';

/// See also [ConnectivityNotifier].
@ProviderFor(ConnectivityNotifier)
final connectivityNotifierProvider =
    AutoDisposeNotifierProvider<ConnectivityNotifier, bool>.internal(
      ConnectivityNotifier.new,
      name: r'connectivityNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectivityNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConnectivityNotifier = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
