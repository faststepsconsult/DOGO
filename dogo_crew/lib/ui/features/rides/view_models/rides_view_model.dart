import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../data/models/ride_model.dart';
import '../../../../data/models/wallet_transaction_model.dart';
import '../../../../data/repositories/rides_repository.dart';
import '../../../../data/services/location_service.dart';

class RidesViewModel extends ChangeNotifier {
  final RidesRepository ridesRepo;

  List<RideModel> _rides = [];
  RideModel? _selectedRide;
  Timer? _liveTrackTimer;
  Timer? _livePollTimer;
  Timer? _fallbackDemoTimer;
  StreamSubscription<RideModel?>? _liveRideSub;

  // Booking Flow State
  int _bookingStep = 0;
  String _pickup = RidesRepository.cities[0].name;
  String _dropoff = RidesRepository.cities[1].name;
  LatLng? _pickupCoord;
  LatLng? _dropoffCoord;
  bool _isLocatingPickup = false;
  String _selectedVehicleId = 'taxi';
  String _selectedPaymentId = 'wallet';
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  String _recipientName = '';
  String _recipientPhone = '';
  String _itemLabel = '';

  RidesViewModel({required this.ridesRepo}) {
    _refreshRides();
  }

  List<RideModel> get allRides => _rides;
  List<RideModel> get recentRides => _rides.take(3).toList();
  RideModel? get selectedRide => _selectedRide;

  // Booking Getters
  int get bookingStep => _bookingStep;
  String get pickup => _pickup;
  String get dropoff => _dropoff;
  LatLng? get pickupCoord => _pickupCoord ?? LocationService.getCoordinates(_pickup);
  LatLng? get dropoffCoord => _dropoffCoord ?? LocationService.getCoordinates(_dropoff);
  bool get isLocatingPickup => _isLocatingPickup;
  String get selectedVehicleId => _selectedVehicleId;
  String get selectedPaymentId => _selectedPaymentId;
  bool get isScheduled => _isScheduled;
  DateTime? get scheduledDate => _scheduledDate;
  TimeOfDay? get scheduledTime => _scheduledTime;
  String get recipientName => _recipientName;
  String get recipientPhone => _recipientPhone;
  String get itemLabel => _itemLabel;

  int get currentDistance => ridesRepo.calculateDistance(
        _pickup,
        _dropoff,
        fromCoord: _pickupCoord,
        toCoord: _dropoffCoord,
      );

  VehicleOption get currentVehicle =>
      RidesRepository.vehicles.firstWhere((v) => v.id == _selectedVehicleId, orElse: () => RidesRepository.vehicles.first);

  int get currentFare => ridesRepo.calculateFare(currentVehicle, currentDistance);

  // Wallet Getters
  int get walletBalance => ridesRepo.walletBalance;
  String get formattedWalletBalance => '₦${NumberFormat('#,###').format(walletBalance)}';
  List<WalletTransactionModel> get walletTransactions => ridesRepo.walletTransactions;
  bool get hasSufficientWalletBalance => walletBalance >= currentFare;

  void _refreshRides() {
    _rides = ridesRepo.allRides;
    notifyListeners();
  }

  void selectRideByCode(String code) {
    _selectedRide = ridesRepo.getRide(code);
    _subscribeToLiveRide(code);
    notifyListeners();
  }

  void initBooking({bool isDispatch = false}) {
    _bookingStep = 0;
    _pickup = RidesRepository.cities[0].name;
    _pickupCoord = LocationService.getCoordinates(_pickup);
    _dropoff = RidesRepository.cities[1].name;
    _dropoffCoord = LocationService.getCoordinates(_dropoff);
    _isLocatingPickup = false;
    _selectedVehicleId = isDispatch ? 'bike' : 'taxi';
    _selectedPaymentId = 'wallet';
    _isScheduled = false;
    _scheduledDate = null;
    _scheduledTime = null;
    _recipientName = '';
    _recipientPhone = '';
    _itemLabel = '';
    notifyListeners();
  }

