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
  final bool isCreating;
  final bool isUpdating;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int totalBookings;
  final Map<String, dynamic>? stats;

  BookingState({
    this.bookings = const [],
    this.myBookings = const [],
    this.driverBookings = const [],
    this.upcomingBookings = const [],
    this.completedBookings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.totalBookings = 0,
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
    bool? isCreating,
    bool? isUpdating,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? totalBookings,
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
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      totalBookings: totalBookings ?? this.totalBookings,
      stats: stats ?? this.stats,
    );
  }

  // Helper getters for filtering
  List<Booking> get pendingBookings => bookings.where((b) => b.isPending).toList();
  List<Booking> get confirmedBookings => bookings.where((b) => b.isConfirmed).toList();
  List<Booking> get cancelledBookings => bookings.where((b) => b.isCancelled).toList();
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

  // ✅ FIXED: Load my bookings with proper endpoint usage
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
        'type': 'passenger', // Specify we want passenger bookings
      };

      if (kDebugMode) {
        print('📡 Request params: $queryParams');
      }

      final response = await _dioClient.dio.get(
        ApiConstants.bookings, // ✅ Fixed: Use correct endpoint
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📡 My bookings response: ${response.statusCode}');
        print('📄 Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData['data'] ?? responseData;
        final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];
        final pagination = data['pagination'] ?? {};
        final total = data['total'] ?? bookingsJson.length;

        final newBookings = bookingsJson
            .map((json) {
              try {
                return Booking.fromJson(json);
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Error parsing booking: $e');
                  print('📄 Problematic booking data: $json');
                }
                return null;
              }
            })
            .whereType<Booking>()
            .toList();

        final updatedBookings = refresh || isInitialLoad
            ? newBookings
            : [...state.myBookings, ...newBookings];

        state = state.copyWith(
          myBookings: updatedBookings,
          bookings: updatedBookings, // Update main bookings list too
          currentPage: newPage,
          hasMore: pagination['hasNext'] ?? newBookings.length >= limit,
          totalBookings: total,
          isLoading: false,
          isLoadingMore: false,
        );

        if (kDebugMode) {
          print('✅ Loaded ${newBookings.length} bookings, Total: ${updatedBookings.length}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load my bookings DioException: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }

      String errorMessage = 'حدث خطأ في جلب الحجوزات';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب إعادة تسجيل الدخول';
      } else if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message'] as String? ?? errorMessage;
          } else if (errorData is String) {
            errorMessage = errorData;
          }
        } catch (parseError) {
          // Use default error message
        }
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: errorMessage,
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

  // ✅ FIXED: Load driver bookings with proper endpoint
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
        ApiConstants.driverBookings, // ✅ Fixed: Use correct endpoint
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📡 Driver bookings response: ${response.statusCode}');
        print('📄 Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData['data'] ?? responseData;
        final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];
        final pagination = data['pagination'] ?? {};
        final total = data['total'] ?? bookingsJson.length;

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
          totalBookings: total,
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
        print('❌ Error data: ${e.response?.data}');
      }

      String errorMessage = 'حدث خطأ في جلب حجوزات الرحلات';
      
      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message'] as String? ?? errorMessage;
          }
        } catch (parseError) {
          // Use default error message
        }
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ✅ FIXED: Create booking with proper validation and endpoint
  Future<bool> createBooking({
    required int rideId,
    required int seatsBooked,
    String? specialRequests,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? dropoffLocation,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? notes,
  }) async {
    if (state.isCreating) {
      if (kDebugMode) {
        print('⚠️ Booking creation already in progress');
      }
      return false;
    }

    state = state.copyWith(isCreating: true, error: null);

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
        if (dropoffLocation?.isNotEmpty == true) 'dropoffLocation': dropoffLocation,
        if (dropoffLatitude != null) 'dropoffLatitude': dropoffLatitude,
        if (dropoffLongitude != null) 'dropoffLongitude': dropoffLongitude,
        if (notes?.isNotEmpty == true) 'notes': notes,
      };

      if (kDebugMode) {
        print('📤 Booking request data: $requestData');
      }

      final response = await _dioClient.dio.post(
        ApiConstants.bookings,
        data: requestData,
      );

      if (kDebugMode) {
        print('📡 Create booking response status: ${response.statusCode}');
        print('📄 Create booking response data: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        // Check if response indicates success
        if (responseData['status'] == 'success' || responseData.containsKey('data')) {
          if (kDebugMode) {
            print('✅ Booking created successfully');
          }

          // Try to extract the created booking data
          try {
            final bookingData = responseData['data']?['booking'] ?? 
                               responseData['data'] ?? 
                               responseData['booking'];
            
            if (bookingData != null) {
              final createdBooking = Booking.fromJson(bookingData);
              
              // Add to bookings list at the beginning
              final updatedBookings = [createdBooking, ...state.myBookings];
              state = state.copyWith(
                myBookings: updatedBookings,
                bookings: updatedBookings,
                isCreating: false,
                totalBookings: state.totalBookings + 1,
              );
            } else {
              // Successful creation but no booking data returned
              state = state.copyWith(isCreating: false);
              // Refresh the bookings list
              await loadMyBookings(refresh: true);
            }
          } catch (parseError) {
            if (kDebugMode) {
              print('❌ Error parsing created booking: $parseError');
            }
            // Still successful, just refresh the list
            state = state.copyWith(isCreating: false);
            await loadMyBookings(refresh: true);
          }
          
          return true;
        }
      }
      
      // Handle error response
      String errorMessage = 'فشل في إنشاء الحجز';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      if (kDebugMode) {
        print('❌ Create booking failed: $errorMessage');
      }

      state = state.copyWith(
        isCreating: false,
        error: errorMessage,
      );
      return false;

    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Create booking DioException: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }

      String errorMessage = 'حدث خطأ في إنشاء الحجز';
      
      if (e.response?.statusCode == 400) {
        errorMessage = 'بيانات الحجز غير صحيحة';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'غير مسموح لك بإنشاء هذا الحجز';
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'الرحلة ممتلئة أو غير متاحة';
      } else if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message'] as String? ?? errorMessage;
          } else if (errorData is String) {
            errorMessage = errorData;
          }
        } catch (parseError) {
          // Use default error message
        }
      }

      state = state.copyWith(
        isCreating: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected create booking error: $e');
      }
      
      state = state.copyWith(
        isCreating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // ✅ FIXED: Cancel booking with proper endpoint
  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    if (state.isUpdating) return false;
    
    state = state.copyWith(isUpdating: true, error: null);

    if (kDebugMode) {
      print('❌ Cancelling booking $bookingId, Reason: ${reason ?? 'No reason provided'}');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.cancelBookingById(bookingId), // ✅ Fixed: Use helper method
        data: reason != null ? {'cancellationReason': reason} : null,
      );

      if (kDebugMode) {
        print('📡 Cancel booking response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking cancelled successfully');
        }

        // Update the booking status in current state
        _updateBookingStatus(bookingId, 'cancelled');
        
        state = state.copyWith(isUpdating: false);
        return true;
      }
      
      state = state.copyWith(
        isUpdating: false,
        error: response.data?['message'] ?? 'فشل في إلغاء الحجز',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Cancel booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isUpdating: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في إلغاء الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // ✅ FIXED: Accept booking request with proper endpoint
  Future<bool> acceptBooking(int bookingId, {String? notes}) async {
    if (state.isUpdating) return false;
    
    state = state.copyWith(isUpdating: true, error: null);

    if (kDebugMode) {
      print('✅ Accepting booking $bookingId');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.acceptBookingById(bookingId), // ✅ Fixed: Use helper method
        data: notes != null ? {'notes': notes} : null,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking accepted successfully');
        }

        // Update booking status in current state
        _updateBookingStatus(bookingId, 'confirmed');
        
        state = state.copyWith(isUpdating: false);
        return true;
      }
      
      state = state.copyWith(
        isUpdating: false,
        error: response.data?['message'] ?? 'فشل في قبول الحجز',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Accept booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isUpdating: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في قبول الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // ✅ FIXED: Reject booking request with proper endpoint
  Future<bool> rejectBooking(int bookingId, {String? reason}) async {
    if (state.isUpdating) return false;
    
    state = state.copyWith(isUpdating: true, error: null);

    if (kDebugMode) {
      print('❌ Rejecting booking $bookingId, Reason: ${reason ?? 'No reason provided'}');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.rejectBookingById(bookingId), // ✅ Fixed: Use helper method
        data: reason != null ? {'rejectionReason': reason} : null,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking rejected successfully');
        }

        // Update booking status in current state
        _updateBookingStatus(bookingId, 'rejected');
        
        state = state.copyWith(isUpdating: false);
        return true;
      }
      
      state = state.copyWith(
        isUpdating: false,
        error: response.data?['message'] ?? 'فشل في رفض الحجز',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Reject booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isUpdating: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في رفض الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // ✅ FIXED: Confirm booking with proper endpoint
  Future<bool> confirmBooking(int bookingId) async {
    if (state.isUpdating) return false;
    
    state = state.copyWith(isUpdating: true, error: null);

    if (kDebugMode) {
      print('✅ Confirming booking $bookingId');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.confirmBookingById(bookingId), // ✅ Fixed: Use helper method
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking confirmed successfully');
        }

        // Update booking status in current state
        _updateBookingStatus(bookingId, 'confirmed');
        
        state = state.copyWith(isUpdating: false);
        return true;
      }
      
      state = state.copyWith(
        isUpdating: false,
        error: response.data?['message'] ?? 'فشل في تأكيد الحجز',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Confirm booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isUpdating: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في تأكيد الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // ✅ FIXED: Complete booking with proper endpoint
  Future<bool> completeBooking(int bookingId) async {
    if (state.isUpdating) return false;
    
    state = state.copyWith(isUpdating: true, error: null);

    if (kDebugMode) {
      print('🏁 Completing booking $bookingId');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.completeBookingById(bookingId), // ✅ Fixed: Use helper method
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Booking completed successfully');
        }

        // Update booking status in current state
        _updateBookingStatus(bookingId, 'completed');
        
        state = state.copyWith(isUpdating: false);
        return true;
      }
      
      state = state.copyWith(
        isUpdating: false,
        error: response.data?['message'] ?? 'فشل في إكمال الحجز',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Complete booking error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isUpdating: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في إكمال الحجز',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // ✅ FIXED: Get single booking
  Future<Booking?> getBooking(int bookingId) async {
    try {
      if (kDebugMode) {
        print('🔍 Getting booking $bookingId');
      }

      final response = await _dioClient.dio.get(
        ApiConstants.bookingById(bookingId), // ✅ Fixed: Use helper method
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final bookingData = data['booking'] ?? data;
        
        if (kDebugMode) {
          print('✅ Booking fetched successfully');
        }
        
        return Booking.fromJson(bookingData);
      }
      
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Get booking error: ${e.response?.statusCode}');
      }
      
      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'حدث خطأ في جلب تفاصيل الحجز',
      );
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected get booking error: $e');
      }
      
      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return null;
    }
  }

  // ✅ FIXED: Load booking statistics
  Future<void> loadBookingStats() async {
    if (kDebugMode) {
      print('📊 Loading booking statistics');
    }

    try {
      final response = await _dioClient.dio.get(ApiConstants.bookingStats);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final stats = responseData['data'] ?? responseData;
        
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected stats error: $e');
      }
      // Don't set error for stats, it's not critical
    }
  }

  // ✅ FIXED: Search bookings with proper endpoint
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
        ApiConstants.bookings,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData['data'] ?? responseData;
        final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];

        final searchResults = bookingsJson
            .map((json) => Booking.fromJson(json))
            .toList();

        state = state.copyWith(
          bookings: searchResults,
          myBookings: searchResults,
          isLoading: false,
          totalBookings: searchResults.length,
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
        error: e.response?.data?['message'] ?? 'حدث خطأ في البحث عن الحجوزات',
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

  // ✅ Load bookings by status
  Future<void> loadBookingsByStatus(String status, {bool refresh = false}) async {
    if (kDebugMode) {
      print('🔍 Loading bookings with status: $status');
    }

    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
      case 'completed':
      case 'cancelled':
      case 'rejected':
        await loadMyBookings(refresh: refresh, status: status);
        break;
      default:
        await loadMyBookings(refresh: refresh);
    }
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

// ✅ FIXED: Get single booking provider
@riverpod
Future<Booking?> getBooking(GetBookingRef ref, int bookingId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get(ApiConstants.bookingById(bookingId));
    
    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final bookingData = data['booking'] ?? data;
      return Booking.fromJson(bookingData);
    }
    return null;
  } on DioException catch (e) {
    throw e.response?.data?['message'] ?? 'حدث خطأ في جلب تفاصيل الحجز';
  }
}

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

final isBookingCreatingProvider = Provider<bool>((ref) {
  return ref.watch(myBookingsProvider).isCreating;
});

final isBookingUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(myBookingsProvider).isUpdating;
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

final hasMoreBookingsProvider = Provider<bool>((ref) {
  return ref.watch(myBookingsProvider).hasMore;
});
