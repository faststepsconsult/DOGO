import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'google_maps_config.dart';

class LocationPlace {
  final String title;
  final String subtitle;
  final LatLng coordinates;
  final bool isGps;
  final String? placeId;
  final bool isGooglePlace;

  const LocationPlace({
    required this.title,
    required this.subtitle,
    required this.coordinates,
    this.isGps = false,
    this.placeId,
    this.isGooglePlace = false,
  });

  String get displayName => subtitle.isNotEmpty ? '$title, $subtitle' : title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPlace &&
          runtimeType == other.runtimeType &&
          title.toLowerCase() == other.title.toLowerCase() &&
          subtitle.toLowerCase() == other.subtitle.toLowerCase();

  @override
  int get hashCode => title.toLowerCase().hashCode ^ subtitle.toLowerCase().hashCode;
}

class LocationService {
  // Default coordinates: Lagos, Nigeria (Ikeja GRA)
  static const LatLng defaultLocation = LatLng(6.5898, 3.3556);

  static const List<LocationPlace> predefinedPlaces = [
    LocationPlace(
      title: 'Lagos — Ikeja GRA',
      subtitle: 'Ikeja, Lagos State',
      coordinates: LatLng(6.5898, 3.3556),
    ),
    LocationPlace(
      title: 'Lagos — Lekki Phase 1',
      subtitle: 'Eti-Osa, Lagos State',
      coordinates: LatLng(6.4474, 3.4739),
    ),
    LocationPlace(
      title: 'Victoria Island (VI)',
      subtitle: 'Lagos Island, Lagos State',
      coordinates: LatLng(6.4281, 3.4219),
    ),
    LocationPlace(
      title: 'Lagos — Yaba',
      subtitle: 'Akoka / Tech Hub, Lagos State',
      coordinates: LatLng(6.5095, 3.3711),
    ),
    LocationPlace(
      title: 'Murtala Muhammed Airport (MMA2)',
      subtitle: 'Ikeja, Lagos State',
      coordinates: LatLng(6.5774, 3.3212),
    ),
    LocationPlace(
      title: 'Maryland Mall',
      subtitle: 'Ikorodu Road, Lagos State',
      coordinates: LatLng(6.5701, 3.3666),
    ),
    LocationPlace(
      title: 'Surulere — Adeniran Ogunsanya',
      subtitle: 'Lagos Mainland, Lagos State',
      coordinates: LatLng(6.4969, 3.3558),
    ),
    LocationPlace(
      title: 'Ikoyi — Bourdillon Road',
      subtitle: 'Ikoyi, Lagos State',
      coordinates: LatLng(6.4549, 3.4350),
    ),
    LocationPlace(
      title: 'Ajah — Jubilee Bridge',
      subtitle: 'Lekki-Epe Expressway, Lagos State',
      coordinates: LatLng(6.4698, 3.5852),
    ),
    LocationPlace(
      title: 'Oshodi Transport Interchange',
      subtitle: 'Oshodi-Isolo, Lagos State',
      coordinates: LatLng(6.5367, 3.3524),
    ),
    LocationPlace(
      title: 'Allen Avenue',
      subtitle: 'Ikeja, Lagos State',
      coordinates: LatLng(6.6018, 3.3515),
    ),
    LocationPlace(
      title: 'Magodo Phase 2',
      subtitle: 'Kosofe, Lagos State',
      coordinates: LatLng(6.6202, 3.3812),
    ),
    LocationPlace(
      title: 'Festac Town',
      subtitle: 'Amuwo-Odofin, Lagos State',
      coordinates: LatLng(6.4678, 3.2833),
    ),
    LocationPlace(
      title: 'Abuja — Wuse 2',
      subtitle: 'Abuja FCT',
      coordinates: LatLng(9.0765, 7.4735),
    ),
    LocationPlace(
      title: 'Abuja — Maitama',
      subtitle: 'Abuja FCT',
      coordinates: LatLng(9.0882, 7.4933),
    ),
    LocationPlace(
      title: 'Abuja — Central Business District',
      subtitle: 'Abuja FCT',
      coordinates: LatLng(9.0579, 7.4951),
    ),
    LocationPlace(
      title: 'Nnamdi Azikiwe Int. Airport',
      subtitle: 'Abuja FCT',
      coordinates: LatLng(9.0065, 7.2631),
    ),
    LocationPlace(
      title: 'Ibadan — Bodija',
      subtitle: 'Ibadan, Oyo State',
      coordinates: LatLng(7.4243, 3.9059),
    ),
    LocationPlace(
      title: 'Ibadan — Ring Road',
      subtitle: 'Ibadan, Oyo State',
      coordinates: LatLng(7.3621, 3.8614),
    ),
    LocationPlace(
      title: 'Port Harcourt — GRA Phase 2',
      subtitle: 'Port Harcourt, Rivers State',
      coordinates: LatLng(4.8156, 7.0498),
    ),
    LocationPlace(
      title: 'Kano — Nassarawa',
      subtitle: 'Kano State',
      coordinates: LatLng(11.9964, 8.5167),
    ),
    LocationPlace(
      title: 'Benin City — Ugbowo',
      subtitle: 'Benin City, Edo State',
      coordinates: LatLng(6.3986, 5.6139),
    ),
  ];

