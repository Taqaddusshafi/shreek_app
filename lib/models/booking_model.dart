class Booking {
  final int id;
  final int rideId;
  final int passengerId;
  final int seatsBooked;
  final double totalPrice;
  final String status;
  final String bookingCode;
  final String? specialRequests;
  final String pickupLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? notes;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.totalPrice,
    required this.status,
    required this.bookingCode,
    this.specialRequests,
    required this.pickupLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.notes,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      rideId: json['rideId'],
      passengerId: json['passengerId'],
      seatsBooked: json['seatsBooked'],
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      status: json['status'],
      bookingCode: json['bookingCode'],
      specialRequests: json['specialRequests'],
      pickupLocation: json['pickupLocation'] ?? '',
      pickupLatitude: json['pickupLatitude']?.toDouble() ?? 0.0,
      pickupLongitude: json['pickupLongitude']?.toDouble() ?? 0.0,
      notes: json['notes'],
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغى';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }
}
