// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getRideHash() => r'fa33c0a923eda907c11a2efe650c9234f5dac926';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [getRide].
@ProviderFor(getRide)
const getRideProvider = GetRideFamily();

/// See also [getRide].
class GetRideFamily extends Family<AsyncValue<Ride?>> {
  /// See also [getRide].
  const GetRideFamily();

  /// See also [getRide].
  GetRideProvider call(
    int rideId,
  ) {
    return GetRideProvider(
      rideId,
    );
  }

  @override
  GetRideProvider getProviderOverride(
    covariant GetRideProvider provider,
  ) {
    return call(
      provider.rideId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getRideProvider';
}

/// See also [getRide].
class GetRideProvider extends AutoDisposeFutureProvider<Ride?> {
  /// See also [getRide].
  GetRideProvider(
    int rideId,
  ) : this._internal(
          (ref) => getRide(
            ref as GetRideRef,
            rideId,
          ),
          from: getRideProvider,
          name: r'getRideProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getRideHash,
          dependencies: GetRideFamily._dependencies,
          allTransitiveDependencies: GetRideFamily._allTransitiveDependencies,
          rideId: rideId,
        );

  GetRideProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rideId,
  }) : super.internal();

  final int rideId;

  @override
  Override overrideWith(
    FutureOr<Ride?> Function(GetRideRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetRideProvider._internal(
        (ref) => create(ref as GetRideRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rideId: rideId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Ride?> createElement() {
    return _GetRideProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRideProvider && other.rideId == rideId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rideId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetRideRef on AutoDisposeFutureProviderRef<Ride?> {
  /// The parameter `rideId` of this provider.
  int get rideId;
}

class _GetRideProviderElement extends AutoDisposeFutureProviderElement<Ride?>
    with GetRideRef {
  _GetRideProviderElement(super.provider);

  @override
  int get rideId => (origin as GetRideProvider).rideId;
}

String _$rideSearchHash() => r'76a2bc4b4351bf3a5f5736bf34ef8611507ee7c4';

/// See also [RideSearch].
@ProviderFor(RideSearch)
final rideSearchProvider =
    AutoDisposeNotifierProvider<RideSearch, RideState>.internal(
  RideSearch.new,
  name: r'rideSearchProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rideSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RideSearch = AutoDisposeNotifier<RideState>;
String _$myRidesHash() => r'12f81924f375bed645713f22edef479aa972e07a';

/// See also [MyRides].
@ProviderFor(MyRides)
final myRidesProvider =
    AutoDisposeNotifierProvider<MyRides, RideState>.internal(
  MyRides.new,
  name: r'myRidesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myRidesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MyRides = AutoDisposeNotifier<RideState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
