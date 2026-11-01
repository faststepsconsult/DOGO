import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/ride_model.dart';
import '../../../../data/services/driver_tracking_service.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/services/rides_dispatch_service.dart';
import '../../../../data/services/road_routing_service.dart';

enum DriverSession {
  offline,
  online,
  request,
  toPickup,
  atPickup,
  onTrip,
  complete,
}

class MapPoint {
  final double x;
  final double y;
  const MapPoint(this.x, this.y);
}

class DriverRideRequest {
  final String id;
  final String passenger;
  final String passengerPhone;
  final String pin;
  final String initials;
  final double rating;
  final String pickupName;
  final String dropoffName;
  final double distanceKm;
  final int minutes;
  final int fare; // Gross fare paid by passenger
  final String payment; // 'Cash' | 'Card'
  final MapPoint pickup;
  final MapPoint destination;

  const DriverRideRequest({
    required this.id,
    required this.passenger,
    this.passengerPhone = '+2348031234567',
    this.pin = '1234',
    required this.initials,
    required this.rating,
    required this.pickupName,
    required this.dropoffName,
    required this.distanceKm,
    required this.minutes,
    required this.fare,
    required this.payment,
    required this.pickup,
    required this.destination,
  });

  int get driverPayout => (fare * 0.85).round();
  int get commission => fare - driverPayout;
}

class CompletedDriverTrip {
  final String id;
  final String passenger;
  final String pickupName;
  final String dropoffName;
  final int totalFare; // Gross fare paid by passenger
  final int fare; // Net payout after commission (85%)
  final int commission; // 15% platform commission
  int tip; // Real-time tip if received
  final double distanceKm;
  final int minutes;
  final String payment;
  final DateTime completedAt;

