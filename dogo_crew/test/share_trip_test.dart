import 'package:flutter_test/flutter_test.dart';
import 'package:dogo_crew/data/models/ride_model.dart';
import 'package:dogo_crew/ui/features/rides/widgets/share_trip_modal.dart';

void main() {
  group('ShareTripModal Tests', () {
    test('generateShareText formats captain, vehicle, route, and live link', () {
      final ride = RideModel(
        code: 'DG-7821',
        pickup: 'Ikeja GRA, Lagos',
        dropoff: 'Victoria Island, Lagos',
        vehicleId: 'taxi',
        vehicleName: 'Toyota Corolla (Silver)',
        payment: 'wallet',
        price: 5200,
        distanceKm: 18,
        pin: '4912',
        createdAt: DateTime.now(),
        status: 'on_trip',
        driverName: 'Captain Babatunde',
        driverPhone: '+2348031122334',
        driverPlate: 'KJA-892-AB',
        driverVehicle: 'Toyota Corolla (Silver)',
      );

      final text = ShareTripModal.generateShareText(ride);

      // Verify essential security and tracking details are included
      expect(text, contains('Ikeja GRA, Lagos'));
      expect(text, contains('Victoria Island, Lagos'));
      expect(text, contains('Captain Babatunde'));
      expect(text, contains('+2348031122334'));
      expect(text, contains('Toyota Corolla (Silver)'));
      expect(text, contains('KJA-892-AB'));
      expect(text, contains('DG-7821'));
      expect(text, contains('https://dogo.ng/track/DG-7821'));
      expect(text, contains('Trip in Progress'));
    });
  });
}

