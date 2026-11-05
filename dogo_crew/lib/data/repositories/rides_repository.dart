import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ride_model.dart';
import '../models/wallet_transaction_model.dart';
import '../services/location_service.dart';
import '../services/rides_dispatch_service.dart';

class CityLocation {
  final String name;
  final int km;
  final double x;
  final double y;

  const CityLocation({
    required this.name,
    required this.km,
    this.x = 0,
    this.y = 0,
  });
}

class VehicleOption {
  final String id;
  final String name;
  final String capacity;
  final String eta;
  final int base;
  final int perKm;
  final String icon;
  final String service; // 'ride' or 'dispatch'

  const VehicleOption({
    required this.id,
    required this.name,
    required this.capacity,
    required this.eta,
    required this.base,
    required this.perKm,
    required this.icon,
    required this.service,
  });
}

class PaymentMethodOption {
  final String id;
  final String label;
  final String hint;

  const PaymentMethodOption({
    required this.id,
    required this.label,
    required this.hint,
  });
}

class RidesRepository {
  static const List<CityLocation> cities = [
    CityLocation(name: 'Lagos — Ikeja GRA', km: 0, x: 0.1, y: 0.8),
    CityLocation(name: 'Lagos — Lekki Phase 1', km: 24, x: 0.85, y: 0.2),
    CityLocation(name: 'Lagos — Yaba', km: 12, x: 0.35, y: 0.55),
    CityLocation(name: 'Ibadan — Bodija', km: 128, x: 0.5, y: 0.4),
    CityLocation(name: 'Abuja — Wuse 2', km: 712, x: 0.7, y: 0.3),
    CityLocation(name: 'Port Harcourt — GRA Phase 2', km: 608, x: 0.6, y: 0.7),
    CityLocation(name: 'Kano — Nassarawa', km: 986, x: 0.75, y: 0.15),
    CityLocation(name: 'Benin City — Ugbowo', km: 312, x: 0.4, y: 0.65),
  ];

  static const List<VehicleOption> vehicles = [
    VehicleOption(
      id: 'taxi',
      name: 'Taxi (Car)',
      capacity: 'Up to 4 passengers',
      eta: '5 min away',
      base: 1800,
      perKm: 180,
      icon: '🚕',
      service: 'ride',
    ),
    VehicleOption(
      id: 'tricycle',
      name: 'Tricycle (Keke napep)',
      capacity: 'Up to 3 passengers',
      eta: '9 min away',
      base: 2100,
      perKm: 140,
      icon: '🛺',
      service: 'ride',
    ),
    VehicleOption(
      id: 'bike',
      name: 'Bike Dispatcher',
      capacity: 'Parcels up to 15 kg',
      eta: '6 min away',
      base: 1200,
      perKm: 95,
      icon: '🏍️',
      service: 'dispatch',
    ),
  ];

  static const List<PaymentMethodOption> paymentMethods = [
    PaymentMethodOption(id: 'wallet', label: 'DOGO Wallet', hint: 'Instant 1-tap Paystack balance'),
    PaymentMethodOption(id: 'card', label: 'Paystack Direct', hint: 'Debit Card • Bank Transfer • USSD'),
  ];

  final List<RideModel> _rides = [
    RideModel(
      code: 'DG-4821HK',
      pickup: 'Lagos — Ikeja GRA',
      dropoff: 'Lagos — Lekki Phase 1',
      vehicleId: 'bike',
      vehicleName: 'Bike Dispatcher',
      packageType: 'Documents & Parcel',
      weight: 2,
      recipientName: 'Chidinma Okoro',
      recipientPhone: '+234 802 441 9922',
      itemLabel: 'Contract Papers',
      payment: 'DOGO Wallet',
      price: 3480,
      distanceKm: 24,
      pin: '4193',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      service: 'courier',
      status: 'picked_up',
      driverName: 'Tunde Oyelaran',
      driverPlate: 'LAG-472-XA',
      driverRating: 4.88,
      driverTrips: 1284,
      driverPhone: '+2348024419922',
    ),
    RideModel(
      code: 'DG-7710QP',
      pickup: 'Lagos — Yaba',
      dropoff: 'Ibadan — Bodija',
      vehicleId: 'taxi',
      vehicleName: 'Taxi (Car)',
      packageType: 'Ride',
      recipientName: 'Musa Bello',
      recipientPhone: '+234 703 118 4470',
      payment: 'Fiat Card',
      price: 6450,
      distanceKm: 28,
      pin: '8025',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      service: 'ride',
      status: 'confirmed',
      driverName: 'Emeka Nwosu',
      driverPlate: 'LAG-891-AB',
      driverRating: 4.95,
      driverTrips: 2140,
      driverPhone: '+2348033221144',
    ),
  ];

  static const String _keyWalletBalance = 'dogo_wallet_balance_v1';
  static const String _keyTransactions = 'dogo_wallet_txs_v1';
  static const String _keySettledTrips = 'dogo_settled_trips_v1';

  int _walletBalance = 184500;
  int get walletBalance => _walletBalance;
  bool _walletInitialized = false;
  final Set<String> _settledTripCodes = {};

