import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/ride_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'ride_provider.g.dart';

// ✅ FIXED: Ride State with searchParameters
class RideState {
  final List<Ride> rides;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final SearchParameters? searchParameters; // ✅ Added

  RideState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.searchParameters, // ✅ Added
  });

  RideState copyWith({
    List<Ride>? rides,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    SearchParameters? searchParameters, // ✅ Added
  }) {
    return RideState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchParameters: searchParameters ?? this.searchParameters, // ✅ Added
    );
  }
}

// ✅ FIXED: SearchParameters with proper constructor
class SearchParameters {
  final String from;
  final String to;
  final String? date;
  final int? passengers;
  final bool? isFemaleOnly;
  final double? maxPrice;
  final int? limit;
  final int? offset;

  SearchParameters({
    required this.from,
    required this.to,
    this.date,
    this.passengers,
    this.isFemaleOnly,
    this.maxPrice,
    this.limit,
    this.offset,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromCity': from,
      'toCity': to,
      if (date != null) 'departureDate': date,
      if (passengers != null) 'passengers': passengers,
      if (isFemaleOnly != null) 'isFemaleOnly': isFemaleOnly,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
  }

  SearchParameters copyWith({
    String? from,
    String? to,
    String? date,
    int? passengers,
    bool? isFemaleOnly,
    double? maxPrice,
    int? limit,
    int? offset,
  }) {
    return SearchParameters(
      from: from ?? this.from,
      to: to ?? this.to,
      date: date ?? this.date,
      passengers: passengers ?? this.passengers,
      isFemaleOnly: isFemaleOnly ?? this.isFemaleOnly,
      maxPrice: maxPrice ?? this.maxPrice,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
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

  Future<void> searchRides(SearchParameters params, {bool loadMore = false}) async {
    if (!loadMore) {
      state = state.copyWith(
        isLoading: true, 
        error: null, 
        currentPage: 1,
        searchParameters: params, // ✅ Store search parameters
      );
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
        final data = response.data['data'];
        final List<dynamic> ridesJson = data['rides'] ?? [];
        final newRides = ridesJson.map((json) => Ride.fromJson(json)).toList();
        
        final hasMore = data['total'] > (state.rides.length + newRides.length);

        final updatedRides = loadMore 
            ? [...state.rides, ...newRides]
            : newRides;

        state = state.copyWith(
          rides: updatedRides,
          isLoading: false,
          currentPage: loadMore ? state.currentPage + 1 : 1,
          hasMore: hasMore,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في البحث',
      );
    }
  }

  // ✅ FIXED: loadMoreRides method
  Future<void> loadMoreRides() async {
    if (!state.hasMore || state.isLoading) return;
    
    if (state.searchParameters != null) {
      final updatedParams = state.searchParameters!.copyWith(
        offset: state.rides.length,
      );
      await searchRides(updatedParams, loadMore: true);
    }
  }

  // ✅ NEW: Search by stop points
  Future<void> searchRidesByStops({
    required String fromCity,
    required String toCity,
    List<String>? intermediateCities,
    String? date,
    int? seats,
    bool? isFemaleOnly,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.searchRidesByStops,
        data: {
          'fromCity': fromCity,
          'toCity': toCity,
          if (intermediateCities != null) 'intermediateCities': intermediateCities,
          if (date != null) 'date': date,
          if (seats != null) 'seats': seats,
          if (isFemaleOnly != null) 'isFemaleOnly': isFemaleOnly,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> ridesJson = data['rides'] ?? [];
        final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();

        state = state.copyWith(
          rides: rides,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في البحث',
      );
    }
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

  Future<void> loadMyRides({
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
        ApiConstants.rides,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> ridesJson = data['rides'] ?? [];
        final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();

        state = state.copyWith(
          rides: rides,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الرحلات',
      );
    }
  }

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
    required double price,
    required String description,
    required bool isFemaleOnly,
    List<Map<String, dynamic>>? stopPoints,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.rides,
        data: {
          'from': {
            'city': fromCity,
            'address': fromAddress,
            'coordinates': {
              'lat': fromLatitude,
              'lng': fromLongitude,
            },
          },
          'to': {
            'city': toCity,
            'address': toAddress,
            'coordinates': {
              'lat': toLatitude,
              'lng': toLongitude,
            },
          },
          'departureTime': departureTime.toIso8601String(),
          'availableSeats': availableSeats,
          'price': price,
          'description': description,
          'isFemaleOnly': isFemaleOnly,
          if (stopPoints != null && stopPoints.isNotEmpty)
            'stopPoints': stopPoints,
        },
      );

      if (response.statusCode == 200) {
        await loadMyRides();
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في إنشاء الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في إنشاء الرحلة',
      );
      return false;
    }
  }

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
    double? price,
    String? description,
    bool? isFemaleOnly,
  }) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = <String, dynamic>{};
      
