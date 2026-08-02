// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'packages_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeRideLocationHash() =>
    r'9ea892ec947f6916d1de13640329dc9d56b09a98';

/// See also [activeRideLocation].
@ProviderFor(activeRideLocation)
final activeRideLocationProvider =
    AutoDisposeProvider<AsyncValue<Position>?>.internal(
      activeRideLocation,
      name: r'activeRideLocationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeRideLocationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveRideLocationRef = AutoDisposeProviderRef<AsyncValue<Position>?>;
String _$packagesNotifierHash() => r'8709c6533e5504c874496e15637bc5e1e3f77827';

/// See also [PackagesNotifier].
@ProviderFor(PackagesNotifier)
final packagesNotifierProvider =
    AutoDisposeNotifierProvider<PackagesNotifier, PackagesState>.internal(
      PackagesNotifier.new,
      name: r'packagesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$packagesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PackagesNotifier = AutoDisposeNotifier<PackagesState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
