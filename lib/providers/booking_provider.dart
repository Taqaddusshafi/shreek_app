import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/booking_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'booking_provider.g.dart';

// Booking State
class BookingState {
  final List<Booking> bookings;
  final List<Booking> upcomingBookings;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  BookingState({
    this.bookings = const [],
    this.upcomingBookings = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  BookingState copyWith({
    List<Booking>? bookings,
    List<Booking>? upcomingBookings,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// My Bookings Provider
@riverpod
class MyBookings extends _$MyBookings {
  late DioClient _dioClient;

  @override
  BookingState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return BookingState();
  }

  Future<void> loadMyBookings({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.bookings,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data is List 
            ? data 
            : data['bookings'] ?? [];
            
        final bookings = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        state = state.copyWith(
          bookings: bookings,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الحجوزات',
      );
    }
  }

  // ✅ FIXED: Use correct booking API structure for new Halawasl API
  Future<bool> bookRide({
    required int rideId, // Changed to int
    required int seatsBooked,
    String? specialRequests,
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    String? notes,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.bookings,
        data: {
          'rideId': rideId,
          'seatsBooked': seatsBooked,
          if (specialRequests != null) 'specialRequests': specialRequests,
          'pickupLocation': pickupLocation,
          'pickupLatitude': pickupLatitude,
          'pickupLongitude': pickupLongitude,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        await loadMyBookings();
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في حجز الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في حجز الرحلة',
      );
      return false;
    }
  }

  Future<bool> cancelBooking(int bookingId) async { // Changed to int
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.delete(
        '${ApiConstants.bookings}/$bookingId',
      );

      if (response.statusCode == 200) {
        final updatedBookings = state.bookings
            .where((booking) => booking.id != bookingId)
            .toList();
        
        state = state.copyWith(
          bookings: updatedBookings,
          isLoading: false,
        );
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في إلغاء الحجز',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في إلغاء الحجز',
      );
      return false;
    }
  }

  Future<bool> updateBooking({
    required int bookingId, // Changed to int
    int? seatsBooked,
    String? specialRequests,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? notes,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.bookings}/$bookingId',
        data: {
          if (seatsBooked != null) 'seatsBooked': seatsBooked,
          if (specialRequests != null) 'specialRequests': specialRequests,
          if (pickupLocation != null) 'pickupLocation': pickupLocation,
          if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
          if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        await loadMyBookings();
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في تحديث الحجز',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في تحديث الحجز',
      );
      return false;
    }
  }

  // ✅ FIXED: Load upcoming bookings using status filter instead of separate endpoint
  Future<void> loadUpcomingBookings() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.bookings,
        queryParameters: {
          'status': 'confirmed',
          'limit': 20,
          'offset': 0,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data is List 
            ? data 
            : data['bookings'] ?? [];
            
        final upcomingBookings = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        state = state.copyWith(upcomingBookings: upcomingBookings);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الحجوزات القادمة',
      );
    }
  }

  // ✅ NEW: Get bookings by status
  Future<void> loadBookingsByStatus(String status) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.get(
        ApiConstants.bookings,
        queryParameters: {
          'status': status,
          'limit': 20,
          'offset': 0,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data is List 
            ? data 
            : data['bookings'] ?? [];
            
        final bookings = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        state = state.copyWith(
          bookings: bookings,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الحجوزات',
      );
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

// ✅ Driver Booking Management Provider
@riverpod
class DriverBookings extends _$DriverBookings {
  late DioClient _dioClient;

  @override
  BookingState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return BookingState();
  }

  // ✅ Load driver bookings from dedicated endpoint
  Future<void> loadDriverBookings({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.driverBookings,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> bookingsJson = data is List 
            ? data 
            : data['bookings'] ?? [];
            
        final bookings = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        state = state.copyWith(
          bookings: bookings,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الحجوزات',
      );
    }
  }

  // ✅ FIXED: Use new API method names
  Future<bool> acceptBooking(int bookingId, {String? notes}) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.bookings}/$bookingId/accept',
        data: {
          if (notes != null) 'notes': notes,
        },
      );
      
      if (response.statusCode == 200) {
        await loadDriverBookings(); // Refresh list
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في قبول الحجز',
      );
      return false;
    }
  }

  Future<bool> rejectBooking(int bookingId, {String? notes}) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.bookings}/$bookingId/reject',
        data: {
          if (notes != null) 'notes': notes,
        },
      );
      
      if (response.statusCode == 200) {
        await loadDriverBookings(); // Refresh list
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في رفض الحجز',
      );
      return false;
    }
  }

  Future<bool> completeBooking(int bookingId) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.bookings}/$bookingId/complete',
      );
      
      if (response.statusCode == 200) {
        await loadDriverBookings(); // Refresh list
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في إكمال الحجز',
      );
      return false;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

// Single Booking Provider
@riverpod
Future<Booking?> getBooking(GetBookingRef ref, int bookingId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get('${ApiConstants.bookings}/$bookingId');
    
    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return Booking.fromJson(data['booking'] ?? data);
    }
    return null;
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? 'حدث خطأ في جلب تفاصيل الحجز';
  }
}

// ✅ NEW: Get booking statistics
@riverpod
Future<Map<String, dynamic>> getBookingStats(GetBookingStatsRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get(ApiConstants.bookingStats);
    
    if (response.statusCode == 200) {
      return response.data['data'] ?? response.data;
    }
    return {};
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? 'حدث خطأ في جلب إحصائيات الحجوزات';
  }
}

// ✅ NEW: Convenience providers for different booking statuses
final pendingBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(myBookingsProvider).bookings;
  return bookings.where((booking) => booking.status == 'pending').toList();
});

final confirmedBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(myBookingsProvider).bookings;
  return bookings.where((booking) => booking.status == 'confirmed').toList();
});

final completedBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(myBookingsProvider).bookings;
  return bookings.where((booking) => booking.status == 'completed').toList();
});

final cancelledBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(myBookingsProvider).bookings;
  return bookings.where((booking) => booking.status == 'cancelled').toList();
});
