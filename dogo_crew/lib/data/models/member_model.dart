class MemberModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? vehicle;
  final List<String> roles;
  final DateTime createdAt;

  MemberModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.vehicle,
    required this.roles,
    required this.createdAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      vehicle: json['vehicle'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  bool get isDriver => roles.contains('driver');
  bool get isDispatcher => roles.contains('dispatcher');
  bool get isPendingApproval => !isDriver && !isDispatcher;
}
