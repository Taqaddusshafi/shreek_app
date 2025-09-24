import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/booking_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'booking_provider.g.dart';

// Enhanced Booking State
class BookingState {
  final List<Booking> bookings;
  final List<Booking> myBookings;
  final List<Booking> driverBookings;
  final List<Booking> upcomingBookings;
  final List<Booking> completedBookings;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final Map<String, dynamic>? stats;

  BookingState({
    this.bookings = const [],
    this.myBookings = const [],
    this.driverBookings = const [],
    this.upcomingBookings = const [],
    this.completedBookings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.stats,
  });

  BookingState copyWith({
    List<Booking>? bookings,
    List<Booking>? myBookings,
    List<Booking>? driverBookings,
    List<Booking>? upcomingBookings,
    List<Booking>? completedBookings,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    Map<String, dynamic>? stats,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      myBookings: myBookings ?? this.myBookings,
      driverBookings: driverBookings ?? this.driverBookings,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      stats: stats ?? this.stats,
    );
  }

  // Helper getters for filtering
  List<Booking> get pendingBookings => bookings.where((b) => b.isPending).toList();
  List<Booking> get confirmedBookings => bookings.where((b) => b.isConfirmed).toList();
  List<Booking> get cancelledBookings => bookings.where((b) => b.isCancelled).toList();
  int get totalBookings => bookings.length;
  bool get hasError => error != null;
  bool get isEmpty => bookings.isEmpty && !isLoading;
}

// Enhanced Booking Provider
@riverpod
class MyBookings extends _$MyBookings {
  late DioClient _dioClient;