      if (fromCity != null || fromAddress != null || fromLatitude != null || fromLongitude != null) {
        data['from'] = {
          if (fromCity != null) 'city': fromCity,
          if (fromAddress != null) 'address': fromAddress,
          if (fromLatitude != null && fromLongitude != null)
            'coordinates': {
              'lat': fromLatitude,
              'lng': fromLongitude,
            },
        };
      }

      if (toCity != null || toAddress != null || toLatitude != null || toLongitude != null) {
        data['to'] = {
          if (toCity != null) 'city': toCity,
          if (toAddress != null) 'address': toAddress,
          if (toLatitude != null && toLongitude != null)
            'coordinates': {
              'lat': toLatitude,
              'lng': toLongitude,
            },
        };
      }

      if (departureTime != null) data['departureTime'] = departureTime.toIso8601String();
      if (availableSeats != null) data['availableSeats'] = availableSeats;
      if (price != null) data['price'] = price;
      if (description != null) data['description'] = description;
      if (isFemaleOnly != null) data['isFemaleOnly'] = isFemaleOnly;

      final response = await _dioClient.dio.put(
        '${ApiConstants.rides}/$rideId',
        data: data,
      );

      if (response.statusCode == 200) {
        await loadMyRides();
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في تحديث الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في تحديث الرحلة',
      );
      return false;
    }
  }

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
        );
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في إلغاء الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في إلغاء الرحلة',
      );
      return false;
    }
  }

  // ✅ FIXED: Add completeRide method
  Future<bool> completeRide(int rideId) async {
    if (state.isLoading) return false;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.rides}/$rideId/complete',
      );

      if (response.statusCode == 200) {
        await loadMyRides(); // Refresh rides
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'فشل في إكمال الرحلة',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في إكمال الرحلة',
      );
      return false;
    }
  }

  // ✅ NEW: Add stop points to ride
  Future<bool> addStopPoint({
    required int rideId,
    required String cityName,
    required String address,
    required double latitude,
    required double longitude,
    required DateTime estimatedArrivalTime,
    required DateTime estimatedDepartureTime,
    String? notes,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.rideStops}/$rideId/stops',
        data: {
          'cityName': cityName,
          'address': address,
          'coordinates': {
            'lat': latitude,
            'lng': longitude,
          },
          'estimatedArrivalTime': estimatedArrivalTime.toIso8601String(),
          'estimatedDepartureTime': estimatedDepartureTime.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        await loadMyRides(); // Refresh to get updated stop points
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في إضافة نقطة التوقف',
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

// Single Ride Provider
@riverpod
Future<Ride?> getRide(GetRideRef ref, int rideId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get('${ApiConstants.rides}/$rideId');
    
    if (response.statusCode == 200) {
      final data = response.data['data']['ride'];
      return Ride.fromJson(data);
    }
    return null;
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? 'حدث خطأ في جلب تفاصيل الرحلة';
  }
}

// Get Ride Stop Points
@riverpod
Future<List<StopPoint>> getRideStops(GetRideStopsRef ref, int rideId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get('${ApiConstants.rideStops}/$rideId/stops');
    
    if (response.statusCode == 200) {
      final List<dynamic> stopsJson = response.data['data']['stops'];
      return stopsJson.map((json) => StopPoint.fromJson(json)).toList();
    }
    return [];
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? 'حدث خطأ في جلب نقاط التوقف';
  }
}
