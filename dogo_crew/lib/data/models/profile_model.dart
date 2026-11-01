import 'dart:convert';

class ProfileModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? vehicle;
  final String? plate;
  final bool isOnline;
  final DateTime createdAt;
  final List<String> roles;
  final String driverClearanceStatus; // 'not_applied', 'pending', 'active', 'rejected'
  final String? driverVehicleType; // 'taxi', 'keke', 'bike'
  final String? driverLicenseNumber;
  final String? driverGuarantorPhone;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.vehicle,
    this.plate,
    this.isOnline = false,
    required this.createdAt,
    this.roles = const [],
    this.driverClearanceStatus = 'not_applied',
    this.driverVehicleType,
    this.driverLicenseNumber,
    this.driverGuarantorPhone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json, {List<String> roles = const []}) {
    final parsedRoles = json['roles'] is List
        ? (json['roles'] as List).map((e) => e.toString()).toList()
        : roles;

    return ProfileModel(
      id: json['id'] as String? ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      vehicle: json['vehicle'] as String?,
      plate: json['plate'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      roles: parsedRoles,
      driverClearanceStatus: json['driver_clearance_status'] as String? ?? 'not_applied',
      driverVehicleType: json['driver_vehicle_type'] as String?,
      driverLicenseNumber: json['driver_license_number'] as String?,
      driverGuarantorPhone: json['driver_guarantor_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'vehicle': vehicle,
      'plate': plate,
      'is_online': isOnline,
      'created_at': createdAt.toIso8601String(),
      'roles': roles,
      'driver_clearance_status': driverClearanceStatus,
      'driver_vehicle_type': driverVehicleType,
      'driver_license_number': driverLicenseNumber,
      'driver_guarantor_phone': driverGuarantorPhone,
    };
  }

  String toRawJson() => json.encode(toJson());
  factory ProfileModel.fromRawJson(String str) => ProfileModel.fromJson(json.decode(str) as Map<String, dynamic>);

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? vehicle,
    String? plate,
    bool? isOnline,
    DateTime? createdAt,
    List<String>? roles,
    String? driverClearanceStatus,
    String? driverVehicleType,
    String? driverLicenseNumber,
    String? driverGuarantorPhone,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      plate: plate ?? this.plate,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      roles: roles ?? this.roles,
      driverClearanceStatus: driverClearanceStatus ?? this.driverClearanceStatus,
      driverVehicleType: driverVehicleType ?? this.driverVehicleType,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      driverGuarantorPhone: driverGuarantorPhone ?? this.driverGuarantorPhone,
    );
  }

  bool get isDriver => roles.contains('driver') || roles.contains('rider') || driverClearanceStatus == 'active';
  bool get isDispatcher => roles.contains('dispatcher');
  bool get isAdmin => roles.contains('admin');
  bool get isApprovedCrew => driverClearanceStatus == 'active' || isDriver;
  bool get isClearedDriver => driverClearanceStatus == 'active';
  bool get isPendingClearance => driverClearanceStatus == 'pending';
}
