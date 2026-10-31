class RideModel {
  final String? id;
  final String code;
  final String pickup;
  final String dropoff;
  final String vehicleId;
  final String vehicleName;
  final String packageType;
  final int weight;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final String recipientName;
  final String recipientPhone;
  final String? itemLabel;
  final String payment;
  final int price;
  final int distanceKm;
  final String pin;
  final DateTime createdAt;
  final String? scheduledAt;
  final String service; // 'ride' or 'courier'
  final String speed; // 'casual' | 'express' | 'scheduled'
  final String status; // 'pending', 'confirmed', 'accepted', 'to_pickup', 'at_pickup', 'on_trip', 'completed', 'cancelled'
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;

  // Driver details
  final String? driverId;
  final String driverName;
  final String driverPlate;
  final String driverVehicle;
  final double driverRating;
  final int driverTrips;
  final String driverPhone;

  RideModel({
    this.id,
    required this.code,
    required this.pickup,
    required this.dropoff,
    required this.vehicleId,
    required this.vehicleName,
    this.packageType = 'Ride',
    this.weight = 0,
    this.passengerId = '',
    this.passengerName = 'Passenger',
    this.passengerPhone = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.itemLabel,
    required this.payment,
    required this.price,
    required this.distanceKm,
    required this.pin,
    required this.createdAt,
    this.scheduledAt,
    this.service = 'ride',
    this.speed = 'casual',
    this.status = 'pending',
    this.pickupLat = 6.5898,
    this.pickupLng = 3.3556,
    this.dropoffLat = 6.4474,
    this.dropoffLng = 3.4739,
    this.driverId,
    this.driverName = 'Tunde Oyelaran',
    this.driverPlate = 'LAG-472-XA',
    this.driverVehicle = 'Toyota Corolla (White)',
    this.driverRating = 4.88,
    this.driverTrips = 1284,
    this.driverPhone = '+2348024419922',
  });

  bool get isCourier => service == 'courier';
  bool get isScheduled => scheduledAt != null && scheduledAt!.isNotEmpty;

  RideModel copyWith({
    String? id,
    String? status,
    String? scheduledAt,
    String? payment,
    String? driverId,
    String? driverName,
    String? driverPlate,
    String? driverVehicle,
    double? driverRating,
    String? driverPhone,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
  }) {
    return RideModel(
      id: id ?? this.id,
      code: code,
      pickup: pickup,
      dropoff: dropoff,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      packageType: packageType,
      weight: weight,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      itemLabel: itemLabel,
      payment: payment ?? this.payment,
      price: price,
      distanceKm: distanceKm,
      pin: pin,
      createdAt: createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      service: service,
      speed: speed,
      status: status ?? this.status,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPlate: driverPlate ?? this.driverPlate,
      driverVehicle: driverVehicle ?? this.driverVehicle,
      driverRating: driverRating ?? this.driverRating,
      driverTrips: driverTrips,
      driverPhone: driverPhone ?? this.driverPhone,
    );
  }

  static bool _isValidUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(str);
  }

  /// Generates a deterministic 4-digit PIN from the trip code so both rider
  /// and driver devices always match 100% across two-phone live testing.
  static String derivePinFromCode(String code) {
    if (code.isEmpty) return '1234';
    int hash = 0;
    for (int i = 0; i < code.length; i++) {
      hash = (hash * 31 + code.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final pinNum = 1000 + (hash % 9000);
    return pinNum.toString();
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'code': code,
      if (_isValidUuid(passengerId)) 'passenger_id': passengerId,
      'passenger_name': passengerName.isNotEmpty ? passengerName : 'Passenger',
      if (passengerPhone.isNotEmpty) 'passenger_phone': passengerPhone,
      if (_isValidUuid(driverId)) 'driver_id': driverId,
      if (driverName.isNotEmpty) 'driver_name': driverName,
      if (driverPlate.isNotEmpty) 'driver_plate': driverPlate,
      if (driverVehicle.isNotEmpty) 'driver_vehicle': driverVehicle,
      if (driverPhone.isNotEmpty) 'driver_phone': driverPhone,
      'driver_rating': driverRating,
      'service_type': vehicleId,
      'pickup_address': pickup,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoff,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'fare_amount': price,
      'distance_km': distanceKm,
      'payment_method': payment.toLowerCase(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory RideModel.fromSupabase(Map<String, dynamic> map) {
    final statusVal = map['status']?.toString() ?? 'pending';
    return RideModel(
      id: map['id']?.toString(),
      code: map['code']?.toString() ?? 'DG-000000',
      pickup: map['pickup_address']?.toString() ?? '',
      dropoff: map['dropoff_address']?.toString() ?? '',
      vehicleId: map['service_type']?.toString() ?? 'taxi',
      vehicleName: (map['service_type']?.toString() ?? 'taxi').toUpperCase(),
      payment: (map['payment_method']?.toString() ?? 'wallet').toUpperCase(),
      price: (map['fare_amount'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distance_km'] as num?)?.toInt() ?? 5,
      pin: derivePinFromCode(map['code']?.toString() ?? ''),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      status: statusVal,
      pickupLat: (map['pickup_lat'] as num?)?.toDouble() ?? 6.5898,
      pickupLng: (map['pickup_lng'] as num?)?.toDouble() ?? 3.3556,
      dropoffLat: (map['dropoff_lat'] as num?)?.toDouble() ?? 6.4474,
      dropoffLng: (map['dropoff_lng'] as num?)?.toDouble() ?? 3.4739,
      passengerId: map['passenger_id']?.toString() ?? '',
      passengerName: map['passenger_name']?.toString() ?? 'Passenger',
      passengerPhone: map['passenger_phone']?.toString() ?? '',
      driverId: map['driver_id']?.toString(),
      driverName: map['driver_name']?.toString() ?? '',
      driverPlate: map['driver_plate']?.toString() ?? '',
      driverVehicle: map['driver_vehicle']?.toString() ?? '',
      driverRating: (map['driver_rating'] as num?)?.toDouble() ?? 4.90,
      driverPhone: map['driver_phone']?.toString() ?? '',
    );
  }
}
