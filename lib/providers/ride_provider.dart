import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/ride_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'ride_provider.g.dart';

// Enhanced Ride State with comprehensive fields
class RideState {
  final List<Ride> rides;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isCreating;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int totalRides;
  final SearchParameters? searchParameters;

  RideState({
    this.rides = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.totalRides = 0,
    this.searchParameters,
  });

  RideState copyWith({
    List<Ride>? rides,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? totalRides,
    SearchParameters? searchParameters,
  }) {
    return RideState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      totalRides: totalRides ?? this.totalRides,
      searchParameters: searchParameters ?? this.searchParameters,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => rides.isEmpty && !isLoading;
}

// Ride Search Provider
@riverpod
class RideSearch extends _$RideSearch {
  late DioClient _dioClient;

  @override
  RideState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return RideState();
  }

  // Search rides according to your API
  Future<void> searchRides(SearchParameters params, {bool loadMore = false}) async {
    if (!loadMore) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        searchParameters: params,
      );
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final queryParams = {
        ...params.toMap(),
        'limit': params.limit ?? 20,
        'offset': params.offset ?? (loadMore ? state.currentPage * 20 : 0),
      };

      if (kDebugMode) {
        print('🔍 Searching rides with params: $queryParams');
      }

      final response = await _dioClient.dio.get(
        ApiConstants.searchRides,
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📡 Search response status: ${response.statusCode}');
        print('📄 Search response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Handle different response structures
        final data = responseData['data'] ?? responseData;
        final List<dynamic> ridesJson = data['rides'] ?? data ?? [];
        final total = data['total'] ?? ridesJson.length;
        final currentPage = data['currentPage'] ?? data['page'] ?? 1;
        final totalPages = data['totalPages'] ?? (total / 20).ceil();
        
        final newRides = ridesJson.map((json) {
          try {
            return Ride.fromJson(json);
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error parsing ride: $e');
              print('📄 Problematic ride data: $json');
            }
            return null;
          }
        }).whereType<Ride>().toList();

        final hasMore = currentPage < totalPages || newRides.length >= 20;

        final updatedRides = loadMore 
            ? [...state.rides, ...newRides]
            : newRides;

        state = state.copyWith(
          rides: updatedRides,
          isLoading: false,
          isLoadingMore: false,
          currentPage: currentPage,
          hasMore: hasMore,
          totalRides: total,
        );

        if (kDebugMode) {
          print('✅ Search completed: ${newRides.length} rides loaded, total: $total');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Search DioException: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }

      String errorMessage = 'حدث خطأ في البحث عن الرحلات';
      
      if (e.response?.data != null) {
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
        print('❌ Unexpected search error: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // Load more rides
  Future<void> loadMoreRides() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    
    if (state.searchParameters != null) {
      final updatedParams = state.searchParameters!.copyWith(
        offset: state.rides.length,
      );
      await searchRides(updatedParams, loadMore: true);
    }
  }

  // Search by stop points
  Future<void> searchRidesByStops({
    required String fromCity,
    required String toCity,
    List<String>? intermediateCities,
    String? departureDate,
    int? passengers,
    bool? isFemaleOnly,
    double? maxPrice,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requestData = {
        'fromCity': fromCity,
        'toCity': toCity,
        if (intermediateCities != null && intermediateCities.isNotEmpty)
          'intermediateCities': intermediateCities,
        if (departureDate != null) 'date': departureDate,
        if (passengers != null) 'seats': passengers,
        if (isFemaleOnly != null) 'isFemaleOnly': isFemaleOnly,
        if (maxPrice != null) 'maxPrice': maxPrice,
      };

      final response = await _dioClient.dio.post(
        ApiConstants.searchRidesByStops,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> ridesJson = data['rides'] ?? data ?? [];
        final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();

        state = state.copyWith(
          rides: rides,
          isLoading: false,
          totalRides: rides.length,
        );

        if (kDebugMode) {
          print('✅ Stop points search completed: ${rides.length} rides found');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Stop points search error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في البحث عن الرحلات',
      );
    }
  }

  // Quick search method
  Future<void> quickSearch({
    required String fromCity,
    required String toCity,
    String? departureDate,
    int? passengers,
  }) async {
    final params = SearchParameters(
      fromCity: fromCity,
      toCity: toCity,
      departureDate: departureDate,
      passengers: passengers,
      limit: 20,
      sortBy: 'departureTime',
      sortOrder: 'asc',
    );

    await searchRides(params);
  }

  void clearRides() {
    state = RideState();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

// My Rides Provider (for drivers)
@riverpod
class MyRides extends _$MyRides {
  late DioClient _dioClient;

  @override
  RideState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return RideState();
  }

  // Load my rides
  Future<void> loadMyRides({
    String? status,
    int limit = 20,
    int offset = 0,
    bool refresh = false,
  }) async {
    if (!refresh && state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        'type': 'created', // Important: specify we want created rides
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      };

      if (kDebugMode) {
        print('📡 Loading my rides with params: $queryParams');
      }

      final response = await _dioClient.dio.get(
        ApiConstants.userRides,
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📡 My rides response status: ${response.statusCode}');
        print('📄 My rides response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> ridesJson = data['rides'] ?? data ?? [];
        final total = data['total'] ?? ridesJson.length;
        final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();

        state = state.copyWith(
          rides: rides,
          isLoading: false,
          totalRides: total,
        );

        if (kDebugMode) {
          print('✅ My rides loaded: ${rides.length} rides');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load my rides error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      String errorMessage = 'حدث خطأ في جلب رحلاتك';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'يجب إعادة تسجيل الدخول';
      } else if (e.response?.data != null) {
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
        error: errorMessage,
      );
    }
  }

  // Create ride matching your API exactly
  Future<bool> createRide(CreateRideRequest request) async {
    if (state.isCreating) {
      if (kDebugMode) {
        print('⚠️ Ride creation already in progress');
      }
      return false;
    }
    
    state = state.copyWith(isCreating: true, error: null);

    try {
      if (kDebugMode) {
        print('🚗 Creating ride with data: ${request.toJson()}');
      }

      final response = await _dioClient.dio.post(
        ApiConstants.rides,
        data: request.toJson(),
      );

      if (kDebugMode) {
        print('📡 Create ride response status: ${response.statusCode}');
        print('📄 Create ride response data: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the created ride from response
        final responseData = response.data;
        
        // Check if response indicates success
        if (responseData['status'] == 'success' || responseData.containsKey('data')) {
          if (kDebugMode) {
            print('✅ Ride created successfully');
          }

          // Try to extract the created ride data
          try {
            final rideData = responseData['data']?['ride'] ?? 
                             responseData['data'] ?? 
                             responseData['ride'];
            
            if (rideData != null) {
              final createdRide = Ride.fromJson(rideData);
              
              // Add to my rides list at the beginning
              final updatedRides = [createdRide, ...state.rides];
              state = state.copyWith(
                rides: updatedRides,
                isCreating: false,
                totalRides: state.totalRides + 1,
              );
            } else {
              // Successful creation but no ride data returned
              state = state.copyWith(isCreating: false);
              // Refresh the rides list
              await loadMyRides(refresh: true);
            }
          } catch (parseError) {
            if (kDebugMode) {
              print('❌ Error parsing created ride: $parseError');
            }
            // Still successful, just refresh the list
            state = state.copyWith(isCreating: false);
            await loadMyRides(refresh: true);
          }
          
          return true;
        }
      }
      
      // Handle error response
      String errorMessage = 'فشل في إنشاء الرحلة';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      if (kDebugMode) {
        print('❌ Create ride failed: $errorMessage');
      }

      state = state.copyWith(
        isCreating: false,
        error: errorMessage,
      );
      return false;

    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Create ride DioException: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }

      String errorMessage = 'حدث خطأ في إنشاء الرحلة';
      
      if (e.response?.statusCode == 400) {
        errorMessage = 'بيانات الرحلة غير صحيحة';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'غير مسموح لك بإنشاء رحلات';
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
        print('❌ Unexpected create ride error: $e');
      }
      
      state = state.copyWith(
        isCreating: false,
        error: 'حدث خطأ غير متوقع',
      );
      return false;
    }
  }

  // Update ride
  Future<bool> updateRide({
    required int rideId,
    Map<String, dynamic>? from,
    Map<String, dynamic>? to,
    DateTime? departureTime,
    int? availableSeats,
    double? price,
    String? description,
    bool? isFemaleOnly,
    List<Map<String, dynamic>>? stopPoints,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = <String, dynamic>{};
      
      if (from != null) data['from'] = from;
      if (to != null) data['to'] = to;
      if (departureTime != null) data['departureTime'] = departureTime.toIso8601String();
      if (availableSeats != null) data['availableSeats'] = availableSeats;
      if (price != null) data['price'] = price;
      if (description != null) data['description'] = description;
      if (isFemaleOnly != null) data['isFemaleOnly'] = isFemaleOnly;
      if (stopPoints != null) data['stopPoints'] = stopPoints;

      final response = await _dioClient.dio.put(
        '${ApiConstants.rides}/$rideId',
        data: data,
      );

      if (response.statusCode == 200) {
        await loadMyRides(refresh: true);
        state = state.copyWith(isLoading: false);

        if (kDebugMode) {
          print('✅ Ride updated successfully');
        }
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data?['message'] ?? 'فشل في تحديث الرحلة',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Update ride error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في تحديث الرحلة',
      );
      return false;
    }
  }

  // Cancel ride
  Future<bool> cancelRide(int rideId) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.delete('${ApiConstants.rides}/$rideId');

      if (response.statusCode == 200) {
        final updatedRides = state.rides
            .where((ride) => ride.id != rideId)
            .toList();
        
        state = state.copyWith(
          rides: updatedRides,
          isLoading: false,
          totalRides: state.totalRides - 1,
        );

        if (kDebugMode) {
          print('✅ Ride cancelled successfully');
        }
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data?['message'] ?? 'فشل في إلغاء الرحلة',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Cancel ride error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في إلغاء الرحلة',
      );
      return false;
    }
  }

  // Complete ride
  Future<bool> completeRide(int rideId) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.rides}/$rideId/complete',
      );

      if (response.statusCode == 200) {
        await loadMyRides(refresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data?['message'] ?? 'فشل في إكمال الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في إكمال الرحلة',
      );
      return false;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await loadMyRides(refresh: true);
  }
}

// Single Ride Provider
@riverpod
Future<Ride?> getRide(GetRideRef ref, int rideId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get('${ApiConstants.rides}/$rideId');
    
    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final rideData = data['ride'] ?? data;
      return Ride.fromJson(rideData);
    }
    return null;
  } on DioException catch (e) {
    throw e.response?.data?['message'] ?? 'حدث خطأ في جلب تفاصيل الرحلة';
  }
}

// Convenience Providers
final ridesListProvider = Provider<List<Ride>>((ref) {
  return ref.watch(rideSearchProvider).rides;
});

final myRidesListProvider = Provider<List<Ride>>((ref) {
  return ref.watch(myRidesProvider).rides;
});

final isRideSearchLoadingProvider = Provider<bool>((ref) {
  return ref.watch(rideSearchProvider).isLoading;
});

final isMyRidesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(myRidesProvider).isLoading;
});

final isRideCreatingProvider = Provider<bool>((ref) {
  return ref.watch(myRidesProvider).isCreating;
});

final rideSearchErrorProvider = Provider<String?>((ref) {
  return ref.watch(rideSearchProvider).error;
});

final myRidesErrorProvider = Provider<String?>((ref) {
  return ref.watch(myRidesProvider).error;
});

final totalRidesCountProvider = Provider<int>((ref) {
  return ref.watch(rideSearchProvider).totalRides;
});

final hasMoreRidesProvider = Provider<bool>((ref) {
  return ref.watch(rideSearchProvider).hasMore;
});
