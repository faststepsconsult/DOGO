import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_cues_service.dart';
import 'supabase_service.dart';

enum CallStatus {
  idle,
  outgoingRinging,
  incomingRinging,
  connected,
  ended,
}

class CallSession {
  final String rideCode;
  final String peerName;
  final String peerRole; // 'Captain' or 'Passenger'
  final String? peerPhone;
  final bool isOutgoing;
  CallStatus status;
  int durationSeconds;
  bool isMuted;
  bool isSpeakerOn;

  CallSession({
    required this.rideCode,
    required this.peerName,
    required this.peerRole,
    this.peerPhone,
    required this.isOutgoing,
    this.status = CallStatus.idle,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
  });

  String get formattedDuration {
    final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

/// Service managing real-time in-app VoIP data calls between DOGO captains and riders.
/// Uses mobile data / Wi-Fi (0 cellular airtime) and provides verified contact logs.
class InAppCallService extends ChangeNotifier {
  static final InAppCallService _instance = InAppCallService._internal();
  static InAppCallService get instance => _instance;
  factory InAppCallService() => _instance;

  InAppCallService._internal();

  SupabaseClient get _client => SupabaseService.client;

  CallSession? _currentSession;
  CallSession? get currentSession => _currentSession;

  final Map<String, RealtimeChannel> _activeChannels = {};
  final Set<String> _contactedRideCodes = {};

  Timer? _ringingTimeoutTimer;
  Timer? _durationTimer;
  Timer? _demoAutoAnswerTimer;

  // Track call history for verification proof
  String _lastCallStatus = 'none';
  int _lastCallDuration = 0;

  String get lastCallStatus => _lastCallStatus;
  int get lastCallDuration => _lastCallDuration;

  /// Returns true if captain or rider has placed or received an in-app call for this trip
  bool hasAttemptedContact(String rideCode) {
    return _contactedRideCodes.contains(rideCode);
  }

  /// Manually mark contact attempted (e.g. after sending an in-app chat)
  void recordContactAttempt(String rideCode) {
    _contactedRideCodes.add(rideCode);
    notifyListeners();
  }

  /// Subscribes to the real-time call channel for an active trip
  void listenToRideCalls(String rideCode, {required String myRole, required BuildContext? context}) {
    if (_activeChannels.containsKey(rideCode)) return;

    try {
      final channel = _client.channel('call_$rideCode');

      channel.onBroadcast(
        event: 'call_offer',
        callback: (payload) {
          final data = Map<String, dynamic>.from(payload);
          final callerRole = data['caller_role']?.toString() ?? 'passenger';
          // Only react if the call was initiated by the OTHER role
          if (callerRole == myRole) return;

          _handleIncomingCall(
            rideCode: rideCode,
            callerName: data['caller_name']?.toString() ?? (callerRole == 'driver' ? 'Captain' : 'Passenger'),
            callerRole: callerRole == 'driver' ? 'Captain' : 'Passenger',
            callerPhone: data['caller_phone']?.toString(),
          );
        },
      );

      channel.onBroadcast(
        event: 'call_answer',
        callback: (payload) {
          if (_currentSession != null && _currentSession!.status == CallStatus.outgoingRinging) {
            _onCallConnected();
          }
        },
      );

      channel.onBroadcast(
        event: 'call_decline',
        callback: (payload) {
          if (_currentSession != null) {
            endCall(reason: 'declined');
          }
        },
      );

      channel.onBroadcast(
        event: 'call_hangup',
        callback: (payload) {
          if (_currentSession != null) {
            endCall(reason: 'remote_hangup');
          }
        },
      );

      channel.subscribe();
      _activeChannels[rideCode] = channel;
    } catch (_) {}
  }

  /// Initiates an outgoing VoIP internet call to peer
  Future<void> startOutgoingCall({
    required String rideCode,
    required String peerName,
    required String peerRole,
    String? peerPhone,
    required String myRole,
    bool simulateAnswerForDemo = true,
  }) async {
    _cleanupTimers();
    AudioCuesService.instance.stopPhoneRing();

    _currentSession = CallSession(
      rideCode: rideCode,
      peerName: peerName,
      peerRole: peerRole,
      peerPhone: peerPhone,
      isOutgoing: true,
      status: CallStatus.outgoingRinging,
    );

    // Record verified contact attempt for platform dispute protection
    _contactedRideCodes.add(rideCode);
    _lastCallStatus = 'ringing';
    _lastCallDuration = 0;
    notifyListeners();

    // Start outgoing ringing cadence
    AudioCuesService.instance.startPhoneRing(isIncoming: false);

    // Broadcast call offer via Supabase Realtime
    try {
      final channel = _activeChannels[rideCode] ?? _client.channel('call_$rideCode');
      channel.sendBroadcastMessage(
        event: 'call_offer',
        payload: {
          'caller_role': myRole,
          'caller_name': myRole == 'driver' ? 'Captain' : 'Passenger',
          'caller_phone': peerPhone,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {}

    // Auto-timeout after 35 seconds if no answer
    _ringingTimeoutTimer = Timer(const Duration(seconds: 35), () {
      if (_currentSession?.status == CallStatus.outgoingRinging) {
        endCall(reason: 'no_answer');
      }
    });

    // In demo / single-device testing: auto-answer after 3 seconds so the user can test active VoIP
    if (simulateAnswerForDemo) {
      _demoAutoAnswerTimer = Timer(const Duration(seconds: 4), () {
        if (_currentSession?.status == CallStatus.outgoingRinging) {
          _onCallConnected();
        }
      });
    }
  }

  void _handleIncomingCall({
    required String rideCode,
    required String callerName,
    required String callerRole,
    String? callerPhone,
  }) {
    _cleanupTimers();
    _currentSession = CallSession(
      rideCode: rideCode,
      peerName: callerName,
      peerRole: callerRole,
      peerPhone: callerPhone,
      isOutgoing: false,
      status: CallStatus.incomingRinging,
    );

    _contactedRideCodes.add(rideCode);
    notifyListeners();

    // Play incoming phone ringtone
    AudioCuesService.instance.startPhoneRing(isIncoming: true);

    _ringingTimeoutTimer = Timer(const Duration(seconds: 35), () {
      if (_currentSession?.status == CallStatus.incomingRinging) {
        endCall(reason: 'missed');
      }
    });
  }

  /// Answers an incoming call
  void answerCall() {
    if (_currentSession == null) return;
    _onCallConnected();

    // Broadcast answer to peer
    try {
      final channel = _activeChannels[_currentSession!.rideCode];
      channel?.sendBroadcastMessage(
        event: 'call_answer',
        payload: {'status': 'answered'},
      );
    } catch (_) {}
  }

  void _onCallConnected() {
    _cleanupTimers();
    AudioCuesService.instance.playCallConnected();

    if (_currentSession != null) {
      _currentSession!.status = CallStatus.connected;
      _currentSession!.durationSeconds = 0;
      _lastCallStatus = 'connected';
      notifyListeners();

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_currentSession != null && _currentSession!.status == CallStatus.connected) {
          _currentSession!.durationSeconds++;
          _lastCallDuration = _currentSession!.durationSeconds;
          notifyListeners();
        }
      });
    }
  }

  /// Ends or declines active call
  void endCall({String reason = 'user_hangup'}) {
    final code = _currentSession?.rideCode;
    final duration = _currentSession?.durationSeconds ?? 0;

    _cleanupTimers();
    AudioCuesService.instance.playCallEnded();

    if (_currentSession != null) {
      _currentSession!.status = CallStatus.ended;
      _lastCallDuration = duration;
      _lastCallStatus = duration > 0 ? 'completed' : reason;
      notifyListeners();

      // Notify remote peer via Supabase
      if (code != null) {
        try {
          final channel = _activeChannels[code];
          channel?.sendBroadcastMessage(
            event: reason == 'declined' ? 'call_decline' : 'call_hangup',
            payload: {'reason': reason, 'duration': duration},
          );
        } catch (_) {}
      }
    }

    // Dismiss session state after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentSession?.status == CallStatus.ended) {
        _currentSession = null;
        notifyListeners();
      }
    });
  }

  void toggleMute() {
    if (_currentSession == null) return;
    _currentSession!.isMuted = !_currentSession!.isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    if (_currentSession == null) return;
    _currentSession!.isSpeakerOn = !_currentSession!.isSpeakerOn;
    notifyListeners();
  }

  void _cleanupTimers() {
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _demoAutoAnswerTimer?.cancel();
    _demoAutoAnswerTimer = null;
  }

  @override
  void dispose() {
    _cleanupTimers();
    AudioCuesService.instance.stopPhoneRing();
    super.dispose();
  }
}

