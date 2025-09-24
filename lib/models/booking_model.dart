import 'package:flutter/foundation.dart';

class Booking {
  final int id;
  final int rideId;
  final int passengerId;
  final int seatsBooked;
  final double? totalPrice;
  final String status;
  final String bookingCode;
  final String? specialRequests;
  final String? pickupLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? notes;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ ENHANCED: Additional fields from API
  final String? passengerName;
  final String? passengerEmail;
  final String? passengerPhone;
  final String? passengerAvatar;
  final RideInfo? ride;
  final bool isDriverBooking;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? rejectedAt;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    this.totalPrice,
    required this.status,
    required this.bookingCode,
    this.specialRequests,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.notes,
    this.cancelledAt,
    this.cancellationReason,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    // Enhanced fields
    this.passengerName,
    this.passengerEmail,
    this.passengerPhone,
    this.passengerAvatar,
    this.ride,
    this.isDriverBooking = false,
    this.confirmedAt,
    this.completedAt,
    this.rejectedAt,
  });

  // ✅ ENHANCED: Comprehensive factory method with null safety
  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      return Booking(
        id: _parseInteger(json['id']) ?? 0,
        rideId: _parseInteger(json['rideId']) ?? 0,
        passengerId: _parseInteger(json['passengerId']) ?? 0,
        seatsBooked: _parseInteger(json['seatsBooked']) ?? 1,
        totalPrice: _parseDouble(json['totalPrice']),
        status: json['status']?.toString() ?? 'pending',
        bookingCode: json['bookingCode']?.toString() ?? '',
        specialRequests: json['specialRequests']?.toString(),
        pickupLocation: json['pickupLocation']?.toString(),
        pickupLatitude: _parseDouble(json['pickupLatitude']),
        pickupLongitude: _parseDouble(json['pickupLongitude']),
        notes: json['notes']?.toString(),
        cancelledAt: _parseDateTime(json['cancelledAt']),
        cancellationReason: json['cancellationReason']?.toString(),
        rejectionReason: json['rejectionReason']?.toString(),
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
        // Enhanced fields
        passengerName: json['passengerName']?.toString() ?? 
                      json['passenger']?['name']?.toString(),
        passengerEmail: json['passengerEmail']?.toString() ?? 
                       json['passenger']?['email']?.toString(),
        passengerPhone: json['passengerPhone']?.toString() ?? 
                       json['passenger']?['phone']?.toString(),
        passengerAvatar: json['passengerAvatar']?.toString() ?? 
                        json['passenger']?['profileImageUrl']?.toString(),
        ride: json['ride'] != null ? RideInfo.fromJson(json['ride']) : null,
        isDriverBooking: json['isDriverBooking'] == true,
        confirmedAt: _parseDateTime(json['confirmedAt']),
        completedAt: _parseDateTime(json['completedAt']),
        rejectedAt: _parseDateTime(json['rejectedAt']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing Booking from JSON: $e');
        print('❌ JSON data: $json');
      }
      rethrow;
    }
  }

  // ✅ ENHANCED: Complete toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'seatsBooked': seatsBooked,
      'totalPrice': totalPrice,
      'status': status,
      'bookingCode': bookingCode,
      'specialRequests': specialRequests,
      'pickupLocation': pickupLocation,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'notes': notes,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Enhanced fields
      'passengerName': passengerName,
      'passengerEmail': passengerEmail,
      'passengerPhone': passengerPhone,
      'passengerAvatar': passengerAvatar,
      'ride': ride?.toJson(),
      'isDriverBooking': isDriverBooking,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
    };
  }

  // ✅ ENHANCED: Complete copyWith method
  Booking copyWith({
    int? id,
    int? rideId,
    int? passengerId,
    int? seatsBooked,
    double? totalPrice,
    String? status,
    String? bookingCode,
    String? specialRequests,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? notes,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Enhanced fields
    String? passengerName,
    String? passengerEmail,
    String? passengerPhone,
    String? passengerAvatar,
    RideInfo? ride,
    bool? isDriverBooking,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? rejectedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      bookingCode: bookingCode ?? this.bookingCode,
      specialRequests: specialRequests ?? this.specialRequests,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      notes: notes ?? this.notes,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Enhanced fields
      passengerName: passengerName ?? this.passengerName,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerAvatar: passengerAvatar ?? this.passengerAvatar,
      ride: ride ?? this.ride,
      isDriverBooking: isDriverBooking ?? this.isDriverBooking,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }

  // ✅ ENHANCED: Status helpers with all possible statuses
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isActive => isConfirmed || isPending;
  bool get isFinished => isCompleted || isCancelled || isRejected;

  // ✅ ENHANCED: Status display text with all cases
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغى';
      case 'completed':
        return 'مكتمل';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  // ✅ NEW: Color for status
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'green';
      case 'completed':
        return 'blue';
      case 'cancelled':
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  // ✅ NEW: Formatted price
  String get formattedPrice {
    if (totalPrice == null || totalPrice == 0) return 'غير محدد';
    return '${totalPrice!.toStringAsFixed(0)} ر.س';
  }

  // ✅ NEW: Formatted pickup location
  String get formattedPickupLocation {
    if (pickupLocation?.isEmpty ?? true) return 'نقطة الانطلاق الأساسية';
    return pickupLocation!;
  }

  // ✅ NEW: Has coordinates
  bool get hasPickupCoordinates {
    return pickupLatitude != null && 
           pickupLongitude != null && 
           pickupLatitude! != 0.0 && 
           pickupLongitude! != 0.0;
  }

  // ✅ NEW: Route display
  String get routeDisplay {
    if (ride != null) {
      return '${ride!.fromCity} → ${ride!.toCity}';
    }
    return 'رحلة غير محددة';
  }

  // ✅ NEW: Passenger display name
  String get displayPassengerName {
    if (passengerName?.isNotEmpty == true) return passengerName!;
    return 'راكب #$passengerId';
  }

  // ✅ NEW: Can be cancelled
  bool get canBeCancelled {
    return isPending || isConfirmed;
  }

  // ✅ NEW: Can be modified
  bool get canBeModified {
    return isPending;
  }

  // ✅ NEW: Days until ride
  int? get daysUntilRide {
    if (ride?.departureDate == null) return null;
    final difference = ride!.departureDate!.difference(DateTime.now()).inDays;
    return difference >= 0 ? difference : null;
  }

  // ✅ NEW: Static helper methods for parsing
  static int? _parseInteger(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parsing DateTime from string: $value');
        }
        return null;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking{id: $id, rideId: $rideId, status: $status, seatsBooked: $seatsBooked, totalPrice: $totalPrice}';
  }
}

