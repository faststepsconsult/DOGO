import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepo;

  User? _currentUser;
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSub;

  AuthViewModel({required this.authRepo}) {
    _initLocalProfile();

    _currentUser = authRepo.currentUser;
    if (_currentUser != null) {
      loadProfile(_currentUser!.id);
    }

    _authSub = authRepo.authStateChanges.listen((event) {
      final user = event.session?.user;
      _currentUser = user;
      if (user != null) {
        loadProfile(user.id);
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> _initLocalProfile() async {
    final local = await authRepo.loadLocalProfile();
    if (local != null) {
      _profile = local;
    } else {
      // Default to the first testing preset (Passenger) if unconfigured
      _profile = AuthRepository.testingPresets[0];
      await authRepo.saveLocalProfile(_profile!);
    }
    notifyListeners();
  }

  User? get currentUser => _currentUser;
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _profile != null || _currentUser != null;

  bool get isDriver => _profile?.isDriver ?? false;
  bool get isDispatcher => _profile?.isDispatcher ?? false;
  bool get isApprovedCrew => _profile?.isApprovedCrew ?? false;
  bool get isClearedDriver => _profile?.isClearedDriver ?? false;
  bool get isPendingClearance => _profile?.isPendingClearance ?? false;

  String get displayName => _profile?.fullName.isNotEmpty == true
      ? _profile!.fullName
      : (_currentUser?.userMetadata?['full_name'] as String? ?? 'Salim Abdulaziz');

  String? get phone => _profile?.phone ?? _currentUser?.userMetadata?['phone'] as String?;
  String? get email => _profile?.email ?? _currentUser?.email;
  String? get vehicle => _profile?.vehicle;
  String? get plate => _profile?.plate;
  String get driverClearanceStatus => _profile?.driverClearanceStatus ?? 'not_applied';
  String? get driverVehicleType => _profile?.driverVehicleType;
  String? get driverLicenseNumber => _profile?.driverLicenseNumber;

  bool _isOnline = false;
  bool get isOnline => _profile?.isOnline ?? _isOnline;

  void toggleOnlineStatus() {
    _isOnline = !isOnline;
    if (_profile != null) {
      _profile = _profile!.copyWith(isOnline: _isOnline);
      authRepo.saveLocalProfile(_profile!);
    }
    notifyListeners();
  }

  /// Instant identity switcher for multi-device live testing
  Future<void> switchProfilePreset(ProfileModel preset) async {
    _profile = preset;
    await authRepo.saveLocalProfile(preset);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? email,
    String? vehicle,
    String? plate,
    String? driverVehicleType,
    String? driverLicenseNumber,
    String? driverGuarantorPhone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = (_profile ?? AuthRepository.testingPresets[0]).copyWith(
        fullName: fullName.trim(),
        phone: phone?.trim(),
        email: email?.trim(),
        vehicle: vehicle?.trim(),
        plate: plate?.trim(),
        driverVehicleType: driverVehicleType,
        driverLicenseNumber: driverLicenseNumber?.trim(),
        driverGuarantorPhone: driverGuarantorPhone?.trim(),
      );

      _profile = updated;
      await authRepo.saveLocalProfile(updated);

      if (_currentUser != null) {
        await authRepo.updateProfile(
          userId: _currentUser!.id,
          fullName: fullName,
          phone: phone,
          vehicle: vehicle,
          plate: plate,
          driverClearanceStatus: updated.driverClearanceStatus,
          driverVehicleType: driverVehicleType,
          driverLicenseNumber: driverLicenseNumber,
          driverGuarantorPhone: driverGuarantorPhone,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits Driver Clearance application (Aligned with Danny26y/DOGO-APP specification)
  Future<void> submitDriverClearance({
    required String vehicleType,
    required String vehicleModel,
    required String plateNumber,
    required String licenseNumber,
    String? guarantorPhone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedRoles = List<String>.from(_profile?.roles ?? ['passenger']);
      if (!updatedRoles.contains('driver')) updatedRoles.add('driver');

      final updated = (_profile ?? AuthRepository.testingPresets[0]).copyWith(
        vehicle: vehicleModel.trim(),
        plate: plateNumber.trim().toUpperCase(),
        driverVehicleType: vehicleType,
        driverLicenseNumber: licenseNumber.trim(),
        driverGuarantorPhone: guarantorPhone?.trim(),
        driverClearanceStatus: 'pending', // Starts in pending review
        roles: updatedRoles,
      );

      _profile = updated;
      await authRepo.saveLocalProfile(updated);

      if (_currentUser != null) {
        await authRepo.updateProfile(
          userId: _currentUser!.id,
          fullName: updated.fullName,
          phone: updated.phone,
          vehicle: vehicleModel,
          plate: plateNumber,
          driverClearanceStatus: 'pending',
          driverVehicleType: vehicleType,
          driverLicenseNumber: licenseNumber,
          driverGuarantorPhone: guarantorPhone,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fast-tracks / approves driver clearance (for testing & admin clearance approval)
  Future<void> approveDriverClearance() async {
    if (_profile == null) return;
    final updatedRoles = List<String>.from(_profile!.roles);
    if (!updatedRoles.contains('driver')) updatedRoles.add('driver');

    final updated = _profile!.copyWith(
      driverClearanceStatus: 'active',
      roles: updatedRoles,
    );

    _profile = updated;
    await authRepo.saveLocalProfile(updated);
    notifyListeners();
  }

  Future<void> loadProfile(String userId) async {
    final remote = await authRepo.getProfile(userId);
    if (remote != null) {
      _profile = remote;
      notifyListeners();
    }
  }

  Future<bool> demoSignIn({String role = 'passenger', String name = 'Salim (Demo)'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final preset = role == 'driver'
        ? AuthRepository.testingPresets[1] // Ibrahim Musa (Driver)
        : AuthRepository.testingPresets[0]; // Salim Abdulaziz (Passenger)

    _profile = preset.copyWith(fullName: name);
    await authRepo.saveLocalProfile(_profile!);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await authRepo.signIn(email: email, password: password).timeout(
        const Duration(seconds: 4),
      );
      _currentUser = res.user;
      if (res.user != null) {
        await loadProfile(res.user!.id);
      }
      return true;
    } on AuthException catch (_) {
      // Handle offline or fallback
      final name = email.split('@').first;
      _profile = ProfileModel(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        fullName: name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : 'DOGO Member',
        email: email,
        phone: '+234 800 000 0000',
        createdAt: DateTime.now(),
        roles: const ['passenger'],
        driverClearanceStatus: 'not_applied',
      );
      await authRepo.saveLocalProfile(_profile!);
      return true;
    } catch (_) {
      final name = email.split('@').first;
      _profile = ProfileModel(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        fullName: name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : 'DOGO Member',
        email: email,
        phone: '+234 800 000 0000',
        createdAt: DateTime.now(),
        roles: const ['passenger'],
        driverClearanceStatus: 'not_applied',
      );
      await authRepo.saveLocalProfile(_profile!);
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await authRepo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      _currentUser = res.user;
      final newProf = ProfileModel(
        id: res.user?.id ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
        roles: [role ?? 'passenger'],
        driverClearanceStatus: role == 'driver' ? 'pending' : 'not_applied',
      );
      _profile = newProf;
      await authRepo.saveLocalProfile(newProf);
      return true;
    } catch (_) {
      final newProf = ProfileModel(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
        roles: [role ?? 'passenger'],
        driverClearanceStatus: role == 'driver' ? 'pending' : 'not_applied',
      );
      _profile = newProf;
      await authRepo.saveLocalProfile(newProf);
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authRepo.signOut();
    _currentUser = null;
    _profile = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
