import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'google_maps_config.dart';
import 'location_service.dart';

class RoadRouteResult {
  final List<LatLng> coordinates;
  final double distanceKm;
  final int durationMinutes;
  final bool isRealRoad;

  const RoadRouteResult({
    required this.coordinates,
    required this.distanceKm,
    required this.durationMinutes,
    this.isRealRoad = true,
  });
}

/// Service that retrieves real road routing polylines following actual streets,
/// bridges, and highways.
///
/// Service that retrieves real road routing polylines following actual streets,
/// bridges, and highways.
///
/// Supports Google Maps Directions / Routes API when [googleMapsApiKey] is configured,
/// with automatic high-speed OSRM fallback and offline organic smoothing.
class RoadRoutingService {
  /// Optional Google Maps Directions / Routes API Key.
  /// When populated, requests route polylines via Google Maps Platform.
  /// If null or empty, defaults to OSRM (100% free, zero cost).
  static String? googleMapsApiKey;

  static final Map<String, RoadRouteResult> _cache = {};

  static String _cacheKey(LatLng start, LatLng end) {
    return '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}->'
        '${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}';
  }

  /// Calculates real road driving route between [start] and [end].
  ///
  /// CRITICAL EFFICIENCY RULE:
  /// Routes are cached in memory. Continuous driver tracking NEVER calls this
  /// function on live GPS ticks.
  static Future<RoadRouteResult> getDrivingRoute(LatLng start, LatLng end) async {
    // If start and end are identical or very close (< 20 meters), return single point
    final directDist = LocationService.calculateDistanceKm(start, end);
    if (directDist < 0.02) {
      return RoadRouteResult(
        coordinates: [start, end],
        distanceKm: 0.0,
        durationMinutes: 0,
        isRealRoad: false,
      );
    }

    final key = _cacheKey(start, end);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // 1. If Google Maps API Key is provided, try Google Directions API
    final activeKey = (googleMapsApiKey != null && googleMapsApiKey!.trim().isNotEmpty)
        ? googleMapsApiKey!.trim()
        : (GoogleMapsConfig.hasValidKey ? GoogleMapsConfig.apiKey.trim() : null);

    if (activeKey != null && activeKey.isNotEmpty) {
      try {
        final googleRoute = await _fetchFromGoogleDirections(start, end, activeKey);
        if (googleRoute != null) {
          _cache[key] = googleRoute;
          return googleRoute;
        }
      } catch (_) {
        // Fall through to OSRM on failure
      }
    }

    // 2. High-speed OSRM engine
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      // OSRM coordinates are in format: {longitude},{latitude}
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final req = await client.getUrl(url);
      req.headers.set('User-Agent', 'DOGO-Crew-Routing/1.0 (support@dogo.ng)');
      final resp = await req.close().timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;

        if (json['code'] == 'Ok' && json['routes'] != null && (json['routes'] as List).isNotEmpty) {
          final firstRoute = json['routes'][0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final rawCoords = geometry?['coordinates'] as List<dynamic>?;

          if (rawCoords != null && rawCoords.isNotEmpty) {
            final polylinePoints = <LatLng>[];
            for (final pair in rawCoords) {
              if (pair is List && pair.length >= 2) {
                final lng = (pair[0] as num).toDouble();
                final lat = (pair[1] as num).toDouble();
                polylinePoints.add(LatLng(lat, lng));
              }
            }

            final distMeters = (firstRoute['distance'] as num?)?.toDouble() ?? (directDist * 1000);
            final durationSecs = (firstRoute['duration'] as num?)?.toDouble() ?? (distMeters / 10);

            final result = RoadRouteResult(
              coordinates: polylinePoints,
              distanceKm: (distMeters / 1000 * 10).round() / 10,
              durationMinutes: math.max(1, (durationSecs / 60).round()),
              isRealRoad: true,
            );

            _cache[key] = result;
            client.close();
            return result;
          }
        }
      }
      client.close();
    } catch (_) {
      // In case of timeout or offline, fall back gracefully
    }

