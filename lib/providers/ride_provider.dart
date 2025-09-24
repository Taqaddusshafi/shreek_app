import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/ride_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'ride_provider.g.dart';

// ✅ ENHANCED: Ride State with comprehensive fields
class RideState {
  final List<Ride> rides;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int totalRides;
  final SearchParameters? searchParameters;

  RideState({
    this.rides = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
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

// ✅ ENHANCED: SearchParameters matching your API
class SearchParameters {
  final String fromCity;
  final String toCity;
  final String? departureDate;
  final int? passengers;
  final bool? isFemaleOnly;
  final double? maxPrice;
  final double? minPrice;
  final String? departureTime;
  final int? limit;
  final int? offset;
  final String? sortBy;
  final String? sortOrder;

  SearchParameters({
    required this.fromCity,
    required this.toCity,
    this.departureDate,
    this.passengers,
    this.isFemaleOnly,
    this.maxPrice,
    this.minPrice,
    this.departureTime,
    this.limit,
    this.offset,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromCity': fromCity,
      'toCity': toCity,
      if (departureDate != null) 'departureDate': departureDate,
      if (passengers != null) 'passengers': passengers,
      if (isFemaleOnly != null) 'isFemaleOnly': isFemaleOnly,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minPrice != null) 'minPrice': minPrice,
      if (departureTime != null) 'departureTime': departureTime,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }

  SearchParameters copyWith({
    String? fromCity,
    String? toCity,
    String? departureDate,
    int? passengers,
    bool? isFemaleOnly,
    double? maxPrice,
    double? minPrice,
    String? departureTime,
    int? limit,
    int? offset,
    String? sortBy,
    String? sortOrder,
  }) {
    return SearchParameters(
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      departureDate: departureDate ?? this.departureDate,
      passengers: passengers ?? this.passengers,
      isFemaleOnly: isFemaleOnly ?? this.isFemaleOnly,
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      departureTime: departureTime ?? this.departureTime,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

// ✅ FIXED: Ride Search Provider
@riverpod
class RideSearch extends _$RideSearch {
  late DioClient _dioClient;

  @override
  RideState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return RideState();
  }

  // ✅ FIXED: Search rides according to your API
  Future<void> searchRides(SearchParameters params, {bool loadMore = false}) async {
    if (!loadMore) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        searchParameters: params,
      );
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final queryParams = {
        ...params.toMap(),
        'limit': params.limit ?? 20,
        'offset': params.offset ?? (loadMore ? state.currentPage * 20 : 0),
      };

      final response = await _dioClient.dio.get(
        ApiConstants.searchRides,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> ridesJson = data['rides'] ?? data ?? [];
        final total = data['total'] ?? 0;
        final currentPage = data['currentPage'] ?? 1;
        final totalPages = data['totalPages'] ?? 1;
        
        final newRides = ridesJson.map((json) => Ride.fromJson(json)).toList();
        final hasMore = currentPage < totalPages;

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
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Search error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في البحث عن الرحلات',
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

  // ✅ FIXED: Load more rides
  Future<void> loadMoreRides() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    
    if (state.searchParameters != null) {
      final updatedParams = state.searchParameters!.copyWith(
        offset: state.rides.length,
      );
      await searchRides(updatedParams, loadMore: true);
    }
  }

  // ✅ FIXED: Search by stop points according to your API
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
      final queryParams = {
        'fromCity': fromCity,
        'toCity': toCity,
        if (intermediateCities != null && intermediateCities.isNotEmpty)
          'intermediateCities': intermediateCities.join(','),
        if (departureDate != null) 'departureDate': departureDate,
        if (passengers != null) 'passengers': passengers,
        if (isFemaleOnly != null) 'isFemaleOnly': isFemaleOnly,
        if (maxPrice != null) 'maxPrice': maxPrice,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.searchRidesByStops,
        queryParameters: queryParams,
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

  // ✅ NEW: Quick search method
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

// ✅ ENHANCED: My Rides Provider (for drivers)
@riverpod
class MyRides extends _$MyRides {
  late DioClient _dioClient;

  @override
  RideState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return RideState();
  }

  // ✅ FIXED: Load my rides according to your API
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
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.userRides,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> ridesJson = data['rides'] ?? data ?? [];
        final total = data['total'] ?? 0;
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
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في جلب رحلاتك',
      );
    }
  }

  // ✅ FIXED: Create ride according to your API structure
  Future<bool> createRide({
    required String fromCity,
    required String fromAddress,
    required double fromLatitude,
    required double fromLongitude,
    required String toCity,
    required String toAddress,
    required double toLatitude,
    required double toLongitude,
    required DateTime departureTime,
    required int availableSeats,
    required double pricePerSeat,
    required String description,
    required bool isFemaleOnly,
    List<Map<String, dynamic>>? stopPoints,
    String? notes,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.rides,
        data: {
          'fromCity': fromCity,
          'fromAddress': fromAddress,
          'fromLatitude': fromLatitude,
          'fromLongitude': fromLongitude,
          'toCity': toCity,
          'toAddress': toAddress,
          'toLatitude': toLatitude,
          'toLongitude': toLongitude,
          'departureTime': departureTime.toIso8601String(),
          'availableSeats': availableSeats,
          'pricePerSeat': pricePerSeat,
          'description': description,
          'isFemaleOnly': isFemaleOnly,
          if (notes != null) 'notes': notes,
          if (stopPoints != null && stopPoints.isNotEmpty)
            'stopPoints': stopPoints,
        },
      );

      if (response.statusCode == 200) {
        await loadMyRides(refresh: true);
        state = state.copyWith(isLoading: false);

        if (kDebugMode) {
          print('✅ Ride created successfully');
        }
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data?['message'] ?? 'فشل في إنشاء الرحلة',
      );
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Create ride error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في إنشاء الرحلة',
      );
      return false;
    }
  }

  // ✅ FIXED: Update ride according to your API
  Future<bool> updateRide({
    required int rideId,
    String? fromCity,
    String? fromAddress,
    double? fromLatitude,
    double? fromLongitude,
    String? toCity,
    String? toAddress,
    double? toLatitude,
    double? toLongitude,
    DateTime? departureTime,
    int? availableSeats,
    double? pricePerSeat,
    String? description,
    bool? isFemaleOnly,
    String? notes,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = <String, dynamic>{};
      
      if (fromCity != null) data['fromCity'] = fromCity;
      if (fromAddress != null) data['fromAddress'] = fromAddress;
      if (fromLatitude != null) data['fromLatitude'] = fromLatitude;
      if (fromLongitude != null) data['fromLongitude'] = fromLongitude;
      if (toCity != null) data['toCity'] = toCity;
      if (toAddress != null) data['toAddress'] = toAddress;
      if (toLatitude != null) data['toLatitude'] = toLatitude;
      if (toLongitude != null) data['toLongitude'] = toLongitude;
      if (departureTime != null) data['departureTime'] = departureTime.toIso8601String();
      if (availableSeats != null) data['availableSeats'] = availableSeats;
      if (pricePerSeat != null) data['pricePerSeat'] = pricePerSeat;
      if (description != null) data['description'] = description;
      if (isFemaleOnly != null) data['isFemaleOnly'] = isFemaleOnly;
      if (notes != null) data['notes'] = notes;

      final response = await _dioClient.dio.put(
        ApiConstants.rideById(rideId),
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

  // ✅ FIXED: Cancel ride
  Future<bool> cancelRide(int rideId) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.delete(ApiConstants.rideById(rideId));

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

  // ✅ NEW: Start ride
  Future<bool> startRide(int rideId) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.rideById(rideId)}/start',
      );

      if (response.statusCode == 200) {
        await loadMyRides(refresh: true);
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data?['message'] ?? 'فشل في بدء الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في بدء الرحلة',
      );
      return false;
    }
  }