  static const Map<String, LatLng> cityCoordinates = {
    'Lagos — Ikeja GRA': LatLng(6.5898, 3.3556),
    'Lagos — Lekki Phase 1': LatLng(6.4474, 3.4739),
    'Lagos — Yaba': LatLng(6.5095, 3.3711),
    'Ibadan — Bodija': LatLng(7.4243, 3.9059),
    'Abuja — Wuse 2': LatLng(9.0765, 7.4735),
    'Port Harcourt — GRA Phase 2': LatLng(4.8156, 7.0498),
    'Kano — Nassarawa': LatLng(11.9964, 8.5167),
    'Benin City — Ugbowo': LatLng(6.3986, 5.6139),
    'Victoria Island': LatLng(6.4281, 3.4219),
    'Maryland Mall, Ikorodu Road': LatLng(6.5701, 3.3666),
    'Murtala Muhammed Airport, Ikeja': LatLng(6.5774, 3.3212),
    'Surulere': LatLng(6.4969, 3.3558),
  };

  /// Returns real LatLng coordinates for a given address/city label
  static LatLng getCoordinates(String address) {
    final lower = address.toLowerCase();

    // Check predefined places
    for (final p in predefinedPlaces) {
      if (lower.contains(p.title.toLowerCase()) || p.title.toLowerCase().contains(lower)) {
        return p.coordinates;
      }
    }

    for (final entry in cityCoordinates.entries) {
      if (lower.contains(entry.key.toLowerCase()) || entry.key.toLowerCase().contains(lower)) {
        return entry.value;
      }
    }

    // Partial substring matching
    if (lower.contains('lekki')) return const LatLng(6.4474, 3.4739);
    if (lower.contains('ikeja') || lower.contains('opebi') || lower.contains('allen')) return const LatLng(6.5898, 3.3556);
    if (lower.contains('yaba') || lower.contains('akoka')) return const LatLng(6.5095, 3.3711);
    if (lower.contains('victoria island') || lower.contains('vi') || lower.contains('victoria')) return const LatLng(6.4281, 3.4219);
    if (lower.contains('ikoyi') || lower.contains('banana')) return const LatLng(6.4549, 3.4350);
    if (lower.contains('airport') || lower.contains('mma2')) return const LatLng(6.5774, 3.3212);
    if (lower.contains('abuja') || lower.contains('wuse') || lower.contains('maitama')) return const LatLng(9.0765, 7.4735);
    if (lower.contains('ibadan') || lower.contains('bodija')) return const LatLng(7.4243, 3.9059);
    if (lower.contains('port harcourt') || lower.contains('ph')) return const LatLng(4.8156, 7.0498);
    if (lower.contains('kano')) return const LatLng(11.9964, 8.5167);
    if (lower.contains('benin')) return const LatLng(6.3986, 5.6139);

    return defaultLocation;
  }

