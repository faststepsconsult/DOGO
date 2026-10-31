class RiderVerificationModel {
  final String id;
  final String userId;
  final String licenseNumber;
  final String? nin;
  final String? licensePhoto;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  RiderVerificationModel({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    this.nin,
    this.licensePhoto,
    required this.status,
    this.rejectReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory RiderVerificationModel.fromJson(Map<String, dynamic> json) {
    return RiderVerificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      licenseNumber: json['license_number'] as String? ?? '',
      nin: json['nin'] as String?,
      licensePhoto: json['license_photo'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectReason: json['reject_reason'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class VehicleModel {
  final String id;
  final String ownerId;
  final String service; // 'taxi' | 'keke' | 'bike'
  final String model;
  final String plate;
  final String? color;
  final String? photo;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.ownerId,
    required this.service,
    required this.model,
    required this.plate,
    this.color,
    this.photo,
    required this.status,
    this.rejectReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      service: json['service'] as String? ?? 'taxi',
      model: json['model'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      color: json['color'] as String?,
      photo: json['photo'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectReason: json['reject_reason'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