  // ✅ FIXED: Complete ride
  Future<bool> completeRide(int rideId) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.rideById(rideId)}/complete',
      );

      if (response.statusCode == 200) {
        await loadMyRides(refresh: true);
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

  // ✅ FIXED: Add stop points
  Future<bool> addStopPoint({
    required int rideId,
    required String cityName,
    required String address,
    required double latitude,
    required double longitude,
    required DateTime estimatedArrivalTime,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.rideStopsById(rideId),
        data: {
          'cityName': cityName,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'estimatedArrivalTime': estimatedArrivalTime.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        await loadMyRides(refresh: true);
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'حدث خطأ في إضافة نقطة التوقف',
      );
      return false;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // ✅ NEW: Refresh all data
  Future<void> refreshAll() async {
    await loadMyRides(refresh: true);
  }
}

// ✅ FIXED: Single Ride Provider
@riverpod
Future<Ride?> getRide(GetRideRef ref, int rideId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get(ApiConstants.rideById(rideId));
    
    if (response.statusCode == 200) {
      final data = response.data['data'];
      return Ride.fromJson(data['ride'] ?? data);
    }
    return null;
  } on DioException catch (e) {
    throw e.response?.data?['message'] ?? 'حدث خطأ في جلب تفاصيل الرحلة';
  }
}

// ✅ FIXED: Get Ride Stop Points
@riverpod
Future<List<StopPoint>> getRideStops(GetRideStopsRef ref, int rideId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get(ApiConstants.rideStopsById(rideId));
    
    if (response.statusCode == 200) {
      final data = response.data['data'];
      final List<dynamic> stopsJson = data['stops'] ?? data ?? [];
      return stopsJson.map((json) => StopPoint.fromJson(json)).toList();
    }
    return [];
  } on DioException catch (e) {
    throw e.response?.data?['message'] ?? 'حدث خطأ في جلب نقاط التوقف';
  }
}

// ✅ NEW: Convenience Providers
final ridesListProvider = Provider<List<Ride>>((ref) {
  return ref.watch(rideSearchProvider).rides;
});

final myRidesListProvider = Provider<List<Ride>>((ref) {
  return ref.watch(myRidesProvider).rides;
});

final isRideSearchLoadingProvider = Provider<bool>((ref) {
  return ref.watch(rideSearchProvider).isLoading;
});

final rideSearchErrorProvider = Provider<String?>((ref) {
  return ref.watch(rideSearchProvider).error;
});

final totalRidesCountProvider = Provider<int>((ref) {
  return ref.watch(rideSearchProvider).totalRides;
});

final hasMoreRidesProvider = Provider<bool>((ref) {
  return ref.watch(rideSearchProvider).hasMore;
});