  /// Request and verify device location permission
  static Future<bool> handleLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gets current device GPS position with graceful fallback
  static Future<LatLng> getCurrentLocation() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (hasPermission) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return LatLng(lastKnown.latitude, lastKnown.longitude);
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      // Fallback
    }
    return defaultLocation;
  }

  static final Map<String, LatLng> _placeDetailsCache = {};

  /// Reverse geocode GPS coordinates to a human-readable Nigerian place name
  static Future<LocationPlace> reverseGeocode(LatLng pos) async {
    // 1. Try Google Geocoding API if key configured
    if (GoogleMapsConfig.hasValidKey) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${pos.latitude},${pos.longitude}&key=${GoogleMapsConfig.apiKey}',
        );
        final req = await client.getUrl(url);
        final resp = await req.close().timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;

          if (json['status'] == 'OK' &&
              json['results'] != null &&
              (json['results'] as List).isNotEmpty) {
            final first = json['results'][0] as Map<String, dynamic>;
            final formatted = first['formatted_address'] as String? ?? 'Current Location';
            final components = first['address_components'] as List<dynamic>? ?? [];

            String title = '';
            String subtitle = 'Nigeria';

            for (final comp in components) {
              final types = (comp['types'] as List<dynamic>?) ?? [];
              if (types.contains('point_of_interest') ||
                  types.contains('establishment') ||
                  types.contains('route') ||
                  types.contains('neighborhood') ||
                  types.contains('sublocality')) {
                if (title.isEmpty) title = comp['long_name']?.toString() ?? '';
              }
              if (types.contains('administrative_area_level_1') || types.contains('locality')) {
                subtitle = comp['long_name']?.toString() ?? subtitle;
              }
            }

            if (title.isEmpty) {
              title = formatted.split(',').first.trim();
            }

            client.close();
            return LocationPlace(
              title: title,
              subtitle: subtitle,
              coordinates: pos,
              isGps: true,
              isGooglePlace: true,
            );
          }
        }
        client.close();
      } catch (_) {}
    }

    // 2. Try Nominatim reverse API with 3.5s timeout
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&addressdetails=1',
      );
      final req = await client.getUrl(url);
      req.headers.set('User-Agent', 'DOGO-Crew-App/1.0 (support@dogo.ng)');
      final resp = await req.close().timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final address = json['address'] as Map<String, dynamic>? ?? {};

        // Extract clean primary title
        final primary = address['suburb'] ??
            address['neighbourhood'] ??
            address['road'] ??
            address['quarter'] ??
            address['amenity'] ??
            json['name'] ??
            'Current Location';

        // Extract clean secondary subtitle
        final secondary = address['city'] ??
            address['state_district'] ??
            address['county'] ??
            address['state'] ??
            'Nigeria';

        client.close();
        return LocationPlace(
          title: primary.toString(),
          subtitle: secondary.toString(),
          coordinates: pos,
          isGps: true,
        );
      }
      client.close();
    } catch (_) {
      // Network or timeout: fallback
    }

    // 3. Offline fallback: find closest predefined place
    LocationPlace? closest;
    double minDistance = double.infinity;
    for (final p in predefinedPlaces) {
      final d = calculateDistanceKm(pos, p.coordinates);
      if (d < minDistance) {
        minDistance = d;
        closest = p;
      }
    }

    if (closest != null && minDistance < 5.0) {
      return LocationPlace(
        title: 'Near ${closest.title}',
        subtitle: closest.subtitle,
        coordinates: pos,
        isGps: true,
      );
    }

    return LocationPlace(
      title: 'Current GPS Location',
      subtitle: '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
      coordinates: pos,
      isGps: true,
    );
  }

  /// Resolves the exact LatLng coordinates for a Google Places prediction
  static Future<LocationPlace> resolvePlaceCoordinates(LocationPlace place) async {
    if (!place.isGooglePlace || place.placeId == null) {
      return place;
    }

    final placeId = place.placeId!;
    if (_placeDetailsCache.containsKey(placeId)) {
      return LocationPlace(
        title: place.title,
        subtitle: place.subtitle,
        coordinates: _placeDetailsCache[placeId]!,
        placeId: placeId,
        isGooglePlace: true,
      );
    }

    if (GoogleMapsConfig.hasValidKey) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?'
          'place_id=$placeId&fields=geometry,name,formatted_address&key=${GoogleMapsConfig.apiKey}',
        );
        final req = await client.getUrl(url);
        final resp = await req.close().timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;

          if (json['status'] == 'OK' && json['result'] != null) {
            final loc = json['result']['geometry']?['location'] as Map<String, dynamic>?;
            final lat = (loc?['lat'] as num?)?.toDouble();
            final lng = (loc?['lng'] as num?)?.toDouble();

            if (lat != null && lng != null) {
              final coord = LatLng(lat, lng);
              _placeDetailsCache[placeId] = coord;
              client.close();
              return LocationPlace(
                title: place.title,
                subtitle: place.subtitle,
                coordinates: coord,
                placeId: placeId,
                isGooglePlace: true,
              );
            }
          }
        }
        client.close();
      } catch (_) {}
    }

    // Fallback: estimate from address text
    final fallbackCoord = getCoordinates('${place.title} ${place.subtitle}');
    return LocationPlace(
      title: place.title,
      subtitle: place.subtitle,
      coordinates: fallbackCoord,
      placeId: placeId,
      isGooglePlace: true,
    );
  }

  /// Search locations with instant local filtering + Google Places Autocomplete + OpenStreetMap Nominatim
  static Future<List<LocationPlace>> searchLocations(String query) async {
    final cleanQuery = query.trim().toLowerCase();

    // Default suggestions when query is empty
    if (cleanQuery.isEmpty) {
      return predefinedPlaces.take(8).toList();
    }

    final results = <LocationPlace>[];

    // 1. Instant local matches (0ms latency, works offline)
    for (final p in predefinedPlaces) {
      if (p.title.toLowerCase().contains(cleanQuery) ||
          p.subtitle.toLowerCase().contains(cleanQuery)) {
        results.add(p);
      }
    }

    // 2. Query Google Places Autocomplete API (Restricted to Nigeria: components=country:ng)
    if (GoogleMapsConfig.hasValidKey) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=${Uri.encodeComponent(query)}'
          '&components=country:ng'
          '&language=en'
          '&key=${GoogleMapsConfig.apiKey}',
        );
        final req = await client.getUrl(url);
        final resp = await req.close().timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final body = await resp.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;

          if (json['status'] == 'OK' && json['predictions'] != null) {
            final predictions = json['predictions'] as List<dynamic>;

            for (final item in predictions) {
              final placeId = item['place_id'] as String?;
              final formatting = item['structured_formatting'] as Map<String, dynamic>?;
              final mainText = formatting?['main_text'] as String? ?? item['description'] as String? ?? '';
              final secondaryText = formatting?['secondary_text'] as String? ?? 'Nigeria';

              if (mainText.isEmpty) continue;

              final googlePlace = LocationPlace(
                title: mainText,
                subtitle: secondaryText,
                coordinates: getCoordinates(mainText),
                placeId: placeId,
                isGooglePlace: true,
              );

              if (!results.any((r) => r.title.toLowerCase() == googlePlace.title.toLowerCase())) {
                results.add(googlePlace);
              }
            }

            if (results.isNotEmpty) {
              client.close();
              return results;
            }
          }
        }
        client.close();
      } catch (_) {
        // Fall through to Nominatim
      }
    }

    // 3. Query OpenStreetMap Nominatim for Nigeria (Fallback)
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=ng&addressdetails=1&limit=6',
      );
      final req = await client.getUrl(url);
      req.headers.set('User-Agent', 'DOGO-Crew-App/1.0 (support@dogo.ng)');
      final resp = await req.close().timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;

        for (final item in list) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final address = (item['address'] as Map<String, dynamic>?) ?? {};
          final name = item['name']?.toString() ?? '';
          final displayName = item['display_name']?.toString() ?? '';

          String title = name.isNotEmpty ? name : displayName.split(',').first.trim();
          String subtitle = '';
          final parts = displayName.split(',').map((e) => e.trim()).toList();
          if (parts.length > 1) {
            subtitle = parts.sublist(1, parts.length > 3 ? 3 : parts.length).join(', ');
          } else {
            subtitle = address['state']?.toString() ?? 'Nigeria';
          }

          final place = LocationPlace(
            title: title,
            subtitle: subtitle,
            coordinates: LatLng(lat, lon),
          );

          if (!results.any((r) => r.title.toLowerCase() == place.title.toLowerCase())) {
            results.add(place);
          }
        }
      }
      client.close();
    } catch (_) {
      // Graceful fallback to local matches
    }

    return results;
  }

  /// Continuous GPS stream for driver navigation
  static Stream<LatLng> getLivePositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).map((pos) => LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Computes real distance in kilometers between two GPS points
  static double calculateDistanceKm(LatLng start, LatLng end) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }
}
