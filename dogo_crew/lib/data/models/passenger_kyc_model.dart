import 'dart:typed_data';

class PassengerKycModel {
  final String userId;
  final String status; // 'unverified', 'pending', 'verified', 'rejected'
  final String providerName; // 'Smile ID', 'Dojah'
  final double confidenceScore;
  final bool livenessVerified;
  final String? referenceId;
  final String? rejectReason;
  final DateTime? verifiedAt;
  final Uint8List? selfieBytes;

  const PassengerKycModel({
    required this.userId,
    this.status = 'unverified',
    this.providerName = 'Smile ID',
    this.confidenceScore = 0.0,
    this.livenessVerified = false,
    this.referenceId,
    this.rejectReason,
    this.verifiedAt,
    this.selfieBytes,
  });

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isUnverified => status == 'unverified';

  String get formattedScore => '${(confidenceScore * 100).toStringAsFixed(1)}%';

  PassengerKycModel copyWith({
    String? userId,
    String? status,
    String? providerName,
    double? confidenceScore,
    bool? livenessVerified,
    String? referenceId,
    String? rejectReason,
    DateTime? verifiedAt,
    Uint8List? selfieBytes,
  }) {
    return PassengerKycModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      providerName: providerName ?? this.providerName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      livenessVerified: livenessVerified ?? this.livenessVerified,
      referenceId: referenceId ?? this.referenceId,
      rejectReason: rejectReason ?? this.rejectReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      selfieBytes: selfieBytes ?? this.selfieBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'provider_name': providerName,
      'confidence_score': confidenceScore,
      'liveness_verified': livenessVerified,
      'reference_id': referenceId,
      'reject_reason': rejectReason,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  factory PassengerKycModel.fromJson(Map<String, dynamic> json) {
    return PassengerKycModel(
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unverified',
      providerName: json['provider_name'] as String? ?? 'Smile ID',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      livenessVerified: json['liveness_verified'] as bool? ?? false,
      referenceId: json['reference_id'] as String?,
      rejectReason: json['reject_reason'] as String?,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
    );
  }
}
