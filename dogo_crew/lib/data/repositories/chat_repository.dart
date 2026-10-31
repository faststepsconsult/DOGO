import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_message_model.dart';
import '../services/supabase_service.dart';

class ChatRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<List<TripMessageModel>> getMessagesStream(String tripId) {
    return _client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((e) => TripMessageModel.fromJson(e)).toList());
  }

  Future<List<TripMessageModel>> getMessages(String tripId) async {
    final response = await _client
        .from('trip_messages')
        .select()
        .eq('trip_id', tripId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((e) => TripMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage({
    required String tripId,
    required String body,
    required String senderId,
    String senderKind = 'staff',
  }) async {
    await _client.from('trip_messages').insert({
      'trip_id': tripId,
      'body': body.trim(),
      'sender_id': senderId,
      'sender_kind': senderKind,
    });
  }
}
