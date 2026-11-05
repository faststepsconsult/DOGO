import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioCuesService {
  static final AudioCuesService _instance = AudioCuesService._internal();
  static AudioCuesService get instance => _instance;

  AudioCuesService._internal();

  static const String _keySoundEnabled = 'dogo_audio_cues_enabled_v1';

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();

  bool _initialized = false;
  bool _soundEnabled = true;
  Timer? _incomingAlertLoopTimer;
  bool _isAlertLooping = false;

  bool get soundEnabled => _soundEnabled;
  bool get isAlertLooping => _isAlertLooping;

  // Cached Synthesized WAV Audio Buffers
  Uint8List? _incomingRideWav;
  Uint8List? _driverMatchedWav;
  Uint8List? _driverArrivedWav;
  Uint8List? _tripStartedWav;
  Uint8List? _tripCompletedWav;
  Uint8List? _tipReceivedWav;
  Uint8List? _chatMessageWav;
  Uint8List? _phoneRingWav;
  Uint8List? _callConnectedWav;
  Uint8List? _callEndedWav;

  Timer? _phoneRingLoopTimer;
  bool _isPhoneRingLooping = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    } catch (_) {}

    // Synthesize all sound cues into memory in the background
    _generateSoundBuffers();
    _initialized = true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (!_soundEnabled) {
      stopIncomingRideAlert();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, _soundEnabled);
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    await setSoundEnabled(!_soundEnabled);
  }

  // ==========================================
  // Sound Player Methods
  // ==========================================

  /// Continuous radar ringtone for incoming driver ride request (repeats every 1.8s)
  Future<void> startIncomingRideAlert() async {
    if (_isAlertLooping) return;
    _isAlertLooping = true;

    void playPulse() async {
      if (!_isAlertLooping) return;
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}

      if (_soundEnabled) {
        try {
          final wav = _incomingRideWav ?? _buildIncomingRideAlertWav();
          await _alertPlayer.play(BytesSource(wav), volume: 1.0);
        } catch (_) {}
      }
    }

    playPulse();
    _incomingAlertLoopTimer?.cancel();
    _incomingAlertLoopTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      playPulse();
    });
  }

  /// Stops incoming ride ringtone immediately when driver accepts/declines or timer ends
  Future<void> stopIncomingRideAlert() async {
    _isAlertLooping = false;
    _incomingAlertLoopTimer?.cancel();
    _incomingAlertLoopTimer = null;
    try {
      await _alertPlayer.stop();
    } catch (_) {}
  }

  /// Passenger sound: Captain found & confirmed en route
  Future<void> playDriverMatched() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _driverMatchedWav ?? _buildDriverMatchedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 0.95);
    } catch (_) {}
  }

  /// Passenger sound: Captain has arrived outside pickup location
  Future<void> playDriverArrived() async {
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _driverArrivedWav ?? _buildDriverArrivedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 1.0);
    } catch (_) {}
  }

  /// Driver/Passenger sound: Trip started affirmation
  Future<void> playTripStarted() async {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _tripStartedWav ?? _buildTripStartedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 0.9);
    } catch (_) {}
  }

  /// Driver/Passenger sound: Trip completed and fare settled celebration
  Future<void> playTripCompleted() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _tripCompletedWav ?? _buildTripCompletedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 1.0);
    } catch (_) {}
  }

  /// Driver sound: Passenger tip received "Cha-Ching!"
  Future<void> playTipReceived() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _tipReceivedWav ?? _buildTipReceivedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 1.0);
    } catch (_) {}
  }

  /// In-trip chat sound: Short crisp message pop
  Future<void> playChatMessage() async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _chatMessageWav ?? _buildChatMessageWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 0.85);
    } catch (_) {}
  }

  /// VoIP Internet Calling: Repeating phone ringtone
  Future<void> startPhoneRing({bool isIncoming = false}) async {
    if (_isPhoneRingLooping) return;
    _isPhoneRingLooping = true;

    void ringPulse() async {
      if (!_isPhoneRingLooping) return;
      try {
        if (isIncoming) {
          HapticFeedback.vibrate();
        } else {
          HapticFeedback.selectionClick();
        }
      } catch (_) {}

      if (_soundEnabled) {
        try {
          final wav = _phoneRingWav ?? _buildPhoneRingWav(isIncoming: isIncoming);
          await _sfxPlayer.play(BytesSource(wav), volume: 0.85);
        } catch (_) {}
      }
    }

    ringPulse();
    _phoneRingLoopTimer?.cancel();
    _phoneRingLoopTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      ringPulse();
    });
  }

  /// Stops phone ringtone
  void stopPhoneRing() {
    _isPhoneRingLooping = false;
    _phoneRingLoopTimer?.cancel();
    _phoneRingLoopTimer = null;
    try {
      _sfxPlayer.stop();
    } catch (_) {}
  }

  /// Pleasant ascending chime when in-app data call connects
  Future<void> playCallConnected() async {
    stopPhoneRing();
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _callConnectedWav ?? _buildCallConnectedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 0.9);
    } catch (_) {}
  }

  /// Descending soft beep when in-app data call ends
  Future<void> playCallEnded() async {
    stopPhoneRing();
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    if (!_soundEnabled) return;
    try {
      final wav = _callEndedWav ?? _buildCallEndedWav();
      await _sfxPlayer.play(BytesSource(wav), volume: 0.8);
    } catch (_) {}
  }

  // ==========================================
  // PCM WAV Synthesizers (Zero Latency, 100% Offline)
  // ==========================================

  void _generateSoundBuffers() {
    _incomingRideWav = _buildIncomingRideAlertWav();
    _driverMatchedWav = _buildDriverMatchedWav();
    _driverArrivedWav = _buildDriverArrivedWav();
    _tripStartedWav = _buildTripStartedWav();
    _tripCompletedWav = _buildTripCompletedWav();
    _tipReceivedWav = _buildTipReceivedWav();
    _chatMessageWav = _buildChatMessageWav();
  }

  /// Rising radar pulse: 659Hz (E5) -> 880Hz (A5)
  Uint8List _buildIncomingRideAlertWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    // Pulse 1: 659.25 Hz for 180ms
    final n1 = (sampleRate * 0.18).round();
    for (var i = 0; i < n1; i++) {
      final t = i / sampleRate;
      final env = math.exp(-6.0 * t); // crisp decay
      final wave = math.sin(2 * math.pi * 659.25 * t) + 0.3 * math.sin(2 * math.pi * 1318.5 * t);
      samples.add(wave * env * 0.8);
    }

    // Silence gap: 60ms
    final nGap = (sampleRate * 0.06).round();
    for (var i = 0; i < nGap; i++) {
      samples.add(0.0);
    }

    // Pulse 2: 880.00 Hz for 320ms (higher pitch radar beacon)
    final n2 = (sampleRate * 0.32).round();
    for (var i = 0; i < n2; i++) {
      final t = i / sampleRate;
      final env = math.exp(-4.5 * t);
      final wave = math.sin(2 * math.pi * 880.0 * t) + 0.25 * math.sin(2 * math.pi * 1760.0 * t);
      samples.add(wave * env * 0.85);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// 3-Tone Arpeggio: C5 (523Hz) -> E5 (659Hz) -> G5 (784Hz)
  Uint8List _buildDriverMatchedWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    void addNote(double freq, double durSec, double decayRate) {
      final n = (sampleRate * durSec).round();
      for (var i = 0; i < n; i++) {
        final t = i / sampleRate;
        final env = math.exp(-decayRate * t);
        final wave = math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(2 * math.pi * freq * 2 * t);
        samples.add(wave * env * 0.8);
      }
    }

    addNote(523.25, 0.12, 4.0);
    addNote(659.25, 0.12, 4.0);
    addNote(783.99, 0.32, 3.5);

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Two-tone Doorbell: E5 (659Hz) -> C5 (523Hz)
  Uint8List _buildDriverArrivedWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    void addBell(double freq, double durSec) {
      final n = (sampleRate * durSec).round();
      for (var i = 0; i < n; i++) {
        final t = i / sampleRate;
        final env = math.exp(-4.0 * t);
        // Rich bell timbre with 2nd and 3rd harmonics
        final wave = math.sin(2 * math.pi * freq * t) +
            0.35 * math.sin(2 * math.pi * freq * 2 * t) +
            0.15 * math.sin(2 * math.pi * freq * 3 * t);
        samples.add(wave * env * 0.75);
      }
    }

    addBell(659.25, 0.26);
    addBell(523.25, 0.48);

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Confirmation tone: G4 -> C5
  Uint8List _buildTripStartedWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    void addTone(double freq, double durSec) {
      final n = (sampleRate * durSec).round();
      for (var i = 0; i < n; i++) {
        final t = i / sampleRate;
        final env = math.exp(-5.0 * t);
        final wave = math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(2 * math.pi * freq * 2 * t);
        samples.add(wave * env * 0.75);
      }
    }

    addTone(392.00, 0.12);
    addTone(523.25, 0.30);

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Victory Arpeggio: C5 -> E5 -> G5 -> C6
  Uint8List _buildTripCompletedWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    void addNote(double freq, double durSec, double decay) {
      final n = (sampleRate * durSec).round();
      for (var i = 0; i < n; i++) {
        final t = i / sampleRate;
        final env = math.exp(-decay * t);
        final wave = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * freq * 2 * t);
        samples.add(wave * env * 0.75);
      }
    }

    addNote(523.25, 0.10, 4.0);
    addNote(659.25, 0.10, 4.0);
    addNote(783.99, 0.14, 4.0);
    addNote(1046.50, 0.45, 3.0);

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Cash register "Cha-Ching!" coin shimmer: E6 (1318Hz) -> A6 (1760Hz)
  Uint8List _buildTipReceivedWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    // Initial click/shimmer (80ms)
    final n1 = (sampleRate * 0.08).round();
    for (var i = 0; i < n1; i++) {
      final t = i / sampleRate;
      final env = math.exp(-8.0 * t);
      final wave = math.sin(2 * math.pi * 1318.5 * t) + 0.4 * math.sin(2 * math.pi * 2637.0 * t);
      samples.add(wave * env * 0.85);
    }

    // Resonant bell chime (420ms)
    final n2 = (sampleRate * 0.42).round();
    for (var i = 0; i < n2; i++) {
      final t = i / sampleRate;
      final env = math.exp(-3.5 * t);
      final wave = math.sin(2 * math.pi * 1760.0 * t) +
          0.35 * math.sin(2 * math.pi * 3520.0 * t) +
          0.2 * math.sin(2 * math.pi * 2200.0 * t); // metallic overtone
      samples.add(wave * env * 0.9);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Crisp message pop
  Uint8List _buildChatMessageWav() {
    const sampleRate = 22050;
    final samples = <double>[];
    final n = (sampleRate * 0.09).round();

    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final progress = i / n;
      // Frequency sweep 650Hz -> 1050Hz
      final freq = 650.0 + (400.0 * progress);
      final env = math.sin(math.pi * progress) * math.exp(-6.0 * progress);
      final wave = math.sin(2 * math.pi * freq * t);
      samples.add(wave * env * 0.85);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// VoIP telephone ringing cadence: Dual-tone 440Hz + 480Hz pulses
  Uint8List _buildPhoneRingWav({bool isIncoming = false}) {
    const sampleRate = 22050;
    final samples = <double>[];
    // Ring tone pulse of 1.2s duration (followed by silence in loop)
    final durationSec = isIncoming ? 1.4 : 1.2;
    final totalSamples = (sampleRate * durationSec).round();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Fade in and out gently to avoid clipping clicks
      double env = 1.0;
      if (t < 0.05) env = t / 0.05;
      if (t > (durationSec - 0.05)) env = (durationSec - t) / 0.05;

      // Standard North American / European ringing dual-frequency (440Hz + 480Hz)
      final wave = 0.5 * math.sin(2 * math.pi * 440.0 * t) +
          0.5 * math.sin(2 * math.pi * 480.0 * t);
      samples.add(wave * env * 0.75);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Pleasant ascending two-tone connect chime (523Hz C5 -> 659Hz E5)
  Uint8List _buildCallConnectedWav() {
    const sampleRate = 22050;
    final samples = <double>[];

    // Note 1: C5 (523Hz) for 120ms
    final n1 = (sampleRate * 0.12).round();
    for (var i = 0; i < n1; i++) {
      final t = i / sampleRate;
      final env = math.exp(-4.0 * t);
      final wave = math.sin(2 * math.pi * 523.25 * t);
      samples.add(wave * env * 0.8);
    }

    // Note 2: E5 (659Hz) for 200ms
    final n2 = (sampleRate * 0.20).round();
    for (var i = 0; i < n2; i++) {
      final t = i / sampleRate;
      final env = math.exp(-3.5 * t);
      final wave = math.sin(2 * math.pi * 659.25 * t);
      samples.add(wave * env * 0.85);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Descending soft disconnect beep (440Hz -> 220Hz)
  Uint8List _buildCallEndedWav() {
    const sampleRate = 22050;
    final samples = <double>[];
    final n = (sampleRate * 0.22).round();

    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final progress = i / n;
      final freq = 440.0 - (200.0 * progress);
      final env = math.exp(-5.0 * progress);
      final wave = math.sin(2 * math.pi * freq * t);
      samples.add(wave * env * 0.75);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  /// Encodes raw PCM samples into standard 44-byte WAV format
  Uint8List _encodeWav(List<double> samples, {int sampleRate = 22050}) {
    final numSamples = samples.length;
    final subChunk2Size = numSamples * 2; // 16-bit mono
    final chunkSize = 36 + subChunk2Size;
    final byteData = ByteData(44 + subChunk2Size);

    // RIFF Header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, chunkSize, Endian.little);
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
    byteData.setUint16(20, 1, Endian.little); // PCM format = 1
    byteData.setUint16(22, 1, Endian.little); // 1 Channel (Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample = 16

    // data subchunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, subChunk2Size, Endian.little);

    var offset = 44;
    for (var i = 0; i < numSamples; i++) {
      final s = samples[i].clamp(-1.0, 1.0);
      final intSample = (s * 32767).round();
      byteData.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  void dispose() {
    _incomingAlertLoopTimer?.cancel();
    _alertPlayer.dispose();
    _sfxPlayer.dispose();
  }
}