  void setBookingStep(int step) {
    _bookingStep = step;
    notifyListeners();
  }

  void setPickup(String val, {LatLng? coord}) {
    _pickup = val;
    _pickupCoord = coord ?? LocationService.getCoordinates(val);
    notifyListeners();
  }

  void setDropoff(String val, {LatLng? coord}) {
    _dropoff = val;
    _dropoffCoord = coord ?? LocationService.getCoordinates(val);
    notifyListeners();
  }

  /// Fetches real device GPS position, reverse-geocodes it to a readable place,
  /// and automatically sets it as the pickup point with resolved coordinates.
  Future<LocationPlace?> useCurrentGpsAsPickup() async {
    _isLocatingPickup = true;
    notifyListeners();
    try {
      final pos = await LocationService.getCurrentLocation();
      final place = await LocationService.reverseGeocode(pos);
      _pickup = place.displayName;
      _pickupCoord = pos;
      _isLocatingPickup = false;
      notifyListeners();
      return place;
    } catch (_) {
      _isLocatingPickup = false;
      notifyListeners();
      return null;
    }
  }

  void setVehicleId(String id) {
    _selectedVehicleId = id;
    notifyListeners();
  }

  void setPaymentId(String id) {
    _selectedPaymentId = id;
    notifyListeners();
  }

  void setScheduled(bool scheduled) {
    _isScheduled = scheduled;
    notifyListeners();
  }

  void setScheduledDateTime(DateTime date, TimeOfDay time) {
    _scheduledDate = date;
    _scheduledTime = time;
    notifyListeners();
  }

  void setDispatchInfo({required String name, required String phone, required String item}) {
    _recipientName = name;
    _recipientPhone = phone;
    _itemLabel = item;
    notifyListeners();
  }

  RideModel confirmBooking({String? passengerName, String? passengerPhone}) {
    final paymentLabel = RidesRepository.paymentMethods
        .firstWhere((m) => m.id == _selectedPaymentId, orElse: () => RidesRepository.paymentMethods.first)
        .label;

    String? scheduledStr;
    if (_isScheduled && _scheduledDate != null && _scheduledTime != null) {
      final d = _scheduledDate!;
      final t = _scheduledTime!;
      final hourStr = t.hour.toString().padLeft(2, '0');
      final minuteStr = t.minute.toString().padLeft(2, '0');
      scheduledStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} at $hourStr:$minuteStr';
    }

    final newRide = ridesRepo.createRide(
      pickup: _pickup,
      dropoff: _dropoff,
      pickupCoord: _pickupCoord,
      dropoffCoord: _dropoffCoord,
      vehicle: currentVehicle,
      payment: paymentLabel,
      scheduledAt: scheduledStr,
      passengerName: passengerName != null && passengerName.isNotEmpty ? passengerName : 'Salim Bello',
      passengerPhone: passengerPhone != null && passengerPhone.isNotEmpty ? passengerPhone : '+2348031234567',
      recipientName: _recipientName,
      recipientPhone: _recipientPhone,
      itemLabel: _itemLabel.isNotEmpty ? _itemLabel : null,
    );

    if (_selectedPaymentId == 'wallet') {
      ridesRepo.deductWallet(
        newRide.price,
        currentVehicle.service == 'dispatch' ? 'Courier: ${newRide.pickup} → ${newRide.dropoff}' : 'Ride: ${newRide.pickup} → ${newRide.dropoff}',
        tripCode: newRide.code,
        type: currentVehicle.service == 'dispatch' ? WalletTransactionType.courier : WalletTransactionType.ride,
      );
    }

