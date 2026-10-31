import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/member_model.dart';
import '../../../../data/models/trip_message_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/crew_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/supabase_service.dart';

class TripDetailViewModel extends ChangeNotifier {
  final String tripId;
  final TripRepository tripRepo;
  final ChatRepository chatRepo;
  final CrewRepository crewRepo;

  TripModel? _trip;
  List<TripMessageModel> _messages = [];
  List<MemberModel> _drivers = [];
  String? _goodsPhotoSignedUrl;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _msgSub;

  TripDetailViewModel({
    required this.tripId,
    required this.tripRepo,
    required this.chatRepo,
    required this.crewRepo,
  }) {
    loadTrip();
    _subscribeToMessages();
    loadDrivers();
  }

  TripModel? get trip => _trip;
  List<TripMessageModel> get messages => _messages;
  List<MemberModel> get drivers => _drivers;
  String? get goodsPhotoSignedUrl => _goodsPhotoSignedUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _subscribeToMessages() {
    _msgSub = chatRepo.getMessagesStream(tripId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });
  }

  Future<void> loadTrip() async {
    try {
      _trip = await tripRepo.getTrip(tripId);
      if (_trip?.goodsPhotoUrl != null) {
        _goodsPhotoSignedUrl = await SupabaseService.getSignedUrl(
          bucket: 'goods-photos',
          path: _trip!.goodsPhotoUrl!,
        );
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not load trip details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDrivers() async {
    try {
      final members = await crewRepo.listMembers();
      _drivers = members.where((m) => m.isDriver).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> sendMessage({
    required String body,
    required String senderId,
    String senderKind = 'staff',
  }) async {
    if (body.trim().isEmpty) return false;
    try {
      await chatRepo.sendMessage(
        tripId: tripId,
        body: body,
        senderId: senderId,
        senderKind: senderKind,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> advanceStatus(String nextStatus) async {
    try {
      DateTime? movedAt;
      if (nextStatus == 'en_route' && _trip?.movedAt == null) {
        movedAt = DateTime.now();
      }
      await tripRepo.updateTripStatus(
        tripId: tripId,
        newStatus: nextStatus,
        movedAt: movedAt,
      );
      await loadTrip();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markPaid() async {
    try {
      await tripRepo.markTripPaid(tripId);
      await loadTrip();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignDriver(String driverId) async {
    try {
      await tripRepo.assignDriver(
        tripId: tripId,
        driverId: driverId,
        currentStatus: _trip?.status ?? 'pending',
      );
      await loadTrip();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> cancelTrip(double coveredKm) async {
    final refund = await tripRepo.cancelTrip(tripId: tripId, coveredKm: coveredKm);
    await loadTrip();
    return refund;
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }
}
