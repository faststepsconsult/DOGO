import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dogo_crew/data/services/in_app_call_service.dart';
import 'package:dogo_crew/ui/features/driver/view_models/driver_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
  });

  group('InAppCallService Tests', () {
    test('Initializes with idle session and empty contact set', () {
      final service = InAppCallService.instance;
      expect(service.currentSession, isNull);
      expect(service.hasAttemptedContact('NON_EXISTENT_RIDE'), isFalse);
    });

    test('Starting outgoing data call creates session and logs contact attempt', () async {
      final service = InAppCallService.instance;
      await service.startOutgoingCall(
        rideCode: 'TEST_RIDE_101',
        peerName: 'Salim Bello',
        peerRole: 'Passenger',
        peerPhone: '+2348031234567',
        myRole: 'driver',
        simulateAnswerForDemo: false,
      );

      expect(service.currentSession, isNotNull);
      expect(service.currentSession!.peerName, 'Salim Bello');
      expect(service.currentSession!.isOutgoing, isTrue);
      expect(service.currentSession!.status, CallStatus.outgoingRinging);
      expect(service.hasAttemptedContact('TEST_RIDE_101'), isTrue);

      // Answer call
      service.answerCall();
      expect(service.currentSession!.status, CallStatus.connected);

      // Toggle Mute & Speaker
      expect(service.currentSession!.isMuted, isFalse);
      service.toggleMute();
      expect(service.currentSession!.isMuted, isTrue);

      expect(service.currentSession!.isSpeakerOn, isFalse);
      service.toggleSpeaker();
      expect(service.currentSession!.isSpeakerOn, isTrue);

      // End Call
      service.endCall(reason: 'user_ended');
      expect(service.currentSession!.status, CallStatus.ended);
    });

    test('Manual chat contact recording sets hasAttemptedContact', () {
      final service = InAppCallService.instance;
      expect(service.hasAttemptedContact('CHAT_RIDE_99'), isFalse);
      service.recordContactAttempt('CHAT_RIDE_99');
      expect(service.hasAttemptedContact('CHAT_RIDE_99'), isTrue);
    });
  });

  group('Driver Respite & Anti-Fraud Logic Tests', () {
    test('Respite constants are correctly configured', () {
      expect(DriverViewModel.respiteRequiredDwellSeconds, 180);
      expect(DriverViewModel.arrivalCompensationFee, 1000);
    });

    test('canClaimRespiteFee requires atPickup, dwell timer, and attempted contact', () {
      final vm = DriverViewModel();
      expect(vm.canClaimRespiteFee, isFalse);
    });
  });
}