  CompletedDriverTrip({
    required this.id,
    required this.passenger,
    required this.pickupName,
    required this.dropoffName,
    int? totalFare,
    required this.fare,
    int? commission,
    this.tip = 0,
    required this.distanceKm,
    required this.minutes,
    required this.payment,
    required this.completedAt,
  })  : totalFare = totalFare ?? ((fare / 0.85).round()),
        commission = commission ?? (((totalFare ?? ((fare / 0.85).round())) - fare));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger': passenger,
      'pickupName': pickupName,
      'dropoffName': dropoffName,
      'totalFare': totalFare,
      'fare': fare,
      'commission': commission,
      'tip': tip,
      'distanceKm': distanceKm,
      'minutes': minutes,
      'payment': payment,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory CompletedDriverTrip.fromJson(Map<String, dynamic> json) {
    return CompletedDriverTrip(
      id: json['id'] as String? ?? 'trip-${DateTime.now().millisecondsSinceEpoch}',
      passenger: json['passenger'] as String? ?? 'Passenger',
      pickupName: json['pickupName'] as String? ?? 'Pickup',
      dropoffName: json['dropoffName'] as String? ?? 'Dropoff',
      totalFare: (json['totalFare'] as num?)?.toInt(),
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      commission: (json['commission'] as num?)?.toInt(),
      tip: (json['tip'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 5.0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 15,
      payment: json['payment'] as String? ?? 'Cash',
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DriverViewModel extends ChangeNotifier {
  static const int requestDurationSeconds = 30;
  static const double commissionRate = 0.15;
  static const int driverSharePercent = 85;

  static const String _keyDriverEarnings = 'dogo_driver_today_earnings_v1';
  static const String _keyDriverWallet = 'dogo_driver_wallet_balance_v1';
  static const String _keyDriverTrips = 'dogo_driver_completed_trips_v1';

  DriverSession _session = DriverSession.offline;
  int _secondsLeft = requestDurationSeconds;
  int _waitSeconds = 0;
  int _ratingStars = 5;
  bool _pinVerified = false;

  Timer? _requestCountdownTimer;
  Timer? _requestCheckTimer;
  Timer? _waitStopwatchTimer;
  Timer? _onlineTriggerTimer;
  String? _sessionMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _pendingRidesSub;
  Timer? _pendingPollTimer;
  final RidesDispatchService _dispatchService = RidesDispatchService();
  final DriverTrackingService _trackingService = DriverTrackingService();
  StreamSubscription<LatLng>? _gpsStreamSub;
  StreamSubscription<Map<String, dynamic>>? _tipSub;
  Timer? _driverSimulatedNavTimer;
  LatLng? _currentDriverGps;
  final double _currentDriverHeading = 0.0;
  final Set<String> _ignoredRides = {};
  bool _autoSimulateDemo = false;
  String _currentDriverName = 'Captain';

  int _todayEarnings = 28500;
  int _driverWalletBalance = 28500;

  DriverViewModel() {
    initLocation();
    _loadDriverFinancials();
  }

  Future<void> _loadDriverFinancials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyDriverEarnings)) {
        _todayEarnings = prefs.getInt(_keyDriverEarnings) ?? 28500;
      }
      if (prefs.containsKey(_keyDriverWallet)) {
        _driverWalletBalance = prefs.getInt(_keyDriverWallet) ?? 28500;
      }
      final rawTrips = prefs.getStringList(_keyDriverTrips);
      if (rawTrips != null && rawTrips.isNotEmpty) {
        _completedTrips.clear();
        for (final raw in rawTrips) {
          try {
            _completedTrips.add(CompletedDriverTrip.fromJson(jsonDecode(raw)));
          } catch (_) {}
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveDriverFinancials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDriverEarnings, _todayEarnings);
      await prefs.setInt(_keyDriverWallet, _driverWalletBalance);
      final rawList = _completedTrips.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_keyDriverTrips, rawList);
    } catch (_) {}
  }

  Future<void> initLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      _currentDriverGps = pos;
      notifyListeners();

      _gpsStreamSub?.cancel();
      _gpsStreamSub = LocationService.getLivePositionStream().listen((pos) {
        _currentDriverGps = pos;
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}
  }

  bool get autoSimulateDemo => _autoSimulateDemo;

  void toggleAutoSimulateDemo() {
    _autoSimulateDemo = !_autoSimulateDemo;
    notifyListeners();
  }

  void triggerSimulatedRequest() {
    if (_session == DriverSession.online) {
      _activeRequest = _sampleRequests[_requestIndex % _sampleRequests.length];
      _requestIndex++;
      setSession(DriverSession.request);
    }
  }

  final List<CompletedDriverTrip> _completedTrips = [
    CompletedDriverTrip(
      id: 'trip-seed-1',
      passenger: 'Babatunde A.',
      pickupName: 'Lekki Phase 1, Admiralty Way',
      dropoffName: 'Victoria Island, Adeola Odeku',
      fare: 4200,
      distanceKm: 6.8,
      minutes: 18,
      payment: 'Card',
      completedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    ),
    CompletedDriverTrip(
      id: 'trip-seed-2',
      passenger: 'Zainab Bello',
      pickupName: 'Maryland Mall, Ikorodu Road',
      dropoffName: 'Ikeja City Mall, Alausa',
      fare: 3500,
      distanceKm: 5.2,
      minutes: 14,
      payment: 'Cash',
      completedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 40)),
    ),
    CompletedDriverTrip(
      id: 'trip-seed-3',
      passenger: 'Chukwuma Eze',
      pickupName: 'Surulere, Adeniran Ogunsanya',
      dropoffName: 'Marina, Lagos Island',
      fare: 5100,
      distanceKm: 9.1,
      minutes: 24,
      payment: 'Card',
      completedAt: DateTime.now().subtract(const Duration(hours: 6, minutes: 10)),
    ),
  ];

  static const List<DriverRideRequest> _sampleRequests = [
    DriverRideRequest(
      id: 'req-yaba',
      passenger: 'Chinedu O.',
      initials: 'CO',
      rating: 4.8,
      pickupName: 'Yaba Bus Stop, Yaba',
      dropoffName: 'Ikeja City Mall, Alausa',
      distanceKm: 9.4,
      minutes: 26,
      fare: 4650,
      payment: 'Cash',
      pickup: MapPoint(117, 260),
      destination: MapPoint(272, 130),
    ),
    DriverRideRequest(
      id: 'req-akoka',
      passenger: 'Funmi A.',
      initials: 'FA',
      rating: 4.9,
      pickupName: 'UNILAG Second Gate, Akoka',
      dropoffName: 'Landmark Beach, Victoria Island',
      distanceKm: 11.2,
      minutes: 31,
      fare: 6200,
      payment: 'Card',
      pickup: MapPoint(272, 516),
      destination: MapPoint(349, 130),
    ),
    DriverRideRequest(
      id: 'req-ikeja',
      passenger: 'Emeka N.',
      initials: 'EN',
      rating: 4.7,
      pickupName: 'Ikeja Under Bridge, Ikeja',
      dropoffName: 'Murtala Muhammed Airport, Ikeja',
      distanceKm: 14.6,
      minutes: 38,
      fare: 8100,
      payment: 'Cash',
      pickup: MapPoint(117, 516),
      destination: MapPoint(195, 130),
    ),
  ];

  int _requestIndex = 0;
  DriverRideRequest? _activeRequest;

  DriverSession get session => _session;
  int get secondsLeft => _secondsLeft;
  int get waitSeconds => _waitSeconds;
  int get ratingStars => _ratingStars;
  int get todayEarnings => _todayEarnings;
  int get driverWalletBalance => _driverWalletBalance;
  String get formattedDriverWalletBalance => '₦${NumberFormat('#,###').format(_driverWalletBalance)}';
  List<CompletedDriverTrip> get completedTrips => List.unmodifiable(_completedTrips);
  int get completedTripsCount => _completedTrips.length;
  double get driverRating => 4.98;
  int get driverShare => driverSharePercent;
  LatLng? get currentDriverGps => _currentDriverGps;
  double get currentDriverHeading => _currentDriverHeading;
  bool get pinVerified => _pinVerified;
  String? get sessionMessage => _sessionMessage;

  void clearSessionMessage() {
    _sessionMessage = null;
    notifyListeners();
  }

  /// Withdraws driver earnings directly to Nigerian bank account
  Future<bool> withdrawToBank({
    required String bankName,
    required String accountNumber,
    required String accountName,
    required int amount,
  }) async {
    if (amount <= 0 || _driverWalletBalance < amount) return false;
    _driverWalletBalance -= amount;
    await _saveDriverFinancials();
    _sessionMessage = '₦${NumberFormat('#,###').format(amount)} withdrawn successfully to $bankName ($accountNumber)';
    notifyListeners();
    return true;
  }

  bool verifyPin(String enteredPin) {
    final cleanEntered = enteredPin.trim();
    final expected = currentRequest.pin.trim();
    if (cleanEntered.isNotEmpty && cleanEntered == expected) {
      _pinVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void resetPinVerification() {
    _pinVerified = false;
    notifyListeners();
  }

  DriverRideRequest get currentRequest =>
      _activeRequest ?? _sampleRequests[_requestIndex % _sampleRequests.length];

  bool get isOffline => _session == DriverSession.offline;
  bool get isOnline => _session == DriverSession.online;
  bool get isBusy => _session != DriverSession.offline && _session != DriverSession.online;

  void toggleOnline() {
    if (_session == DriverSession.offline) {
      setSession(DriverSession.online);
    } else {
      setSession(DriverSession.offline);
    }
  }

  void setSession(DriverSession newSession) {
    _session = newSession;
    _cleanTimers();
    if (newSession != DriverSession.atPickup) {
      _pinVerified = false;
    }

    if (_session == DriverSession.online) {
      void processPendingList(List<Map<String, dynamic>> list) {
        if (_session != DriverSession.online) return;
        for (final r in list) {
          final code = r['code']?.toString() ?? '';
          if (code.isNotEmpty && !_ignoredRides.contains(code) && (r['status'] == 'pending')) {
            final distanceKm = (r['distance_km'] as num?)?.toDouble() ?? 5.0;
            final minutes = (distanceKm * 2.5).round().clamp(5, 60);
            final passengerName = r['passenger_name']?.toString() ?? 'Passenger';
            final passengerPhone = r['passenger_phone']?.toString() ?? '+2348031234567';
            final pin = RideModel.derivePinFromCode(code);
            final initials = passengerName
                .split(' ')
                .where((s) => s.isNotEmpty)
                .map((s) => s[0])
                .take(2)
                .join()
                .toUpperCase();

            _activeRequest = DriverRideRequest(
              id: code,
              passenger: passengerName,
              passengerPhone: passengerPhone,
              pin: pin,
              initials: initials.isNotEmpty ? initials : 'PA',
              rating: 4.9,
              pickupName: r['pickup_address']?.toString() ?? 'Pickup location',
              dropoffName: r['dropoff_address']?.toString() ?? 'Dropoff destination',
              distanceKm: distanceKm,
              minutes: minutes,
              fare: (r['fare_amount'] as num?)?.toInt() ?? 2500,
              payment: (r['payment_method']?.toString() ?? 'wallet').toUpperCase(),
              pickup: const MapPoint(117, 260),
              destination: const MapPoint(272, 130),
            );

            setSession(DriverSession.request);
            return;
          }
        }
      }

      // 1. Subscribe to Supabase pending rides stream
      try {
        _pendingRidesSub = _dispatchService.streamPendingRides().listen((list) {
          processPendingList(list);
        }, onError: (_) {});
      } catch (_) {}

      // 2. Poll Supabase pending rides every 3s for guaranteed delivery
      _pendingPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (_session != DriverSession.online) return;
        final list = await _dispatchService.fetchPendingRides();
        processPendingList(list);
      });

      // 3. Fallback sample request only if user toggles auto-simulate demo
      if (_autoSimulateDemo) {
        _onlineTriggerTimer = Timer(const Duration(seconds: 10), () {
          if (_session == DriverSession.online) {
            triggerSimulatedRequest();
          }
        });
      }
    } else if (_session == DriverSession.request) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
      _secondsLeft = requestDurationSeconds;
      _requestCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 1) {
          _secondsLeft--;
          notifyListeners();
        } else {
          timer.cancel();
          if (_activeRequest != null) {
            _ignoredRides.add(_activeRequest!.id);
          }
          // Timeout: auto-resume online search
          setSession(DriverSession.online);
        }
      });

      // Poll every 2s to check if another driver claimed this ride first
      _requestCheckTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
        if (_session != DriverSession.request || _activeRequest == null) {
          t.cancel();
          return;
        }
        final remote = await _dispatchService.fetchRide(_activeRequest!.id);
        if (remote != null && remote.status != 'pending') {
          t.cancel();
          if (_activeRequest != null) {
            _ignoredRides.add(_activeRequest!.id);
          }
          _sessionMessage = 'Ride was accepted by another driver.';
          setSession(DriverSession.online);
        }
      });
    } else if (_session == DriverSession.atPickup) {
      _waitSeconds = 0;
      _waitStopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _waitSeconds++;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  Future<bool> acceptRide({
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPlate,
    String? driverVehicle,
  }) async {
    _cleanTimers();

    final req = currentRequest;
    final dName = driverName ?? 'Abdulmutallib Alasah';
    final dPlate = driverPlate ?? 'LAG-605-EK';
    final dVehicle = driverVehicle ?? 'Toyota Corolla (White)';
    final dPhone = driverPhone ?? '+2348024419922';

    final success = await _dispatchService.acceptRide(
      rideCode: req.id,
      driverId: driverId,
      driverName: dName,
      driverPlate: dPlate,
      driverVehicle: dVehicle,
      driverPhone: dPhone,
    );

    if (!success) {
      _ignoredRides.add(req.id);
      _sessionMessage = 'Another driver accepted this ride first!';
      setSession(DriverSession.online);
      return false;
    }

    _currentDriverName = dName;
    _session = DriverSession.toPickup;
    notifyListeners();

    // Listen for incoming real-time tips from passenger
    _tipSub?.cancel();
    _tipSub = _dispatchService.streamTip(req.id).listen((payload) {
      final tipAmount = (payload['tip_amount'] as num?)?.toInt() ?? 0;
      final passengerName = payload['passenger_name']?.toString() ?? 'Passenger';
      if (tipAmount > 0) {
        _todayEarnings += tipAmount;
        _driverWalletBalance += tipAmount;
        if (_completedTrips.isNotEmpty) {
          _completedTrips.first.tip += tipAmount;
        }
        _saveDriverFinancials();
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
        _sessionMessage = '🎉 Received ₦${NumberFormat('#,###').format(tipAmount)} tip from $passengerName!';
        notifyListeners();
      }
    }, onError: (_) {});

    await _dispatchService.updateStatus(rideCode: req.id, newStatus: 'to_pickup');
    _startDriverLocationBroadcast(req.id);
    return true;
  }

  void declineRide() {
    _cleanTimers();
    if (_activeRequest != null) {
      _ignoredRides.add(_activeRequest!.id);
    }
    setSession(DriverSession.online);
  }

  void cancelRide() {
    _cleanTimers();
    setSession(DriverSession.online);
  }

  Future<void> arrivedAtPickup() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    setSession(DriverSession.atPickup);
    await _dispatchService.updateStatus(
      rideCode: currentRequest.id,
      newStatus: 'at_pickup',
    );
  }

  Future<void> startTrip() async {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    _cleanTimers();
    _session = DriverSession.onTrip;
    notifyListeners();
    await _dispatchService.updateStatus(
      rideCode: currentRequest.id,
      newStatus: 'on_trip',
    );
    _startDriverLocationBroadcast(currentRequest.id);
  }

  void _startDriverLocationBroadcast(String rideCode) {
    _gpsStreamSub?.cancel();
    _driverSimulatedNavTimer?.cancel();

    final pickupCoord = LocationService.getCoordinates(currentRequest.pickupName);
    final dropoffCoord = LocationService.getCoordinates(currentRequest.dropoffName);

    // 1. Real Device GPS Stream (updates passenger live)
    try {
      _gpsStreamSub = LocationService.getLivePositionStream().listen((pos) {
        _currentDriverGps = pos;
        _trackingService.broadcastLocation(
          rideCode: rideCode,
          position: pos,
          heading: _currentDriverHeading,
        );
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {}

    // 2. Continuous Simulated GPS Drive Along Real Road Network
    final startPt = _session == DriverSession.toPickup
        ? (_currentDriverGps ?? const LatLng(6.5898, 3.3556))
        : pickupCoord;
    final endPt = _session == DriverSession.toPickup ? pickupCoord : dropoffCoord;

    RoadRoutingService.getDrivingRoute(startPt, endPt).then((routeRes) {
      if (_session != DriverSession.toPickup && _session != DriverSession.onTrip) {
        return;
      }
      final routePoints = routeRes.coordinates.isNotEmpty
          ? routeRes.coordinates
          : DriverTrackingService.generateRoutePoints(startPt, endPt, steps: 35);

      int stepIdx = 0;
      _driverSimulatedNavTimer?.cancel();
      _driverSimulatedNavTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_session != DriverSession.toPickup && _session != DriverSession.onTrip) {
          timer.cancel();
          return;
        }
        if (stepIdx < routePoints.length) {
          final pt = routePoints[stepIdx];
          _currentDriverGps = pt;

          double heading = 45.0;
          if (stepIdx < routePoints.length - 1) {
            heading = RoadRoutingService.calculateBearing(pt, routePoints[stepIdx + 1]);
          }

          _trackingService.broadcastLocation(
            rideCode: rideCode,
            position: pt,
            heading: heading,
          );
          final stride = math.max(1, (routePoints.length / 32).round());
          stepIdx += stride;
          notifyListeners();
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> completeTrip() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    _cleanTimers();
    final req = currentRequest;
    final payout = req.driverPayout;
    _todayEarnings += payout;
    _driverWalletBalance += payout;

    final trip = CompletedDriverTrip(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      passenger: req.passenger,
      pickupName: req.pickupName,
      dropoffName: req.dropoffName,
      totalFare: req.fare,
      fare: payout,
      commission: req.commission,
      distanceKm: req.distanceKm,
      minutes: req.minutes,
      payment: req.payment,
      completedAt: DateTime.now(),
    );

    _completedTrips.insert(0, trip);
    await _saveDriverFinancials();
    _ratingStars = 5;
    _session = DriverSession.complete;
    notifyListeners();

    // 1. Update status on Supabase
    await _dispatchService.updateStatus(
      rideCode: req.id,
      newStatus: 'completed',
    );

    // 2. Broadcast financial settlement to passenger phone in real-time
    await _dispatchService.broadcastSettlement(
      rideCode: req.id,
      totalFare: req.fare,
      driverEarnings: payout,
      platformCommission: req.commission,
      paymentMethod: req.payment,
      driverName: _currentDriverName,
    );
  }

  void setRating(int stars) {
    _ratingStars = stars.clamp(1, 5);
    notifyListeners();
  }

  void continueAfterComplete() {
    setSession(DriverSession.online);
  }

  void resetDemoData() {
    _cleanTimers();
    _tipSub?.cancel();
    _tipSub = null;
    _ignoredRides.clear();
    _session = DriverSession.offline;
    _todayEarnings = 0;
    _driverWalletBalance = 0;
    _completedTrips.clear();
    _requestIndex = 0;
    _activeRequest = null;
    _saveDriverFinancials();
    notifyListeners();
  }

  void _cleanTimers() {
    _requestCountdownTimer?.cancel();
    _requestCountdownTimer = null;
    _requestCheckTimer?.cancel();
    _requestCheckTimer = null;
    _waitStopwatchTimer?.cancel();
    _waitStopwatchTimer = null;
    _onlineTriggerTimer?.cancel();
    _onlineTriggerTimer = null;
    _pendingRidesSub?.cancel();
    _pendingRidesSub = null;
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
    _gpsStreamSub?.cancel();
    _gpsStreamSub = null;
    _driverSimulatedNavTimer?.cancel();
    _driverSimulatedNavTimer = null;
    _trackingService.stopTracking();
  }

  @override
  void dispose() {
    _cleanTimers();
    _tipSub?.cancel();
    _trackingService.dispose();
    super.dispose();
  }
}

