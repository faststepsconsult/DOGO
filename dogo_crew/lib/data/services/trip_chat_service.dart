import 'dart:async';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_message_model.dart';
import 'supabase_service.dart';

class TripChatService {
  static final TripChatService _instance = TripChatService._internal();
  factory TripChatService() => _instance;
  TripChatService._internal();

  SupabaseClient get _client => SupabaseService.client;

  // Active channel per trip
  final Map<String, RealtimeChannel> _channels = {};

  // In-memory message store per trip code
  final Map<String, List<TripMessageModel>> _messages = {};

  // Stream controllers
  final Map<String, StreamController<List<TripMessageModel>>> _messageControllers = {};
  final Map<String, StreamController<bool>> _typingControllers = {};
  final Map<String, StreamController<int>> _unreadControllers = {};

  // Unread counters: key is "${tripCode}_${role}"
  final Map<String, int> _unreadCounts = {};

  // Whether the chat modal is currently open on this device for a trip
  final Map<String, bool> _isModalOpen = {};

  void setModalOpen(String tripCode, bool isOpen, String currentRole) {
    _isModalOpen['${tripCode}_$currentRole'] = isOpen;
    if (isOpen) {
      markAsRead(tripCode, currentRole);
    }
  }

  void _ensureChannel(String tripCode) {
    if (_channels.containsKey(tripCode)) return;

    _messages.putIfAbsent(tripCode, () => []);

    final channel = _client.channel('chat_$tripCode');

    channel.onBroadcast(
      event: 'new_message',
      callback: (payload) {
        final msgJson = Map<String, dynamic>.from(payload);
        final newMsg = TripMessageModel(
          id: msgJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          tripId: tripCode,
          body: msgJson['body']?.toString() ?? '',
          senderId: msgJson['sender_id']?.toString(),
          senderKind: msgJson['sender_kind']?.toString() ?? 'staff',
          createdAt: DateTime.tryParse(msgJson['created_at']?.toString() ?? '') ?? DateTime.now(),
        );

        final list = _messages.putIfAbsent(tripCode, () => []);
        // Avoid duplicate message IDs
        if (!list.any((m) => m.id == newMsg.id)) {
          list.add(newMsg);
          _messageControllers[tripCode]?.add(List.unmodifiable(list));

          // Check who received it
          final recipientRole = newMsg.senderKind == 'driver' ? 'passenger' : 'driver';
          final modalKey = '${tripCode}_$recipientRole';
          final isModalOpen = _isModalOpen[modalKey] ?? false;

          if (!isModalOpen) {
            final unreadKey = '${tripCode}_$recipientRole';
            _unreadCounts[unreadKey] = (_unreadCounts[unreadKey] ?? 0) + 1;
            _unreadControllers[unreadKey]?.add(_unreadCounts[unreadKey]!);
            try {
              HapticFeedback.mediumImpact();
            } catch (_) {}
          }
        }
      },
    );

    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final isTyping = payload['is_typing'] == true;
        final senderRole = payload['sender_role']?.toString() ?? '';
        final typingKey = '${tripCode}_$senderRole';
        _typingControllers[typingKey]?.add(isTyping);
      },
    );

    channel.subscribe();
    _channels[tripCode] = channel;
  }

  Stream<List<TripMessageModel>> streamMessages(String tripCode) {
    _ensureChannel(tripCode);
    final ctrl = _messageControllers.putIfAbsent(
      tripCode,
      () => StreamController<List<TripMessageModel>>.broadcast(),
    );
    // Emit current list immediately
    Future.microtask(() {
      final list = _messages[tripCode] ?? [];
      ctrl.add(List.unmodifiable(list));
    });
    return ctrl.stream;
  }

  Stream<bool> streamTyping(String tripCode, String targetRole) {
    _ensureChannel(tripCode);
    final typingKey = '${tripCode}_$targetRole';
    return _typingControllers
        .putIfAbsent(typingKey, () => StreamController<bool>.broadcast())
        .stream;
  }

  Stream<int> streamUnreadCount(String tripCode, String currentRole) {
    final key = '${tripCode}_$currentRole';
    final ctrl = _unreadControllers.putIfAbsent(
      key,
      () => StreamController<int>.broadcast(),
    );
    Future.microtask(() {
      ctrl.add(_unreadCounts[key] ?? 0);
    });
    return ctrl.stream;
  }

  int getUnreadCount(String tripCode, String currentRole) {
    return _unreadCounts['${tripCode}_$currentRole'] ?? 0;
  }

  void markAsRead(String tripCode, String currentRole) {
    final key = '${tripCode}_$currentRole';
    _unreadCounts[key] = 0;
    _unreadControllers[key]?.add(0);
  }

  List<TripMessageModel> getMessages(String tripCode) {
    return List.unmodifiable(_messages[tripCode] ?? []);
  }

  Future<void> sendMessage({
    required String tripCode,
    required String body,
    required String senderRole, // 'passenger' | 'driver'
    String? senderId,
  }) async {
    final cleanBody = body.trim();
    if (cleanBody.isEmpty) return;

    _ensureChannel(tripCode);

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${senderRole[0]}';
    final now = DateTime.now();

    final msg = TripMessageModel(
      id: msgId,
      tripId: tripCode,
      body: cleanBody,
      senderId: senderId,
      senderKind: senderRole,
      createdAt: now,
    );

    // 1. Optimistic local addition
    final list = _messages.putIfAbsent(tripCode, () => []);
    list.add(msg);
    _messageControllers[tripCode]?.add(List.unmodifiable(list));

    // 2. Broadcast to other device via Supabase Realtime
    try {
      final channel = _channels[tripCode];
      await channel?.sendBroadcastMessage(
        event: 'new_message',
        payload: {
          'id': msgId,
          'trip_id': tripCode,
          'body': cleanBody,
          'sender_id': senderId,
          'sender_kind': senderRole,
          'created_at': now.toIso8601String(),
        },
      );
    } catch (_) {}
  }

  void sendTyping({
    required String tripCode,
    required bool isTyping,
    required String senderRole, // 'passenger' | 'driver'
  }) {
    _ensureChannel(tripCode);
    try {
      _channels[tripCode]?.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'trip_id': tripCode,
          'is_typing': isTyping,
          'sender_role': senderRole,
        },
      );
    } catch (_) {}
  }
}

