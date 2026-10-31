import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../services/supabase_service.dart';

class TripRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<List<Map<String, dynamic>>> get tripsStream =>
      _client.from('trips').stream(primaryKey: ['id']).order('created_at', ascending: false);

  Future<List<TripModel>> getTrips() async {
    final response = await _client
        .from('trips')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripModel?> getTrip(String id) async {
    final response = await _client.from('trips').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return TripModel.fromJson(response);
  }

  Future<void> acceptTrip(String tripId) async {
    await _client.rpc('accept_trip', params: {'_trip': tripId});
  }

  Future<void> markTripPaid(String tripId) async {
    await _client.rpc('mark_trip_paid', params: {'_trip': tripId});
  }

  Future<int> cancelTrip({
    required String tripId,
    required double coveredKm,
  }) async {
    final result = await _client.rpc(
      'cancel_trip',
      params: {
        '_trip': tripId,
        '_covered_km': coveredKm,
      },
    );
    return (result as num?)?.toInt() ?? 0;
  }

  Future<void> updateTripStatus({
    required String tripId,
    required String newStatus,
    DateTime? movedAt,
  }) async {
    final patch = <String, dynamic>{
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (movedAt != null) {
      patch['moved_at'] = movedAt.toIso8601String();
    }
    await _client.from('trips').update(patch).eq('id', tripId);
  }

  Future<void> assignDriver({
    required String tripId,
    required String driverId,
    required String currentStatus,
  }) async {
    await _client.from('trips').update({
      'assigned_to': driverId,
      'status': currentStatus == 'pending' ? 'accepted' : currentStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tripId);
  }

  Future<void> createTrip({
    required String service,
    required String customerName,
    required String customerPhone,
    required String pickup,
    required String dropoff,
    required double distanceKm,
    required int fare,
    String? notes,
    bool isPaid = false,
    Uint8List? goodsPhotoBytes,
    String? goodsPhotoFileName,
  }) async {
    String? goodsPhotoUrl;
    if (goodsPhotoBytes != null && goodsPhotoFileName != null) {
      final sanitizedName = goodsPhotoFileName.replaceAll(RegExp(r'[^\w.]'), '');
      final path = '${DateTime.now().millisecondsSinceEpoch}-$sanitizedName';
      goodsPhotoUrl = await SupabaseService.uploadFile(
        bucket: 'goods-photos',
        path: path,
        fileBytes: goodsPhotoBytes,
      );
    }

    await _client.from('trips').insert({
      'service': service,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup': pickup,
      'dropoff': dropoff,
      'distance_km': distanceKm,
      'fare': fare,
      'notes': notes?.isNotEmpty == true ? notes : null,
      'goods_photo_url': goodsPhotoUrl,
      'payment_status': isPaid ? 'paid' : 'unpaid',
      'paid_at': isPaid ? DateTime.now().toIso8601String() : null,
    });
  }
}
