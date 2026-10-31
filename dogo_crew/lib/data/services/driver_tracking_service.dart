import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DriverPosition {
  final LatLng point;
  final double heading; // 0 - 360 degrees
  final double speedKmh;
  final DateTime timestamp;

  const DriverPosition({
    required this.point,
    this.heading = 0.0,
    this.speedKmh = 40.0,
    required this.timestamp,
  });
}

class DriverTrackingService {
  SupabaseClient get _client => SupabaseService.client;
  RealtimeChannel? _activeChannel;
  String? _activeRideCode;

  final StreamController<DriverPosition> _positionStreamController =
      StreamController<DriverPosition>.broadcast();

  Stream<DriverPosition> get driverPositionStream => _positionStreamController.stream;

  /// Driver broadcasts their live GPS coordinate to the passenger
  Future<void> broadcastLocation({
    required String rideCode,
    required LatLng position,
    double heading = 0.0,
    double speedKmh = 40.0,
  }) async {
    try {
      _ensureChannel(rideCode);
      await _activeChannel?.sendBroadcastMessage(
        event: 'driver_location',
        payload: {
          'lat': position.latitude,
          'lng': position.longitude,
          'heading': heading,
          'speed': speedKmh,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {}
  }

  /// Passenger subscribes to live GPS updates for their active ride
  Stream<DriverPosition> subscribeToDriverLocation(String rideCode) {
    _ensureChannel(rideCode);
    return driverPositionStream;
  }

  void _ensureChannel(String rideCode) {
    if (_activeRideCode == rideCode && _activeChannel != null) {
      return;
    }

    _activeChannel?.unsubscribe();
    _activeRideCode = rideCode;

    _activeChannel = _client.channel('tracking_$rideCode');
    _activeChannel?.onBroadcast(
      event: 'driver_location',
      callback: (payload) {
        final lat = (payload['lat'] as num?)?.toDouble();
        final lng = (payload['lng'] as num?)?.toDouble();
        final heading = (payload['heading'] as num?)?.toDouble() ?? 0.0;
        final speed = (payload['speed'] as num?)?.toDouble() ?? 40.0;

        if (lat != null && lng != null) {
          _positionStreamController.add(
            DriverPosition(
              point: LatLng(lat, lng),
              heading: heading,
              speedKmh: speed,
              timestamp: DateTime.now(),
            ),
          );
        }
      },
    );
    _activeChannel?.subscribe();
  }

  /// Stop tracking & unsubscribe from channel
  void stopTracking() {
    _activeChannel?.unsubscribe();
    _activeChannel = null;
    _activeRideCode = null;
  }

  /// Interpolates a series of smooth coordinates between start and end
  static List<LatLng> generateRoutePoints(LatLng start, LatLng end, {int steps = 60}) {
    final points = <LatLng>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      // Add slight organic curvature to simulate real road network
      final curve = 0.003 * (1 - (2 * t - 1).abs());
      points.add(LatLng(lat + curve, lng - curve));
    }
    return points;
  }

  void dispose() {
    stopTracking();
    _positionStreamController.close();
  }
}

