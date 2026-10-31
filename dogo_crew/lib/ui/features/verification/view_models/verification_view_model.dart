import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../data/models/verification_model.dart';
import '../../../../data/repositories/verification_repository.dart';

class VerificationViewModel extends ChangeNotifier {
  final VerificationRepository verifRepo;
  final String userId;
  final bool isDispatcher;

  RiderVerificationModel? _myRider;
  List<VehicleModel> _myVehicles = [];
  List<RiderVerificationModel> _allRiders = [];
  List<VehicleModel> _allVehicles = [];

  bool _isLoading = true;
  String? _errorMessage;

  VerificationViewModel({
    required this.verifRepo,
    required this.userId,
    required this.isDispatcher,
  }) {
    loadData();
  }

  RiderVerificationModel? get myRider => _myRider;
  List<VehicleModel> get myVehicles => _myVehicles;
  List<RiderVerificationModel> get allRiders => _allRiders;
  List<VehicleModel> get allVehicles => _allVehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isDispatcher) {
        _allRiders = await verifRepo.getAllRiderVerifications();
        _allVehicles = await verifRepo.getAllVehicles();
      }

      _myRider = await verifRepo.getMyRiderVerification(userId);
      _myVehicles = await verifRepo.getMyVehicles(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load verification status.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRider({
    required String licenseNumber,
    String? nin,
    Uint8List? photoBytes,
    String? photoExt,
  }) async {
    try {
      String? photoPath;
      if (photoBytes != null && photoExt != null) {
        photoPath = await verifRepo.uploadDoc(
          userId: userId,
          kind: 'license',
          bytes: photoBytes,
          extension: photoExt,
        );
      }

      await verifRepo.submitRiderVerification(
        userId: userId,
        licenseNumber: licenseNumber,
        nin: nin,
        licensePhotoPath: photoPath,
      );
      await loadData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitVehicle({
    required String service,
    required String model,
    required String plate,
    String? color,
    Uint8List? photoBytes,
    String? photoExt,
  }) async {
    try {
      String? photoPath;
      if (photoBytes != null && photoExt != null) {
        photoPath = await verifRepo.uploadDoc(
          userId: userId,
          kind: 'vehicle',
          bytes: photoBytes,
          extension: photoExt,
        );
      }

      await verifRepo.submitVehicle(
        ownerId: userId,
        service: service,
        model: model,
        plate: plate,
        color: color,
        photoPath: photoPath,
      );
      await loadData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reviewRider(String id, String status, [String? reason]) async {
    await verifRepo.reviewRiderVerification(id: id, status: status, reason: reason);
    await loadData();
  }

  Future<void> reviewVehicle(String id, String status, [String? reason]) async {
    await verifRepo.reviewVehicle(id: id, status: status, reason: reason);
    await loadData();
  }
}
