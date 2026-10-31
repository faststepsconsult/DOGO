import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/passenger_kyc_model.dart';
import '../../../../data/services/facial_kyc_service.dart';

enum KycUiStage {
  intro,
  preview,
  analyzing,
  success,
  failed,
}

class PassengerVerificationViewModel extends ChangeNotifier {
  final String userId;
  final String? userFullName;
  final FacialKycService _kycService = FacialKycService();

  PassengerKycModel _kycData = const PassengerKycModel(userId: '');
  KycProviderType _selectedProvider = KycProviderType.smileId;
  KycUiStage _stage = KycUiStage.intro;

  Uint8List? _selfieBytes;
  String? _selfieExt;
  double _progress = 0.0;
  String _stepMessage = '';
  String? _errorMessage;

  PassengerVerificationViewModel({
    required this.userId,
    this.userFullName,
  }) {
    _kycData = PassengerKycModel(userId: userId);
  }

  PassengerKycModel get kycData => _kycData;
  KycProviderType get selectedProvider => _selectedProvider;
  KycUiStage get stage => _stage;
  Uint8List? get selfieBytes => _selfieBytes;
  String? get selfieExt => _selfieExt;
  double get progress => _progress;
  String get stepMessage => _stepMessage;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _kycData.isVerified;

  void selectProvider(KycProviderType provider) {
    if (_selectedProvider == provider) return;
    _selectedProvider = provider;
    _kycService.setActiveProvider(provider);
    notifyListeners();
  }

  Future<void> pickSelfie({ImageSource source = ImageSource.camera}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        _selfieBytes = bytes;
        _selfieExt = file.name.split('.').last;
        _stage = KycUiStage.preview;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Could not access camera: $e';
      notifyListeners();
    }
  }

  void clearSelfie() {
    _selfieBytes = null;
    _selfieExt = null;
    _stage = KycUiStage.intro;
    _progress = 0.0;
    _stepMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> runVerification() async {
    if (_selfieBytes == null) {
      _errorMessage = 'Please capture a clear selfie photo first.';
      notifyListeners();
      return false;
    }

    _stage = KycUiStage.analyzing;
    _progress = 0.05;
    _stepMessage = 'Initializing ${_selectedProvider.displayName} scan...';
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _kycService.verifySelfie(
        imageBytes: _selfieBytes!,
        userId: userId,
        fullName: userFullName,
        specificProvider: _selectedProvider,
        onProgress: (message, p) {
          _stepMessage = message;
          _progress = p;
          notifyListeners();
        },
      );

      if (result.isSuccess) {
        _kycData = _kycData.copyWith(
          status: 'verified',
          providerName: _selectedProvider.displayName,
          confidenceScore: result.confidenceScore,
          livenessVerified: result.livenessDetected,
          referenceId: result.referenceId,
          verifiedAt: result.timestamp,
          selfieBytes: _selfieBytes,
        );
        _stage = KycUiStage.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message;
        _stage = KycUiStage.failed;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Verification encountered an error: $e';
      _stage = KycUiStage.failed;
      notifyListeners();
      return false;
    }
  }

  void resetForReverify() {
    _selfieBytes = null;
    _selfieExt = null;
    _kycData = PassengerKycModel(userId: userId);
    _stage = KycUiStage.intro;
    _progress = 0.0;
    _stepMessage = '';
    _errorMessage = null;
    notifyListeners();
  }
}
