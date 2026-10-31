class TripMessageModel {
  final String id;
  final String tripId;
  final String body;
  final String? senderId;
  final String senderKind; // 'customer' | 'staff' | 'customer_log'
  final DateTime createdAt;

  TripMessageModel({
    required this.id,
    required this.tripId,
    required this.body,
    this.senderId,
    required this.senderKind,
    required this.createdAt,
  });

  factory TripMessageModel.fromJson(Map<String, dynamic> json) {
    return TripMessageModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      body: json['body'] as String? ?? '',
      senderId: json['sender_id'] as String?,
      senderKind: json['sender_kind'] as String? ?? 'staff',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'body': body,
      'sender_id': senderId,
      'sender_kind': senderKind,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCustomer => senderKind == 'customer';
  bool get isStaff => senderKind == 'staff';
  bool get isSystem => senderKind == 'customer_log';
}