    // 3. Fallback: smooth interpolated curved path
    final fallback = _generateFallbackRoute(start, end);
    _cache[key] = fallback;
    return fallback;
  }

  /// Fetches real road polylines from Google Maps Directions API
  static Future<RoadRouteResult?> _fetchFromGoogleDirections(
    LatLng start,
    LatLng end,
    String apiKey,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${start.latitude},${start.longitude}'
      '&destination=${end.latitude},${end.longitude}'
      '&mode=driving'
      '&key=$apiKey',
    );

    final req = await client.getUrl(url);
    final resp = await req.close().timeout(const Duration(seconds: 5));

    if (resp.statusCode == 200) {
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json['status'] == 'OK' &&
          json['routes'] != null &&
          (json['routes'] as List).isNotEmpty) {
        final route = json['routes'][0] as Map<String, dynamic>;
        final overview = route['overview_polyline']?['points'] as String?;

        if (overview != null && overview.isNotEmpty) {
          final polylinePoints = _decodeGooglePolyline(overview);
          final legs = route['legs'] as List<dynamic>?;
          double distMeters = 0;
          int durationSecs = 0;

          if (legs != null && legs.isNotEmpty) {
            final leg = legs[0] as Map<String, dynamic>;
            distMeters = (leg['distance']?['value'] as num?)?.toDouble() ?? 0.0;
            durationSecs = (leg['duration']?['value'] as num?)?.toInt() ?? 0;
          }

          client.close();
          return RoadRouteResult(
            coordinates: polylinePoints,
            distanceKm: (distMeters / 1000 * 10).round() / 10,
            durationMinutes: math.max(1, (durationSecs / 60).round()),
            isRealRoad: true,
          );
        }
      }
    }
    client.close();
    return null;
  }

  /// Decodes a Google Maps encoded polyline string into coordinates
  static List<LatLng> _decodeGooglePolyline(String encoded) {
    final poly = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// Calculates driving route through multiple waypoints (e.g. Driver -> Pickup -> Dropoff)
  static Future<RoadRouteResult> getMultiPointRoute(List<LatLng> points) async {
    if (points.length < 2) {
      return RoadRouteResult(
        coordinates: points,
        distanceKm: 0,
        durationMinutes: 0,
        isRealRoad: false,
      );
    }

    if (points.length == 2) {
      return getDrivingRoute(points[0], points[1]);
    }

    final combinedCoordinates = <LatLng>[];
    double totalDistanceKm = 0.0;
    int totalMinutes = 0;

    for (int i = 0; i < points.length - 1; i++) {
      final leg = await getDrivingRoute(points[i], points[i + 1]);
      if (i > 0 && combinedCoordinates.isNotEmpty && leg.coordinates.isNotEmpty) {
        // Skip duplicate connecting point
        combinedCoordinates.addAll(leg.coordinates.skip(1));
      } else {
        combinedCoordinates.addAll(leg.coordinates);
      }
      totalDistanceKm += leg.distanceKm;
      totalMinutes += leg.durationMinutes;
    }

    return RoadRouteResult(
      coordinates: combinedCoordinates,
      distanceKm: (totalDistanceKm * 10).round() / 10,
      durationMinutes: totalMinutes,
      isRealRoad: true,
    );
  }

  /// Calculates compass bearing heading (0 - 360 degrees) between two points
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final rad = math.atan2(y, x);
    final deg = rad * (180.0 / math.pi);
    return (deg + 360.0) % 360.0;
  }

  /// Offline fallback with organic road curvature
  static RoadRouteResult _generateFallbackRoute(LatLng start, LatLng end, {int steps = 40}) {
    final points = <LatLng>[];
    final distKm = LocationService.calculateDistanceKm(start, end);

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      // Slight organic curvature
      final curve = 0.0025 * math.sin(t * math.pi);
      points.add(LatLng(lat + curve, lng - curve));
    }

    return RoadRouteResult(
      coordinates: points,
      distanceKm: distKm,
      durationMinutes: math.max(1, (distKm * 2.2).round()),
      isRealRoad: false,
    );
  }
}

