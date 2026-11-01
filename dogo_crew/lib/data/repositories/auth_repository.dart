import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const String _prefKeyProfile = 'dogo_persisted_profile';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  // Pre-configured role profiles for instant multiplayer device testing
  static final List<ProfileModel> testingPresets = [
    ProfileModel(
      id: 'salim-passenger-01',
      fullName: 'Salim Abdulaziz',
      email: 'salim@dogo.app',
      phone: '+234 803 123 4567',
      roles: const ['passenger'],
      driverClearanceStatus: 'not_applied',
      createdAt: DateTime(2026, 10, 1),
    ),
    ProfileModel(
      id: 'driver-ibrahim-01',
      fullName: 'Ibrahim Musa',
      email: 'ibrahim.driver@dogo.app',
      phone: '+234 802 441 9922',
      vehicle: 'Toyota Corolla 2018 (Silver)',
      plate: 'LAG-605-EK',
      driverVehicleType: 'taxi',
      roles: const ['driver', 'passenger'],
      driverClearanceStatus: 'active',
      driverLicenseNumber: 'DL-90821-LG',
      createdAt: DateTime(2026, 9, 15),
    ),
    ProfileModel(
      id: 'driver-emeka-02',
      fullName: 'Emeka Obi',
      email: 'emeka.keke@dogo.app',
      phone: '+234 809 333 4455',
      vehicle: 'TVS King Deluxe (Yellow)',
      plate: 'KJA-719-XB',
      driverVehicleType: 'keke',
      roles: const ['driver', 'passenger'],
      driverClearanceStatus: 'active',
      driverLicenseNumber: 'DL-44119-KD',
      createdAt: DateTime(2026, 9, 20),
    ),
    ProfileModel(
      id: 'driver-babatunde-03',
      fullName: 'Babatunde Lawal',
      email: 'babatunde.courier@dogo.app',
      phone: '+234 812 777 8899',
      vehicle: 'Bajaj Boxer BM150 (Red)',
      plate: 'BDG-204-AQ',
      driverVehicleType: 'bike',
      roles: const ['driver', 'rider', 'passenger'],
      driverClearanceStatus: 'active',
      driverLicenseNumber: 'DL-18492-IK',
      createdAt: DateTime(2026, 10, 5),
    ),
  ];

  /// Loads profile persisted on this physical device
  Future<ProfileModel?> loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyProfile);
      if (raw != null && raw.isNotEmpty) {
        return ProfileModel.fromRawJson(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Persists profile to this physical device
  Future<void> saveLocalProfile(ProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyProfile, profile.toRawJson());
    } catch (_) {}
  }

  /// Clears profile from this physical device
  Future<void> clearLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyProfile);
    } catch (_) {}
  }

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
    try {
      await _client.auth.signOut();
    } catch (_) {}
    await clearLocalProfile();
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
        final profile = ProfileModel.fromJson(profileData, roles: roles);
        await saveLocalProfile(profile);
        return profile;
      }
    } catch (_) {}

    // Fall back to local device storage if offline or table not migrated
    return await loadLocalProfile();
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? vehicle,
    String? plate,
    String? driverClearanceStatus,
    String? driverVehicleType,
    String? driverLicenseNumber,
    String? driverGuarantorPhone,
  }) async {
    // 1. Try updating remote Supabase profiles if available
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

    // 2. Persist locally to this device
    final current = await loadLocalProfile();
    final updated = (current ?? ProfileModel(
      id: userId,
      fullName: fullName,
      createdAt: DateTime.now(),
    )).copyWith(
      fullName: fullName,
      phone: phone,
      vehicle: vehicle,
      plate: plate,
      driverClearanceStatus: driverClearanceStatus,
      driverVehicleType: driverVehicleType,
      driverLicenseNumber: driverLicenseNumber,
      driverGuarantorPhone: driverGuarantorPhone,
    );
    await saveLocalProfile(updated);
  }
}
