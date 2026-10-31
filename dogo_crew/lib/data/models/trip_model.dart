class TripModel {
  final String id;
  final String code;
  final String service; // 'taxi' | 'keke' | 'bike'
  final String status; // 'pending' | 'accepted' | 'en_route' | 'picked_up' | 'completed' | 'cancelled'
  final String customerName;
  final String customerPhone;
  final String pickup;
  final String dropoff;
  final double distanceKm;
  final double? distanceCoveredKm;
  final int fare;
  final String paymentStatus; // 'unpaid' | 'paid' | 'refunded'
  final String? goodsPhotoUrl;
  final String? notes;
  final String? assignedTo;
  final DateTime? movedAt;
  final DateTime? paidAt;
  final int? refundAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.code,
    required this.service,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    this.distanceCoveredKm,
    required this.fare,
    required this.paymentStatus,
    this.goodsPhotoUrl,
    this.notes,
    this.assignedTo,
    this.movedAt,
    this.paidAt,
    this.refundAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      service: json['service'] as String? ?? 'taxi',
      status: json['status'] as String? ?? 'pending',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      pickup: json['pickup'] as String? ?? '',
      dropoff: json['dropoff'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      distanceCoveredKm: (json['distance_covered_km'] as num?)?.toDouble(),
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      goodsPhotoUrl: json['goods_photo_url'] as String?,
      notes: json['notes'] as String?,
      assignedTo: json['assigned_to'] as String?,
      movedAt: json['moved_at'] != null ? DateTime.tryParse(json['moved_at'] as String) : null,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
      refundAmount: (json['refund_amount'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'service': service,
      'status': status,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup': pickup,
      'dropoff': dropoff,
      'distance_km': distanceKm,
      'distance_covered_km': distanceCoveredKm,
      'fare': fare,
      'payment_status': paymentStatus,
      'goods_photo_url': goodsPhotoUrl,
      'notes': notes,
      'assigned_to': assignedTo,
      'moved_at': movedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'refund_amount': refundAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get driverShare => (fare * 0.7).floor();
  int get dogoShare => fare - driverShare;
}
