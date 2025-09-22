// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getRideHash() => r'a30daa59919279990b9d3722282b44383da147a4';

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

String _$getRideStopsHash() => r'f33d5ef7337ce93c19ef797371a57e14cadbf31b';

/// See also [getRideStops].
@ProviderFor(getRideStops)
const getRideStopsProvider = GetRideStopsFamily();

/// See also [getRideStops].
class GetRideStopsFamily extends Family<AsyncValue<List<StopPoint>>> {
  /// See also [getRideStops].
  const GetRideStopsFamily();

  /// See also [getRideStops].
  GetRideStopsProvider call(
    int rideId,
  ) {
    return GetRideStopsProvider(
      rideId,
    );
  }

  @override
  GetRideStopsProvider getProviderOverride(
    covariant GetRideStopsProvider provider,
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
  String? get name => r'getRideStopsProvider';
}

/// See also [getRideStops].
class GetRideStopsProvider extends AutoDisposeFutureProvider<List<StopPoint>> {
  /// See also [getRideStops].
  GetRideStopsProvider(
    int rideId,
  ) : this._internal(
          (ref) => getRideStops(
            ref as GetRideStopsRef,
            rideId,
          ),
          from: getRideStopsProvider,
          name: r'getRideStopsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getRideStopsHash,
          dependencies: GetRideStopsFamily._dependencies,
          allTransitiveDependencies:
              GetRideStopsFamily._allTransitiveDependencies,
          rideId: rideId,
        );

  GetRideStopsProvider._internal(
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
    FutureOr<List<StopPoint>> Function(GetRideStopsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetRideStopsProvider._internal(
        (ref) => create(ref as GetRideStopsRef),
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
  AutoDisposeFutureProviderElement<List<StopPoint>> createElement() {
    return _GetRideStopsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetRideStopsProvider && other.rideId == rideId;
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
mixin GetRideStopsRef on AutoDisposeFutureProviderRef<List<StopPoint>> {
  /// The parameter `rideId` of this provider.
  int get rideId;
}

class _GetRideStopsProviderElement
    extends AutoDisposeFutureProviderElement<List<StopPoint>>
    with GetRideStopsRef {
  _GetRideStopsProviderElement(super.provider);

  @override
  int get rideId => (origin as GetRideStopsProvider).rideId;
}

String _$rideSearchHash() => r'06fb49361e6f4d69d0fc463a4148e0b6d51880db';

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
String _$myRidesHash() => r'dc2b640efc7712e104af8933dd2e89444c7192b9';

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