  final List<WalletTransactionModel> _transactions = [
    WalletTransactionModel(
      id: 'TX-9481',
      title: 'Top-up via Card (Visa)',
      amount: 50000,
      isCredit: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      method: 'Visa •••• 4242',
      type: WalletTransactionType.topup,
    ),
    WalletTransactionModel(
      id: 'TX-9420',
      title: 'Bike Courier (DG-4821HK)',
      amount: 3480,
      isCredit: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      method: 'DOGO Wallet',
      tripCode: 'DG-4821HK',
      type: WalletTransactionType.courier,
    ),
    WalletTransactionModel(
      id: 'TX-9102',
      title: 'Bank Transfer Top-up',
      amount: 150000,
      isCredit: true,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      method: 'Direct Bank Deposit',
      type: WalletTransactionType.topup,
    ),
    WalletTransactionModel(
      id: 'TX-8831',
      title: 'Ride to Bodija (DG-7710QP)',
      amount: 6450,
      isCredit: false,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      method: 'DOGO Wallet',
      tripCode: 'DG-7710QP',
      type: WalletTransactionType.ride,
    ),
  ];

  List<WalletTransactionModel> get walletTransactions => List.unmodifiable(_transactions);

  /// Initializes passenger wallet from local persistent storage (SharedPreferences)
  Future<void> initWallet() async {
    if (_walletInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyWalletBalance)) {
        _walletBalance = prefs.getInt(_keyWalletBalance) ?? 184500;
      } else {
        await prefs.setInt(_keyWalletBalance, _walletBalance);
      }

