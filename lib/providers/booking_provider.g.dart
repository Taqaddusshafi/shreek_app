// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getBookingHash() => r'05c2406d1c05d627272ab25be1f80e3b1b2b7475';

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

/// See also [getBooking].
@ProviderFor(getBooking)
const getBookingProvider = GetBookingFamily();

/// See also [getBooking].
class GetBookingFamily extends Family<AsyncValue<Booking?>> {
  /// See also [getBooking].
  const GetBookingFamily();

  /// See also [getBooking].
  GetBookingProvider call(
    int bookingId,
  ) {
    return GetBookingProvider(
      bookingId,
    );
  }

  @override
  GetBookingProvider getProviderOverride(
    covariant GetBookingProvider provider,
  ) {
    return call(
      provider.bookingId,
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
  String? get name => r'getBookingProvider';
}

/// See also [getBooking].
class GetBookingProvider extends AutoDisposeFutureProvider<Booking?> {
  /// See also [getBooking].
  GetBookingProvider(
    int bookingId,
  ) : this._internal(
          (ref) => getBooking(
            ref as GetBookingRef,
            bookingId,
          ),
          from: getBookingProvider,
          name: r'getBookingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getBookingHash,
          dependencies: GetBookingFamily._dependencies,
          allTransitiveDependencies:
              GetBookingFamily._allTransitiveDependencies,
          bookingId: bookingId,
        );

  GetBookingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookingId,
  }) : super.internal();

  final int bookingId;

  @override
  Override overrideWith(
    FutureOr<Booking?> Function(GetBookingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetBookingProvider._internal(
        (ref) => create(ref as GetBookingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookingId: bookingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Booking?> createElement() {
    return _GetBookingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetBookingProvider && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetBookingRef on AutoDisposeFutureProviderRef<Booking?> {
  /// The parameter `bookingId` of this provider.
  int get bookingId;
}

class _GetBookingProviderElement
    extends AutoDisposeFutureProviderElement<Booking?> with GetBookingRef {
  _GetBookingProviderElement(super.provider);

  @override
  int get bookingId => (origin as GetBookingProvider).bookingId;
}

String _$getBookingStatsHash() => r'5a8dd2583696afbb0e41fb9475a9522f82fb9a8b';

/// See also [getBookingStats].
@ProviderFor(getBookingStats)
final getBookingStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  getBookingStats,
  name: r'getBookingStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getBookingStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetBookingStatsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$myBookingsHash() => r'b7ba958c9ebe01d5716514c01b76a46a050cdd25';

/// See also [MyBookings].
@ProviderFor(MyBookings)
final myBookingsProvider =
    AutoDisposeNotifierProvider<MyBookings, BookingState>.internal(
  MyBookings.new,
  name: r'myBookingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MyBookings = AutoDisposeNotifier<BookingState>;
String _$driverBookingsHash() => r'bb29dbecbd063907897ac163b725a8140e3cac7c';

/// See also [DriverBookings].
@ProviderFor(DriverBookings)
final driverBookingsProvider =
    AutoDisposeNotifierProvider<DriverBookings, BookingState>.internal(
  DriverBookings.new,
  name: r'driverBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driverBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DriverBookings = AutoDisposeNotifier<BookingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
