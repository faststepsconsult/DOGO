import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';
import '../models/wallet_model.dart';
import '../services/supabase_service.dart';

class CrewRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<WalletModel?> getWalletStats() async {
    try {
      final res = await _client.rpc('my_wallet');
      if (res is List && res.isNotEmpty) {
        return WalletModel.fromJson(res.first as Map<String, dynamic>);
      }
      return WalletModel(balance: 0, today: 0, tripsDone: 0);
    } catch (_) {
      return WalletModel(balance: 0, today: 0, tripsDone: 0);
    }
  }

  Future<List<MemberModel>> listMembers() async {
    final res = await _client.rpc('list_members');
    if (res is List) {
      return res.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> setMemberRole({
    required String userId,
    required String role, // 'driver' | 'dispatcher'
    required bool grant,
  }) async {
    await _client.rpc('set_member_role', params: {
      '_user': userId,
      '_role': role,
      '_grant': grant,
    });
  }
}
