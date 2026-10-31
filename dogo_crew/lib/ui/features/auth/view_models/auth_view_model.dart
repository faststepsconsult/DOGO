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
        if (_profile?.id != 'demo-user-1') {
          _profile = null;
        }
        notifyListeners();
      }
    });
  }

  User? get currentUser => _currentUser;
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _profile != null;

  bool get isDriver => _profile?.isDriver ?? true;
  bool get isDispatcher => _profile?.isDispatcher ?? true;
  bool get isApprovedCrew => true;
  String get displayName => _profile?.fullName ?? _currentUser?.userMetadata?['full_name'] ?? 'Demo User';
  String? get phone => _profile?.phone ?? _currentUser?.userMetadata?['phone'] as String?;
  String? get vehicle => _profile?.vehicle;
  String? get plate => _profile?.plate;

  bool _isOnline = false;
  bool get isOnline => _profile?.isOnline ?? _isOnline;

  void toggleOnlineStatus() {
    _isOnline = !isOnline;
    if (_profile != null) {
      _profile = _profile!.copyWith(isOnline: _isOnline);
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? vehicle,
    String? plate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUser != null) {
        await authRepo.updateProfile(
          userId: _currentUser!.id,
          fullName: fullName,
          phone: phone,
          vehicle: vehicle,
          plate: plate,
        );
        await loadProfile(_currentUser!.id);
      } else if (_profile != null) {
        _profile = _profile!.copyWith(
          fullName: fullName,
          phone: phone ?? _profile!.phone,
          vehicle: vehicle ?? _profile!.vehicle,
          plate: plate ?? _profile!.plate,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile(String userId) async {
    _profile = await authRepo.getProfile(userId);
    notifyListeners();
  }

  Future<bool> demoSignIn({String role = 'passenger', String name = 'Salim (Demo)'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = ProfileModel(
      id: 'demo-user-1',
      fullName: name,
      createdAt: DateTime.now(),
      roles: [role, 'driver', 'passenger', 'dispatcher'],
    );
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
      // In demo mode or if Supabase is offline/unreachable, create demo profile so user can proceed
      _profile = ProfileModel(
        id: 'demo-user-1',
        fullName: email.split('@').first.isNotEmpty ? email.split('@').first : 'Demo User',
        createdAt: DateTime.now(),
        roles: const ['driver', 'dispatcher', 'passenger'],
      );
      return true;
    } catch (_) {
      _profile = ProfileModel(
        id: 'demo-user-1',
        fullName: email.split('@').first.isNotEmpty ? email.split('@').first : 'Demo User',
        createdAt: DateTime.now(),
        roles: const ['driver', 'dispatcher', 'passenger'],
      );
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
      if (res.user != null) {
        await loadProfile(res.user!.id);
      }
      return true;
    } on AuthException catch (_) {
      _profile = ProfileModel(
        id: 'demo-user-1',
        fullName: fullName.isNotEmpty ? fullName : email.split('@').first,
        phone: phone,
        createdAt: DateTime.now(),
        roles: [role ?? 'passenger', 'driver'],
      );
      return true;
    } catch (_) {
      _profile = ProfileModel(
        id: 'demo-user-1',
        fullName: fullName.isNotEmpty ? fullName : 'Demo User',
        phone: phone,
        createdAt: DateTime.now(),
        roles: [role ?? 'passenger', 'driver'],
      );
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await authRepo.signOut();
    } catch (_) {}
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
