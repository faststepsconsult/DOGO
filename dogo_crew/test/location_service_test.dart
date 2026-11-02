import 'package:flutter_test/flutter_test.dart';
import 'package:dogo_crew/data/services/google_maps_config.dart';
import 'package:dogo_crew/data/services/location_service.dart';

void main() {
  group('GoogleMapsConfig Tests', () {
    test('Default configuration detects invalid/empty key', () {
      GoogleMapsConfig.apiKey = '';
      GoogleMapsConfig.forceGoogleMaps = false;
      expect(GoogleMapsConfig.hasValidKey, isFalse);
      expect(GoogleMapsConfig.shouldUseGoogleMaps, isFalse);
    });

    test('Valid key activates Google Maps SDK', () {
      GoogleMapsConfig.apiKey = 'AIzaSyActualKeyForProduction1234567890';
      expect(GoogleMapsConfig.hasValidKey, isTrue);
      expect(GoogleMapsConfig.shouldUseGoogleMaps, isTrue);
      GoogleMapsConfig.apiKey = ''; // Reset
    });
  });

  group('LocationService Tests', () {
    test('searchLocations returns instant local matches', () async {
      final results = await LocationService.searchLocations('ikeja');
      expect(results, isNotEmpty);
      expect(results.any((p) => p.title.toLowerCase().contains('ikeja')), isTrue);
    });

    test('getCoordinates returns default or city coordinates correctly', () {
      final coord = LocationService.getCoordinates('Lagos — Lekki Phase 1');
      expect(coord.latitude, closeTo(6.4474, 0.01));
      expect(coord.longitude, closeTo(3.4739, 0.01));
    });
  });
}
