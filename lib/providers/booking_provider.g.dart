// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getBookingHash() => r'3d23a6e77a7e94fa011059570a79db4b226620b6';

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

String _$myBookingsHash() => r'e24533a9bc7da81513a806778b7030f212c57b07';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
