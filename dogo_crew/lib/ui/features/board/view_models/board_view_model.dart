import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repositories/trip_repository.dart';

enum BoardTab { open, active, done }

class BoardViewModel extends ChangeNotifier {
  final TripRepository tripRepo;

  List<TripModel> _trips = [];
  BoardTab _currentTab = BoardTab.open;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _tripsSub;

  BoardViewModel({required this.tripRepo}) {
    loadTrips();
    _subscribeToTrips();
  }

  List<TripModel> get trips => _trips;
  BoardTab get currentTab => _currentTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setTab(BoardTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  List<TripModel> get filteredTrips {
    switch (_currentTab) {
      case BoardTab.open:
        return _trips.where((t) => t.status == 'pending').toList();
      case BoardTab.active:
        return _trips.where((t) => ['accepted', 'en_route', 'picked_up'].contains(t.status)).toList();
      case BoardTab.done:
        return _trips.where((t) => ['completed', 'cancelled'].contains(t.status)).toList();
    }
  }

  int get openCount => _trips.where((t) => t.status == 'pending').length;
  int get activeCount => _trips.where((t) => ['accepted', 'en_route', 'picked_up'].contains(t.status)).length;
  int get doneCount => _trips.where((t) => ['completed', 'cancelled'].contains(t.status)).length;

  void _subscribeToTrips() {
    _tripsSub = tripRepo.tripsStream.listen(
      (data) {
        _trips = data.map((e) => TripModel.fromJson(e)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        // Fallback to fetch
        loadTrips();
      },
    );
  }

  Future<void> loadTrips() async {
    try {
      _trips = await tripRepo.getTrips();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load trips.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptTrip(String tripId) async {
    try {
      await tripRepo.acceptTrip(tripId);
      await loadTrips();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markPaid(String tripId) async {
    try {
      await tripRepo.markTripPaid(tripId);
      await loadTrips();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _tripsSub?.cancel();
    super.dispose();
  }
}
