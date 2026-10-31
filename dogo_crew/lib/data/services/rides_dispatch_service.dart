import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ride_model.dart';
import 'supabase_service.dart';

class RidesDispatchService {
  SupabaseClient get _client => SupabaseService.client;

  /// Inserts a new ride request into the `rides` table on Supabase.
  Future<RideModel?> createRideRequest(RideModel ride) async {
    try {
      final data = ride.toSupabaseMap();
      final res = await _client.from('rides').insert(data).select().maybeSingle();
      if (res != null) {
        return RideModel.fromSupabase(res);
      }
    } catch (_) {
      // In case of network error, returns null to allow graceful fallback
    }
    return null;
  }

  /// Streams active ride updates for passenger by ride code
  Stream<RideModel?> streamRide(String code) {
    try {
      return _client
          .from('rides')
          .stream(primaryKey: ['id'])
          .eq('code', code)
          .map((list) {
            if (list.isNotEmpty) {
              return RideModel.fromSupabase(list.first);
            }
            return null;
          });
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Streams incoming pending rides for online drivers
  Stream<List<Map<String, dynamic>>> streamPendingRides() {
    try {
      return _client
          .from('rides')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending')
          .order('created_at', ascending: false);
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Fetches an active ride by code (used for polling fallback)
  Future<RideModel?> fetchRide(String code) async {
    try {
      final res = await _client.from('rides').select().eq('code', code).maybeSingle();
      if (res != null) {
        return RideModel.fromSupabase(res);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches pending rides list (used for polling fallback)
  Future<List<Map<String, dynamic>>> fetchPendingRides() async {
    try {
      final res = await _client
          .from('rides')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static bool _isValidUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(str);
  }

  /// Driver claims and accepts the ride
  Future<bool> acceptRide({
    required String rideCode,
    String? driverId,
    required String driverName,
    required String driverPlate,
    required String driverVehicle,
    required String driverPhone,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': 'accepted',
        'driver_name': driverName,
        'driver_plate': driverPlate,
        'driver_vehicle': driverVehicle,
        'driver_phone': driverPhone,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (_isValidUuid(driverId)) {
        updateData['driver_id'] = driverId;
      }
      await _client.from('rides').update(updateData).eq('code', rideCode);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates status as driver progresses: to_pickup -> at_pickup -> on_trip -> completed
  Future<bool> updateStatus({
    required String rideCode,
    required String newStatus,
  }) async {
    try {
      await _client.from('rides').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('code', rideCode);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels a ride
  Future<bool> cancelRide(String rideCode) async {
    try {
      await _client.from('rides').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('code', rideCode);
      return true;
    } catch (_) {
      return false;
    }
  }
}