      final savedTxs = prefs.getStringList(_keyTransactions);
      if (savedTxs != null && savedTxs.isNotEmpty) {
        _transactions.clear();
        for (final raw in savedTxs) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            _transactions.add(WalletTransactionModel.fromJson(map));
          } catch (_) {}
        }
      } else {
        await _saveTransactionsToStorage(prefs);
      }

      final settledList = prefs.getStringList(_keySettledTrips);
      if (settledList != null) {
        _settledTripCodes.addAll(settledList);
      }
    } catch (_) {}
    _walletInitialized = true;
  }

  Future<void> _saveWalletToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyWalletBalance, _walletBalance);
      await _saveTransactionsToStorage(prefs);
    } catch (_) {}
  }

  Future<void> _saveTransactionsToStorage(SharedPreferences prefs) async {
    try {
      final list = _transactions.map((tx) => jsonEncode(tx.toJson())).toList();
      await prefs.setStringList(_keyTransactions, list);
    } catch (_) {}
  }

  bool fundWallet(int amount, String method) {
    if (amount <= 0) return false;
    _walletBalance += amount;
    final random = Random();
    final txId = 'TX-${1000 + random.nextInt(9000)}';
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: txId,
        title: 'Wallet Top-up ($method)',
        amount: amount,
        isCredit: true,
        timestamp: DateTime.now(),
        method: method,
        type: WalletTransactionType.topup,
      ),
    );
    _saveWalletToStorage();
    return true;
  }

  bool deductWallet(
    int amount,
    String title, {
    String? tripCode,
    WalletTransactionType type = WalletTransactionType.ride,
  }) {
    if (_walletBalance < amount) return false;
    _walletBalance -= amount;
    final random = Random();
    final txId = 'TX-${1000 + random.nextInt(9000)}';
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: txId,
        title: title,
        amount: amount,
        isCredit: false,
        timestamp: DateTime.now(),
        method: 'DOGO Wallet',
        tripCode: tripCode,
        type: type,
      ),
    );
    _saveWalletToStorage();
    return true;
  }

  /// Automatically executes trip fare settlement when a trip completes.
  /// If paid via DOGO Wallet, deducts the fare if not already deducted and logs the transaction.
  Future<bool> settleTripFare({
    required String tripCode,
    required int fare,
    required String paymentMethod,
    required String routeTitle,
  }) async {
    if (_settledTripCodes.contains(tripCode)) {
      return true; // Idempotent: already settled
    }

    _settledTripCodes.add(tripCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keySettledTrips, _settledTripCodes.toList());
    } catch (_) {}

    final isWallet = paymentMethod.toLowerCase().contains('wallet');
    final alreadyDeducted = _transactions.any((tx) => tx.tripCode == tripCode && !tx.isCredit);

    if (isWallet && !alreadyDeducted) {
      _walletBalance = max(0, _walletBalance - fare);
      final random = Random();
      final txId = 'TX-${1000 + random.nextInt(9000)}';
      _transactions.insert(
        0,
        WalletTransactionModel(
          id: txId,
          title: 'Trip Settlement: $routeTitle',
          amount: fare,
          isCredit: false,
          timestamp: DateTime.now(),
          method: 'DOGO Wallet',
          tripCode: tripCode,
          type: WalletTransactionType.ride,
        ),
      );
      await _saveWalletToStorage();
    }
    return true;
  }

  /// Passenger tips driver in real-time. Debits passenger wallet and broadcasts to driver over Supabase.
  Future<bool> tipDriver({
    required String tripCode,
    required int amount,
    required String driverName,
    String passengerName = 'Salim Bello',
  }) async {
    if (amount <= 0 || _walletBalance < amount) return false;
    _walletBalance -= amount;
    final random = Random();
    final txId = 'TX-${1000 + random.nextInt(9000)}';
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: txId,
        title: 'Tip to Captain $driverName ($tripCode)',
        amount: amount,
        isCredit: false,
        timestamp: DateTime.now(),
        method: 'DOGO Wallet',
        tripCode: tripCode,
        type: WalletTransactionType.tip,
      ),
    );
    await _saveWalletToStorage();

    // Broadcast tip in real-time to driver's device
    await dispatchService.broadcastTip(
      rideCode: tripCode,
      tipAmount: amount,
      passengerName: passengerName,
    );
    return true;
  }

  final RidesDispatchService dispatchService = RidesDispatchService();

  List<RideModel> get allRides => List.unmodifiable(_rides);
  List<RideModel> get recentRides => List.unmodifiable(_rides.take(4).toList());

  void updateRideModel(RideModel updated) {
    final index = _rides.indexWhere((r) => r.code == updated.code);
    if (index != -1) {
      _rides[index] = updated;
    } else {
      _rides.insert(0, updated);
    }
  }

  RideModel? getRide(String code) {
    try {
      return _rides.firstWhere((r) => r.code == code);
    } catch (_) {
      return null;
    }
  }

  int calculateDistance(String fromCity, String toCity, {LatLng? fromCoord, LatLng? toCoord}) {
    final start = fromCoord ?? LocationService.getCoordinates(fromCity);
    final end = toCoord ?? LocationService.getCoordinates(toCity);
    final km = LocationService.calculateDistanceKm(start, end);
    if (km > 0.5) {
      return max(2, km.round());
    }
    final from = cities.where((c) => c.name == fromCity).firstOrNull?.km;
    final to = cities.where((c) => c.name == toCity).firstOrNull?.km;
    if (from == null || to == null) return 18;
    final diff = (to - from).abs();
    return max(5, diff);
  }

  int calculateFare(VehicleOption vehicle, int distanceKm) {
    final raw = vehicle.base + (vehicle.perKm * distanceKm);
    return (raw / 10).round() * 10;
  }

  String generateTripCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    final random = Random();
    final digits = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'DG-$digits';
  }

  String generatePin() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  RideModel createRide({
    required String pickup,
    required String dropoff,
    required VehicleOption vehicle,
    required String payment,
    String? scheduledAt,
    String passengerName = 'Salim Bello',
    String passengerPhone = '+2348031234567',
    String recipientName = '',
    String recipientPhone = '',
    String? itemLabel,
    LatLng? pickupCoord,
    LatLng? dropoffCoord,
  }) {
    final pCoord = pickupCoord ?? LocationService.getCoordinates(pickup);
    final dCoord = dropoffCoord ?? LocationService.getCoordinates(dropoff);
    final distance = calculateDistance(pickup, dropoff, fromCoord: pCoord, toCoord: dCoord);
    final price = calculateFare(vehicle, distance);
    final isDispatch = vehicle.service == 'dispatch';
    final tripCode = generateTripCode();

    final newRide = RideModel(
      code: tripCode,
      pickup: pickup,
      dropoff: dropoff,
      pickupLat: pCoord.latitude,
      pickupLng: pCoord.longitude,
      dropoffLat: dCoord.latitude,
      dropoffLng: dCoord.longitude,
      vehicleId: vehicle.id,
      vehicleName: vehicle.name,
      packageType: isDispatch ? (itemLabel ?? 'Parcel') : 'Ride',
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      itemLabel: itemLabel,
      payment: payment,
      price: price,
      distanceKm: distance,
      pin: RideModel.derivePinFromCode(tripCode),
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      service: isDispatch ? 'courier' : 'ride',
      speed: scheduledAt != null ? 'scheduled' : 'casual',
      status: 'pending',
      driverName: '',
      driverPlate: '',
      driverVehicle: '',
      driverRating: 4.9,
      driverTrips: 1450,
      driverPhone: '',
    );

    _rides.insert(0, newRide);
    // Broadcast ride to Supabase in real-time
    dispatchService.createRideRequest(newRide);
    return newRide;
  }

  void updateStatus(String code, String newStatus) {
    final index = _rides.indexWhere((r) => r.code == code);
    if (index != -1) {
      _rides[index] = _rides[index].copyWith(status: newStatus);
    }
  }

  bool cancelRide(String code, {String reason = 'Passenger requested cancellation'}) {
    final index = _rides.indexWhere((r) => r.code == code);
    if (index != -1) {
      final ride = _rides[index];
      _rides[index] = ride.copyWith(status: 'cancelled');
      if (ride.payment.toLowerCase().contains('wallet')) {
        fundWallet(ride.price, 'Refund: Cancelled trip ${ride.code}');
      }
      return true;
    }
    return false;
  }
}
