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

  /// Driver claims and accepts the ride atomically (first-come, first-served)
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
      // Atomic update: only succeeds if ride is still 'pending'
      final res = await _client
          .from('rides')
          .update(updateData)
          .eq('code', rideCode)
          .eq('status', 'pending')
          .select();

      return res.isNotEmpty;
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

  /// Broadcasts real-time financial settlement event when driver completes a trip
  Future<void> broadcastSettlement({
    required String rideCode,
    required int totalFare,
    required int driverEarnings,
    required int platformCommission,
    required String paymentMethod,
    required String driverName,
  }) async {
    try {
      final channel = _client.channel('settlement_$rideCode');
      await channel.sendBroadcastMessage(
        event: 'trip_settled',
        payload: {
          'trip_code': rideCode,
          'total_fare': totalFare,
          'driver_earnings': driverEarnings,
          'platform_commission': platformCommission,
          'payment_method': paymentMethod,
          'driver_name': driverName,
          'settled_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  /// Streams real-time financial settlement events for a specific trip
  Stream<Map<String, dynamic>> streamSettlement(String rideCode) {
    late StreamController<Map<String, dynamic>> controller;
    RealtimeChannel? channel;

    controller = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        channel = _client.channel('settlement_$rideCode');
        channel?.onBroadcast(
          event: 'trip_settled',
          callback: (payload) {
            controller.add(payload);
          },
        ).subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
      },
    );

    return controller.stream;
  }

  /// Broadcasts a passenger tip to the driver in real-time
  Future<void> broadcastTip({
    required String rideCode,
    required int tipAmount,
    required String passengerName,
  }) async {
    try {
      final channel = _client.channel('settlement_$rideCode');
      await channel.sendBroadcastMessage(
        event: 'tip_received',
        payload: {
          'trip_code': rideCode,
          'tip_amount': tipAmount,
          'passenger_name': passengerName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  /// Driver listens for incoming real-time tips during or after trip
  Stream<Map<String, dynamic>> streamTip(String rideCode) {
    late StreamController<Map<String, dynamic>> controller;
    RealtimeChannel? channel;

    controller = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        channel = _client.channel('settlement_$rideCode');
        channel?.onBroadcast(
          event: 'tip_received',
          callback: (payload) {
            controller.add(payload);
          },
        ).subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
      },
    );

    return controller.stream;
  }
}