    _refreshRides();
    _selectedRide = newRide;
    _subscribeToLiveRide(newRide.code);
    notifyListeners();
    return newRide;
  }

  void _subscribeToLiveRide(String code) {
    _liveRideSub?.cancel();
    _liveRideSub = null;
    _livePollTimer?.cancel();
    _livePollTimer = null;
    _fallbackDemoTimer?.cancel();
    _fallbackDemoTimer = null;

    void onUpdate(RideModel liveRide) {
      _selectedRide = liveRide;
      ridesRepo.updateRideModel(liveRide);
      _refreshRides();
      notifyListeners();

      if (liveRide.status == 'completed' || liveRide.status == 'cancelled') {
        _liveRideSub?.cancel();
        _liveRideSub = null;
        _livePollTimer?.cancel();
        _livePollTimer = null;
        _fallbackDemoTimer?.cancel();
        _fallbackDemoTimer = null;
        _liveTrackTimer?.cancel();
        _liveTrackTimer = null;
      }
    }

    // 1. Supabase Realtime Stream
    try {
      _liveRideSub = ridesRepo.dispatchService.streamRide(code).listen((live) {
        if (live != null) {
          onUpdate(live);
        }
      }, onError: (_) {});
    } catch (_) {}

    // 2. Fail-safe Periodic Poll
    _livePollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final remote = await ridesRepo.dispatchService.fetchRide(code);
      if (remote != null) {
        onUpdate(remote);
      }
    });

    // 3. Extended fallback demo simulation (120s) so 2 real devices have plenty of time
    _fallbackDemoTimer = Timer(const Duration(seconds: 120), () {
      if (_selectedRide != null && _selectedRide!.status == 'pending') {
        _startLiveTrackingSimulation();
      }
    });
  }

  /// Manually trigger demo simulation for solo testing
  void triggerDemoSimulation() {
    _fallbackDemoTimer?.cancel();
    _fallbackDemoTimer = null;
    _startLiveTrackingSimulation();
  }

  Future<bool> fundWallet(int amount, String method) async {
    final success = ridesRepo.fundWallet(amount, method);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  bool cancelRide(String code, {String reason = 'Passenger cancelled'}) {
    final success = ridesRepo.cancelRide(code, reason: reason);
    if (success) {
      ridesRepo.dispatchService.cancelRide(code);
      _liveRideSub?.cancel();
      _liveRideSub = null;
      _livePollTimer?.cancel();
      _livePollTimer = null;
      _fallbackDemoTimer?.cancel();
      _fallbackDemoTimer = null;
      _liveTrackTimer?.cancel();
      _liveTrackTimer = null;
      _selectedRide = ridesRepo.getRide(code);
      _refreshRides();
      notifyListeners();
    }
    return success;
  }

  void _startLiveTrackingSimulation() {
    _liveTrackTimer?.cancel();
    if (_selectedRide == null) return;

    const stages = ['pending', 'accepted', 'to_pickup', 'at_pickup', 'on_trip', 'completed'];
    final currentIdx = stages.indexOf(_selectedRide!.status);
    if (currentIdx >= stages.length - 1) return;

    _liveTrackTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_selectedRide == null) {
        timer.cancel();
        return;
      }
      final idx = stages.indexOf(_selectedRide!.status);
      if (idx < stages.length - 1) {
        final nextStatus = stages[idx + 1];
        var updated = _selectedRide!.copyWith(status: nextStatus);
        if (updated.driverName.isEmpty) {
          updated = updated.copyWith(
            driverName: 'Abdulmutallib Alasah',
            driverPlate: 'LAG-605-EK',
            driverVehicle: 'Toyota Corolla (White)',
            driverPhone: '+2348024419922',
            driverRating: 4.95,
          );
        }
        ridesRepo.updateRideModel(updated);
        ridesRepo.dispatchService.updateStatus(rideCode: updated.code, newStatus: nextStatus);
        _selectedRide = updated;
        _refreshRides();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _liveRideSub?.cancel();
    _livePollTimer?.cancel();
    _fallbackDemoTimer?.cancel();
    _liveTrackTimer?.cancel();
    super.dispose();
  }
}
