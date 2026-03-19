import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_task.dart';
import 'auth_provider.dart';

final groupTasksProvider = AsyncNotifierProvider.family<GroupTasksNotifier,
    List<GroupTask>, String>(GroupTasksNotifier.new);

class GroupTasksNotifier extends FamilyAsyncNotifier<List<GroupTask>, String> {
  SupabaseClient get _client => Supabase.instance.client;
  Timer? _refreshTimer;

  @override
  Future<List<GroupTask>> build(String arg) async {
    ref.onDispose(() => _refreshTimer?.cancel());

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidateSelf();
    });

    return _fetchTasks();
  }

  Future<List<GroupTask>> _fetchTasks() async {
    // Fetch group tasks with assigned user profile info
    final data = await _client
        .from('group_tasks')
        .select('*, assigned_profile:profiles!group_tasks_assigned_to_fkey(display_name)')
        .eq('group_id', arg)
        .order('created_at', ascending: false);

    return data.map((json) => GroupTask.fromJson(json)).toList();
  }

  Future<void> addGroupTask({
    required String name,
    String? description,
    required String type,
    required int time,
    required String social,
    required String energy,
    DateTime? dueDate,
    String? assignedTo,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final insertData = {
      'group_id': arg,
      'name': name,
      'description': description,
      'type': type,
      'time': time,
      'social': social,
      'energy': energy,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'created_by': user.id,
    };

    if (assignedTo != null) {
      insertData['assigned_to'] = assignedTo;
      insertData['status'] = 'claimed';
      insertData['claimed_at'] = DateTime.now().toUtc().toIso8601String();
    }

    final result = await _client
        .from('group_tasks')
        .insert(insertData)
        .select()
        .single();

    // If assigned, sync to user's personal task list
    if (assignedTo != null) {
      await _client.rpc('sync_group_task_to_user', params: {
        'p_group_task_id': result['id'],
        'p_user_id': assignedTo,
      });
    }

    ref.invalidateSelf();
  }

  Future<void> claimTask(String taskId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _client.from('group_tasks').update({
      'assigned_to': user.id,
      'status': 'claimed',
      'claimed_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', taskId);

    // Sync to personal task list
    await _client.rpc('sync_group_task_to_user', params: {
      'p_group_task_id': taskId,
      'p_user_id': user.id,
    });

    ref.invalidateSelf();
  }

  Future<void> assignTask(String taskId, String userId) async {
    await _client.from('group_tasks').update({
      'assigned_to': userId,
      'status': 'claimed',
      'claimed_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', taskId);

    await _client.rpc('sync_group_task_to_user', params: {
      'p_group_task_id': taskId,
      'p_user_id': userId,
    });

    ref.invalidateSelf();
  }

  Future<void> updateStatus(String taskId, GroupTaskStatus status) async {
    final updateData = <String, dynamic>{
      'status': status.dbValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (status == GroupTaskStatus.done) {
      updateData['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await _client.from('group_tasks').update(updateData).eq('id', taskId);
    ref.invalidateSelf();
  }

  Future<void> deleteGroupTask(String taskId) async {
    await _client.from('group_tasks').delete().eq('id', taskId);
    ref.invalidateSelf();
  }
}
