import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dogo_crew/core/constants/app_constants.dart';
import 'package:dogo_crew/core/utils/currency_formatter.dart';
import 'package:dogo_crew/data/models/trip_model.dart';
import 'package:dogo_crew/data/repositories/rides_repository.dart';
import 'package:dogo_crew/ui/features/rides/view_models/rides_view_model.dart';
import 'package:dogo_crew/ui/features/rides/widgets/dogo_wallet_modal.dart';
import 'package:dogo_crew/ui/features/rides/widgets/rides_header_widget.dart';

void main() {
  test('CurrencyFormatter formats Nigerian Naira correctly', () {
    expect(CurrencyFormatter.formatNaira(2500), '₦2,500');
    expect(CurrencyFormatter.formatNaira(0), '₦0');
    expect(CurrencyFormatter.formatNaira(150000), '₦150,000');
  });

  test('TripModel calculates driver and DOGO shares accurately', () {
    final trip = TripModel(
      id: 'test-1',
      code: 'DG-100',
      service: 'taxi',
      status: 'pending',
      customerName: 'Amina Bello',
      customerPhone: '08012345678',
      pickup: 'Victoria Island',
      dropoff: 'Ikeja',
      distanceKm: 10.0,
      fare: 2500,
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 70% to driver, 30% to DOGO
    expect(trip.driverShare, 1750);
    expect(trip.dogoShare, 750);
    expect(trip.driverShare + trip.dogoShare, 2500);
  });

  test('AppConstants service rates match expectations', () {
    expect(AppConstants.ratePerKm['taxi'], 250);
    expect(AppConstants.ratePerKm['keke'], 150);
    expect(AppConstants.ratePerKm['bike'], 200);
  });

  test('RidesRepository calculates distance, fare, and creates ride matching dogoui1', () {
    final repo = RidesRepository();
    // Distance between Ikeja GRA (0km) and Lekki Phase 1 (GPS ~20km)
    final distance = repo.calculateDistance('Lagos — Ikeja GRA', 'Lagos — Lekki Phase 1');
    expect(distance, 20);

    final taxi = RidesRepository.vehicles.firstWhere((v) => v.id == 'taxi');
    // base: 1800, perKm: 180 -> 1800 + 180 * 20 = 5400
    final fare = repo.calculateFare(taxi, distance);
    expect(fare, 5400);

    final newRide = repo.createRide(
      pickup: 'Lagos — Ikeja GRA',
      dropoff: 'Lagos — Lekki Phase 1',
      vehicle: taxi,
      payment: 'DOGO Wallet',
    );

    expect(newRide.code.startsWith('DG-'), isTrue);
    expect(newRide.pin.length, 4);
    expect(repo.getRide(newRide.code), isNotNull);
  });

  testWidgets('RidesHeaderWidget and DogoLogo render without overflow on narrow screens', (tester) async {
    // Simulate a 360x800 device with 1.08x text scaler (Samsung Galaxy A17)
    tester.view.physicalSize = const Size(360 * 2.8, 800 * 2.8);
    tester.view.devicePixelRatio = 2.8;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData().copyWith(
            size: const Size(360, 800),
            textScaler: const TextScaler.linear(1.08),
          ),
          child: const Scaffold(
            body: RidesHeaderWidget(activeRoute: '/rides'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Also test ultra-narrow 320px width device with 1.2x text scaler
    tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData().copyWith(
            size: const Size(320, 640),
            textScaler: const TextScaler.linear(1.2),
          ),
          child: const Scaffold(
            body: RidesHeaderWidget(activeRoute: '/rides'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  test('DOGO Wallet funds and deducts balance properly', () {
    final repo = RidesRepository();
    expect(repo.walletBalance, 184500);

    // Fund wallet
    final funded = repo.fundWallet(15000, 'Debit Card');
    expect(funded, isTrue);
    expect(repo.walletBalance, 199500);
    expect(repo.walletTransactions.first.title.contains('Debit Card'), isTrue);
    expect(repo.walletTransactions.first.amount, 15000);

    // Deduct wallet
    final deducted = repo.deductWallet(4500, 'Ride to Ikeja');
    expect(deducted, isTrue);
    expect(repo.walletBalance, 195000);
    expect(repo.walletTransactions.first.title, 'Ride to Ikeja');
    expect(repo.walletTransactions.first.isCredit, isFalse);
  });

  testWidgets('DogoWalletModal renders and supports top-up presets', (tester) async {
    final repo = RidesRepository();
    final vm = RidesViewModel(ridesRepo: repo);

    await tester.pumpWidget(
      ChangeNotifierProvider<RidesViewModel>.value(
        value: vm,
        child: const MaterialApp(
          home: Scaffold(
            body: DogoWalletModal(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('DOGO Wallet'), findsOneWidget);
    expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
    expect(find.text('Top up Wallet'), findsOneWidget);

    // Tap Top up wallet button
    await tester.tap(find.text('Top up Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Select or enter amount'), findsOneWidget);
    expect(find.text('Select Paystack Gateway'), findsOneWidget);
  });
}
