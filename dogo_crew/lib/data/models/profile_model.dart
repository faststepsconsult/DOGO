class ProfileModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? vehicle;
  final String? plate;
  final bool isOnline;
  final DateTime createdAt;
  final List<String> roles;

  ProfileModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.vehicle,
    this.plate,
    this.isOnline = false,
    required this.createdAt,
    this.roles = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json, {List<String> roles = const []}) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      vehicle: json['vehicle'] as String?,
      plate: json['plate'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      roles: roles,
    );
  }

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? vehicle,
    String? plate,
    bool? isOnline,
    DateTime? createdAt,
    List<String>? roles,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      plate: plate ?? this.plate,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      roles: roles ?? this.roles,
    );
  }

  bool get isDriver => roles.contains('driver') || roles.contains('rider');
  bool get isDispatcher => roles.contains('dispatcher');
  bool get isAdmin => roles.contains('admin');
  bool get isApprovedCrew => true; // Approval gate removed to allow progress
}

