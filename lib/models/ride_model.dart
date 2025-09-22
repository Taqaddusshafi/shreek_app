import 'dart:math' as math;

class Ride {
  final int id;
  final int driverId;
  final String driverName;
  final String? driverPhone;
  final double? driverRating;
  final String fromCity;
  final String fromAddress;
  final double fromLatitude;
  final double fromLongitude;
  final String toCity;
  final String toAddress;
  final double toLatitude;
  final double toLongitude;
  final DateTime departureTime;
  final int availableSeats;
  final int seatsAvailable;
  final double pricePerSeat;
  final String? description;
  final bool isFemaleOnly;
  final String status;
  final List<StopPoint> stopPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.driverRating,
    required this.fromCity,
    required this.fromAddress,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toCity,
    required this.toAddress,
    required this.toLatitude,
    required this.toLongitude,
    required this.departureTime,
    required this.availableSeats,
    required this.seatsAvailable,
    required this.pricePerSeat,
    this.description,
    required this.isFemaleOnly,
    required this.status,
    this.stopPoints = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      driverId: json['driverId'],
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'],
      driverRating: json['driverRating']?.toDouble(),
      fromCity: json['fromCity'],
      fromAddress: json['fromAddress'] ?? '',
      fromLatitude: json['fromLatitude']?.toDouble() ?? 0.0,
      fromLongitude: json['fromLongitude']?.toDouble() ?? 0.0,
      toCity: json['toCity'],
      toAddress: json['toAddress'] ?? '',
      toLatitude: json['toLatitude']?.toDouble() ?? 0.0,
      toLongitude: json['toLongitude']?.toDouble() ?? 0.0,
      departureTime: DateTime.parse(json['departureTime']),
      availableSeats: json['availableSeats'] ?? json['seatsAvailable'] ?? 0,
      seatsAvailable: json['seatsAvailable'] ?? json['availableSeats'] ?? 0,
      pricePerSeat: json['pricePerSeat']?.toDouble() ?? json['price']?.toDouble() ?? 0.0,
      description: json['description'],
      isFemaleOnly: json['isFemaleOnly'] ?? false,
      status: json['status'] ?? 'active',
      stopPoints: json['stopPoints'] != null
          ? (json['stopPoints'] as List)
              .map((stop) => StopPoint.fromJson(stop))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverRating': driverRating,
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
      'seatsAvailable': seatsAvailable,
      'pricePerSeat': pricePerSeat,
      'description': description,
      'isFemaleOnly': isFemaleOnly,
      'status': status,
      'stopPoints': stopPoints.map((stop) => stop.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ✅ FIXED: Legacy compatibility getters
  String get fromLocation => fromCity;
  String get toLocation => toCity;
  double get price => pricePerSeat;
  int get totalSeats => availableSeats;
  String get rideType => isFemaleOnly ? 'female_only' : 'mixed';
  String get rideTypeDisplayText => isFemaleOnly ? 'نساء فقط' : 'مختلط';
  DateTime get departureDate => departureTime;
  String get departureTimeString => 
      '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';

  // ✅ FIXED: Driver object - simplified without circular dependency
  DriverInfo get driver => DriverInfo(
    id: driverId,
    firstName: driverName.split(' ').first,
    lastName: driverName.split(' ').skip(1).join(' '),
    fullName: driverName,
    name: driverName,
    rating: driverRating,
    profileImage: null, // Add if available from API
  );

  // Helper methods for UI
  String get routeDisplay => '$fromCity → $toCity';
  String get priceDisplay => '${pricePerSeat.toStringAsFixed(0)} ريال';
  String get seatsDisplay => '$seatsAvailable/$availableSeats متاح';
  String get timeDisplay => departureTimeString;
  String get dateDisplay => '${departureTime.day}/${departureTime.month}/${departureTime.year}';

  // Status helpers
  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشطة';
      case 'pending':
        return 'في الانتظار';
      case 'cancelled':
        return 'ملغية';
      case 'completed':
        return 'مكتملة';
      default:
        return status;
    }
  }

  // Availability helpers
  bool get hasAvailableSeats => seatsAvailable > 0;
  bool get isFull => seatsAvailable <= 0;

  // Distance calculation helper
  double distanceFromUser(double userLat, double userLng) {
    const double earthRadius = 6371; // km
    
    double dLat = _degreesToRadians(fromLatitude - userLat);
    double dLng = _degreesToRadians(fromLongitude - userLng);
    
    double a = math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(_degreesToRadians(userLat)) * math.cos(_degreesToRadians(fromLatitude)) *
        math.sin(dLng/2) * math.sin(dLng/2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Copyable method for updates
  Ride copyWith({
    int? id,
    int? driverId,
    String? driverName,
    String? driverPhone,
    double? driverRating,
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
    int? seatsAvailable,
    double? pricePerSeat,
    String? description,
    bool? isFemaleOnly,
    String? status,
    List<StopPoint>? stopPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      fromCity: fromCity ?? this.fromCity,
      fromAddress: fromAddress ?? this.fromAddress,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      toCity: toCity ?? this.toCity,
      toAddress: toAddress ?? this.toAddress,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      description: description ?? this.description,
      isFemaleOnly: isFemaleOnly ?? this.isFemaleOnly,
      status: status ?? this.status,
      stopPoints: stopPoints ?? this.stopPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ✅ NEW: Simple driver info class to avoid circular dependency
class DriverInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String name;
  final double? rating;
  final String? profileImage;

  DriverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.name,
    this.rating,
    this.profileImage,
  });
}

class StopPoint {
  final int id;
  final int rideId;
  final String cityName;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime estimatedArrivalTime;
  final DateTime estimatedDepartureTime;
  final String? notes;
  final int order;
  final DateTime createdAt;

  StopPoint({
    required this.id,
    required this.rideId,
    required this.cityName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.estimatedArrivalTime,
    required this.estimatedDepartureTime,
    this.notes,
    required this.order,
    required this.createdAt,
  });

  factory StopPoint.fromJson(Map<String, dynamic> json) {
    return StopPoint(
      id: json['id'] ?? 0,
      rideId: json['rideId'] ?? 0,
      cityName: json['cityName'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      estimatedArrivalTime: DateTime.parse(json['estimatedArrivalTime']),
      estimatedDepartureTime: DateTime.parse(json['estimatedDepartureTime']),
      notes: json['notes'],
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'cityName': cityName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedArrivalTime': estimatedArrivalTime.toIso8601String(),
      'estimatedDepartureTime': estimatedDepartureTime.toIso8601String(),
      'notes': notes,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get timeDisplay => 
      '${estimatedArrivalTime.hour.toString().padLeft(2, '0')}:${estimatedArrivalTime.minute.toString().padLeft(2, '0')}';
  
  String get fullAddress => '$cityName - $address';
}

// ✅ FIXED: SearchParameters class
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
