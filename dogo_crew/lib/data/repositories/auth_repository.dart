import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? role,
  }) async {
    final userData = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone.trim(),
    };
    if (role != null) {
      userData['role'] = role;
    }

    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: userData,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final profileData = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      final rolesData = await _client.from('user_roles').select('role').eq('user_id', userId);

      final roles = rolesData
          .map((r) => r['role']?.toString() ?? '')
          .where((r) => r.isNotEmpty)
          .toList();

      if (profileData != null) {
        return ProfileModel.fromJson(profileData, roles: roles);
      } else {
        // In case profile row wasn't populated yet
        return ProfileModel(
          id: userId,
          fullName: _client.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'Crew Member',
          phone: _client.auth.currentUser?.userMetadata?['phone'] as String?,
          createdAt: DateTime.now(),
          roles: roles,
        );
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? vehicle,
    String? plate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'id': userId,
        'full_name': fullName.trim(),
      };
      if (phone != null) updateData['phone'] = phone.trim();
      if (vehicle != null) updateData['vehicle'] = vehicle.trim();
      if (plate != null) updateData['plate'] = plate.trim();
      await _client.from('profiles').upsert(updateData);
    } catch (_) {}
  }
}

