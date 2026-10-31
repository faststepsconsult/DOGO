import 'package:flutter/material.dart';
import '../../../../data/models/member_model.dart';
import '../../../../data/repositories/crew_repository.dart';

class TeamViewModel extends ChangeNotifier {
  final CrewRepository crewRepo;

  List<MemberModel> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  TeamViewModel({required this.crewRepo}) {
    loadMembers();
  }

  List<MemberModel> get members => _members;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MemberModel> get pendingApproval =>
      _members.where((m) => m.isPendingApproval).toList();

  Future<void> loadMembers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _members = await crewRepo.listMembers();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Failed to load team members.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleRole({
    required String userId,
    required String role, // 'driver' | 'dispatcher'
    required bool grant,
  }) async {
    try {
      await crewRepo.setMemberRole(userId: userId, role: role, grant: grant);
      await loadMembers();
      return true;
    } catch (_) {
      return false;
    }
  }
}
