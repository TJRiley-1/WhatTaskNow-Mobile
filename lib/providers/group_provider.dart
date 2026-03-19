import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import 'auth_provider.dart';

final userGroupsProvider =
    AsyncNotifierProvider<UserGroupsNotifier, List<Group>>(
        UserGroupsNotifier.new);

class UserGroupsNotifier extends AsyncNotifier<List<Group>> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Group>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final memberships = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', user.id);

    if (memberships.isEmpty) return [];

    final groupIds =
        memberships.map((m) => m['group_id'] as String).toList();

    final groups =
        await _client.from('groups').select().inFilter('id', groupIds);

    return groups.map((json) => Group.fromJson(json)).toList();
  }

  Future<void> createGroup({
    required String name,
    String? description,
    required GroupType groupType,
    DateTime? eventDate,
    LeaderboardPeriod leaderboardPeriod = LeaderboardPeriod.weekly,
    LeaderboardMetric leaderboardMetric = LeaderboardMetric.points,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final inviteCode = await _client.rpc('generate_invite_code') as String;

    final groupData = await _client
        .from('groups')
        .insert({
          'name': name,
          'description': description,
          'invite_code': inviteCode,
          'created_by': user.id,
          'group_type': groupType.dbValue,
          'event_date': eventDate?.toIso8601String(),
          'leaderboard_period': leaderboardPeriod.name,
          'leaderboard_metric': leaderboardMetric.name,
        })
        .select()
        .single();

    await _client.from('group_members').insert({
      'group_id': groupData['id'],
      'user_id': user.id,
      'role': 'admin',
    });

    ref.invalidateSelf();
  }

  Future<String?> joinByCode(String code) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'Not signed in';

    final groups = await _client
        .from('groups')
        .select()
        .eq('invite_code', code.toUpperCase());

    if (groups.isEmpty) return 'Invalid invite code';

    final groupId = groups.first['id'] as String;

    final existing = await _client
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', user.id);

    if (existing.isNotEmpty) return 'Already a member';

    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': user.id,
      'role': 'member',
    });

    ref.invalidateSelf();
    return null;
  }

  Future<void> leaveGroup(String groupId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', user.id);

    ref.invalidateSelf();
  }

  Future<void> promoteToAdmin(String groupId, String userId) async {
    await _client
        .from('group_members')
        .update({'role': 'admin'})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> removeFromGroup(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> updateAssignmentPermission(
      String groupId, String userId, bool allow) async {
    await _client
        .from('group_members')
        .update({'allow_task_assignment': allow})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }
}

/// Leaderboard provider using parameterised RPC
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, ({String groupId, String period, String metric})>(
        (ref, params) async {
  final data = await Supabase.instance.client.rpc('get_group_leaderboard', params: {
    'p_group_id': params.groupId,
    'p_period': params.period,
    'p_metric': params.metric,
  });

  return (data as List)
      .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
      .toList();
});