// ✅ ENHANCED: RideInfo model for nested ride data
class RideInfo {
  final int? id;
  final String? fromCity;
  final String? toCity;
  final DateTime? departureDate;
  final String? departureTime;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatar;
  final double? pricePerSeat;
  final int? availableSeats;
  final String? carModel;
  final String? carColor;
  final String? carPlateNumber;

  RideInfo({
    this.id,
    this.fromCity,
    this.toCity,
    this.departureDate,
    this.departureTime,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverAvatar,
    this.pricePerSeat,
    this.availableSeats,
    this.carModel,
    this.carColor,
    this.carPlateNumber,
  });

  factory RideInfo.fromJson(Map<String, dynamic> json) {
    try {
      return RideInfo(
        id: Booking._parseInteger(json['id']),
        fromCity: json['fromCity']?.toString(),
        toCity: json['toCity']?.toString(),
        departureDate: Booking._parseDateTime(json['departureDate']),
        departureTime: json['departureTime']?.toString(),
        driverId: Booking._parseInteger(json['driverId']) ?? 
                 Booking._parseInteger(json['driver']?['id']),
        driverName: json['driverName']?.toString() ?? 
                   json['driver']?['name']?.toString(),
        driverPhone: json['driverPhone']?.toString() ?? 
                    json['driver']?['phone']?.toString(),
        driverAvatar: json['driverAvatar']?.toString() ?? 
                     json['driver']?['profileImageUrl']?.toString(),
        pricePerSeat: Booking._parseDouble(json['pricePerSeat']),
        availableSeats: Booking._parseInteger(json['availableSeats']),
        carModel: json['carModel']?.toString() ?? 
                 json['car']?['model']?.toString(),
        carColor: json['carColor']?.toString() ?? 
                 json['car']?['color']?.toString(),
        carPlateNumber: json['carPlateNumber']?.toString() ?? 
                       json['car']?['plateNumber']?.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing RideInfo from JSON: $e');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCity': fromCity,
      'toCity': toCity,
      'departureDate': departureDate?.toIso8601String(),
      'departureTime': departureTime,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverAvatar': driverAvatar,
      'pricePerSeat': pricePerSeat,
      'availableSeats': availableSeats,
      'carModel': carModel,
      'carColor': carColor,
      'carPlateNumber': carPlateNumber,
    };
  }

  // ✅ Helper methods for RideInfo
  String get routeDisplay => '${fromCity ?? 'غير محدد'} → ${toCity ?? 'غير محدد'}';
  
  String get driverDisplayName => driverName ?? 'السائق';
  
  String get carDisplayInfo {
    if (carModel != null && carColor != null) {
      return '$carModel $carColor';
    } else if (carModel != null) {
      return carModel!;
    } else if (carColor != null) {
      return 'سيارة $carColor';
    }
    return 'سيارة غير محددة';
  }

  String get formattedPrice {
    if (pricePerSeat == null || pricePerSeat == 0) return 'غير محدد';
    return '${pricePerSeat!.toStringAsFixed(0)} ر.س';
  }

  @override
  String toString() {
    return 'RideInfo{id: $id, fromCity: $fromCity, toCity: $toCity, driverName: $driverName}';
  }
}