  @override
  BookingState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return BookingState();
  }

  // ✅ ENHANCED: Load my bookings with comprehensive error handling
  Future<void> loadMyBookings({
    bool refresh = false,
    String? status,
    int limit = 20,
  }) async {
    if (state.isLoading && !refresh) return;
    
    final newPage = refresh ? 1 : state.currentPage;
    final isInitialLoad = newPage == 1;

    if (kDebugMode) {
      print('🔍 Loading my bookings - Page: $newPage, Status: ${status ?? 'all'}, Refresh: $refresh');
    }

    state = state.copyWith(
      isLoading: isInitialLoad,
      isLoadingMore: !isInitialLoad,
      error: null,
    );

    try {
      final queryParams = {
        'page': newPage,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.myBookings,
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📡 My bookings response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];
        final pagination = data['pagination'] ?? {};

        final newBookings = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        final updatedBookings = refresh || isInitialLoad
            ? newBookings
            : [...state.myBookings, ...newBookings];

        state = state.copyWith(
          myBookings: updatedBookings,
          bookings: updatedBookings, // Update main bookings list too
          currentPage: newPage,
          hasMore: pagination['hasNext'] ?? newBookings.length >= limit,
          isLoading: false,
          isLoadingMore: false,
        );

        if (kDebugMode) {
          print('✅ Loaded ${newBookings.length} bookings, Total: ${updatedBookings.length}');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load my bookings error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الحجوزات',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading bookings: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ✅ ENHANCED: Load driver bookings (bookings for my rides)
  Future<void> loadDriverBookings({
    bool refresh = false,
    String? status,
    int limit = 20,
  }) async {
    if (state.isLoading && !refresh) return;
    
    final newPage = refresh ? 1 : state.currentPage;
    final isInitialLoad = newPage == 1;

    if (kDebugMode) {
      print('🚗 Loading driver bookings - Page: $newPage, Status: ${status ?? 'all'}');
    }

    state = state.copyWith(
      isLoading: isInitialLoad,
      isLoadingMore: !isInitialLoad,
      error: null,
    );

    try {
      final queryParams = {
        'page': newPage,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.driverBookings,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];
        final pagination = data['pagination'] ?? {};

        final newBookings = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        final updatedBookings = refresh || isInitialLoad
            ? newBookings
            : [...state.driverBookings, ...newBookings];

        state = state.copyWith(
          driverBookings: updatedBookings,
          currentPage: newPage,
          hasMore: pagination['hasNext'] ?? newBookings.length >= limit,
          isLoading: false,
          isLoadingMore: false,
        );

        if (kDebugMode) {
          print('✅ Loaded ${newBookings.length} driver bookings');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load driver bookings error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب حجوزات الرحلات',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ✅ ENHANCED: Create booking with comprehensive validation
  Future<bool> createBooking({
    required int rideId,
    required int seatsBooked,
    String? specialRequests,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? notes,
  }) async {
    if (kDebugMode) {
      print('🎫 Creating booking for ride $rideId, Seats: $seatsBooked');
    }

    try {
      final requestData = {
        'rideId': rideId,
        'seatsBooked': seatsBooked,
        if (specialRequests?.isNotEmpty == true) 'specialRequests': specialRequests,
        if (pickupLocation?.isNotEmpty == true) 'pickupLocation': pickupLocation,
        if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
        if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
        if (notes?.isNotEmpty == true) 'notes': notes,
      };

      if (kDebugMode) {
        print('📤 Booking request data: $requestData');
      }

      final response = await _dioClient.dio.post(
        ApiConstants.bookings,
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Booking created successfully');
        }

        // Refresh bookings to show the new one
        await loadMyBookings(refresh: true);
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Create booking error: ${e.response?.statusCode}');
        print('❌ Error message: ${e.response?.data}');
      }

      state = state.copyWith(
        error: e.response?.data['message'] ?? 'فشل في إنشاء الحجز',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected booking creation error: $e');
      }

      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ ENHANCED: Cancel booking with confirmation
  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    if (kDebugMode) {
      print('❌ Cancelling booking $bookingId, Reason: ${reason ?? 'No reason provided'}');
    }

    try {
      final response = await _dioClient.dio.delete(
        '${ApiConstants.bookings}/$bookingId',
        data: reason != null ? {'cancellationReason': reason} : null,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking cancelled successfully');
        }

        // Update the booking status in current state
        final updatedBookings = state.myBookings.map((booking) {
          if (booking.id == bookingId) {
            return booking.copyWith(status: 'cancelled');
          }
          return booking;
        }).toList();

        state = state.copyWith(
          myBookings: updatedBookings,
          bookings: updatedBookings,
        );

        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Cancel booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        error: e.response?.data['message'] ?? 'فشل في إلغاء الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ ENHANCED: Accept booking request (for drivers)
  Future<bool> acceptBooking(int bookingId) async {
    if (kDebugMode) {
      print('✅ Accepting booking $bookingId');
    }

    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.bookings}/$bookingId/accept',
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking accepted successfully');
        }

        // Update booking status in current state
        _updateBookingStatus(bookingId, 'confirmed');
        
        // Refresh driver bookings
        await loadDriverBookings(refresh: true);
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Accept booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        error: e.response?.data['message'] ?? 'فشل في قبول الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ ENHANCED: Reject booking request (for drivers)
  Future<bool> rejectBooking(int bookingId, {String? reason}) async {
    if (kDebugMode) {
      print('❌ Rejecting booking $bookingId, Reason: ${reason ?? 'No reason provided'}');
    }

    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.bookings}/$bookingId/reject',
        data: reason != null ? {'rejectionReason': reason} : null,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking rejected successfully');
        }

        // Update booking status in current state
        _updateBookingStatus(bookingId, 'rejected');
        
        // Refresh driver bookings
        await loadDriverBookings(refresh: true);
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Reject booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        error: e.response?.data['message'] ?? 'فشل في رفض الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ ENHANCED: Update booking status
  Future<bool> updateBookingStatus(int bookingId, String status) async {
    if (kDebugMode) {
      print('🔄 Updating booking $bookingId status to: $status');
    }

    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.bookings}/$bookingId/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking status updated successfully');
        }

        // Update local state
        _updateBookingStatus(bookingId, status);
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Update booking status error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        error: e.response?.data['message'] ?? 'فشل في تحديث حالة الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ NEW: Load booking statistics
  Future<void> loadBookingStats() async {
    if (kDebugMode) {
      print('📊 Loading booking statistics');
    }

    try {
      final response = await _dioClient.dio.get(ApiConstants.bookingStats);

      if (response.statusCode == 200) {
        final stats = response.data['data'] ?? response.data;
        
        state = state.copyWith(stats: stats);

        if (kDebugMode) {
          print('✅ Booking stats loaded: $stats');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load booking stats error: ${e.response?.statusCode}');
      }
      // Don't set error for stats, it's not critical
    }
  }

  // ✅ NEW: Load bookings by status
  Future<void> loadBookingsByStatus(String status, {bool refresh = false}) async {
    if (kDebugMode) {
      print('🔍 Loading bookings with status: $status');
    }

    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
      case 'completed':
      case 'cancelled':
        await loadMyBookings(refresh: refresh, status: status);
        break;
      default:
        await loadMyBookings(refresh: refresh);
    }
  }

  // ✅ NEW: Search bookings
  Future<void> searchBookings({
    String? query,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kDebugMode) {
      print('🔍 Searching bookings - Query: $query, Status: $status');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = <String, dynamic>{
        if (query?.isNotEmpty == true) 'search': query,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _dioClient.dio.get(
        '${ApiConstants.bookings}/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];

        final searchResults = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        state = state.copyWith(
          bookings: searchResults,
          myBookings: searchResults,
          isLoading: false,
        );

        if (kDebugMode) {
          print('✅ Found ${searchResults.length} bookings matching criteria');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Search bookings error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في البحث عن الحجوزات',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع في البحث',
      );
    }
  }

  // ✅ Helper method to update booking status in current state
  void _updateBookingStatus(int bookingId, String status) {
    final updatedMyBookings = state.myBookings.map((booking) {
      if (booking.id == bookingId) {
        return booking.copyWith(status: status);
      }
      return booking;
    }).toList();

    final updatedDriverBookings = state.driverBookings.map((booking) {
      if (booking.id == bookingId) {
        return booking.copyWith(status: status);
      }
      return booking;
    }).toList();

    state = state.copyWith(
      myBookings: updatedMyBookings,
      driverBookings: updatedDriverBookings,
      bookings: updatedMyBookings,
    );
  }

  // ✅ Load more bookings (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    
    await loadMyBookings();
  }

  // ✅ Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // ✅ Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadMyBookings(refresh: true),
      loadBookingStats(),
    ]);
  }
}

// ✅ Convenience Providers
// ✅ FIXED: Convenience Providers with proper naming and no circular dependencies
final myBookingsListProvider = Provider<List<Booking>>((ref) {
  return ref.watch(myBookingsProvider).myBookings;
});

final driverBookingsListProvider = Provider<List<Booking>>((ref) {
  return ref.watch(myBookingsProvider).driverBookings;
});

final pendingBookingsListProvider = Provider<List<Booking>>((ref) {
  return ref.watch(myBookingsProvider).pendingBookings;
});

final confirmedBookingsListProvider = Provider<List<Booking>>((ref) {
  return ref.watch(myBookingsProvider).confirmedBookings;
});

final completedBookingsListProvider = Provider<List<Booking>>((ref) {
  return ref.watch(myBookingsProvider).completedBookings;
});

final cancelledBookingsListProvider = Provider<List<Booking>>((ref) {
  return ref.watch(myBookingsProvider).cancelledBookings;
});

final bookingStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(myBookingsProvider).stats;
});

final isBookingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(myBookingsProvider).isLoading;
});

final bookingErrorProvider = Provider<String?>((ref) {
  return ref.watch(myBookingsProvider).error;
});

final hasBookingErrorProvider = Provider<bool>((ref) {
  return ref.watch(myBookingsProvider).hasError;
});

final totalBookingsCountProvider = Provider<int>((ref) {
  return ref.watch(myBookingsProvider).totalBookings;
});
