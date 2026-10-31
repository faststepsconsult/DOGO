import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/verification_model.dart';
import '../services/supabase_service.dart';

class VerificationRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<RiderVerificationModel?> getMyRiderVerification(String userId) async {
    final res = await _client
        .from('rider_verifications')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return RiderVerificationModel.fromJson(res);
  }

  Future<List<VehicleModel>> getMyVehicles(String userId) async {
    final res = await _client
        .from('vehicles')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (res as List<dynamic>).map((e) => VehicleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RiderVerificationModel>> getAllRiderVerifications() async {
    final res = await _client
        .from('rider_verifications')
        .select()
        .order('created_at', ascending: false);
    return (res as List<dynamic>).map((e) => RiderVerificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<VehicleModel>> getAllVehicles() async {
    final res = await _client
        .from('vehicles')
        .select()
        .order('created_at', ascending: false);
    return (res as List<dynamic>).map((e) => VehicleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> uploadDoc({
    required String userId,
    required String kind,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '$userId/$kind-${DateTime.now().millisecondsSinceEpoch}.$extension';
    return await SupabaseService.uploadFile(
      bucket: 'verification-docs',
      path: path,
      fileBytes: bytes,
    );
  }

  Future<String?> getDocSignedUrl(String path) async {
    return await SupabaseService.getSignedUrl(
      bucket: 'verification-docs',
      path: path,
    );
  }

  Future<void> submitRiderVerification({
    required String userId,
    required String licenseNumber,
    String? nin,
    String? licensePhotoPath,
  }) async {
    await _client.from('rider_verifications').insert({
      'user_id': userId,
      'license_number': licenseNumber.trim(),
      'nin': nin?.trim().isNotEmpty == true ? nin!.trim() : null,
      'license_photo': licensePhotoPath,
      'status': 'pending',
    });
  }

  Future<void> submitVehicle({
    required String ownerId,
    required String service,
    required String model,
    required String plate,
    String? color,
    String? photoPath,
  }) async {
    await _client.from('vehicles').insert({
      'owner_id': ownerId,
      'service': service,
      'model': model.trim(),
      'plate': plate.trim().toUpperCase(),
      'color': color?.trim().isNotEmpty == true ? color!.trim() : null,
      'photo': photoPath,
      'status': 'pending',
    });
  }

  Future<void> reviewRiderVerification({
    required String id,
    required String status, // 'approved' | 'rejected'
    String? reason,
  }) async {
    await _client.from('rider_verifications').update({
      'status': status,
      'reject_reason': reason,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> reviewVehicle({
    required String id,
    required String status, // 'approved' | 'rejected'
    String? reason,
  }) async {
    await _client.from('vehicles').update({
      'status': status,
      'reject_reason': reason,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
