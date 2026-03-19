import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_member.dart';

final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final data = await Supabase.instance.client
      .from('group_members')
      .select('*, profiles(display_name, avatar_url)')
      .eq('group_id', groupId)
      .order('created_at');

  return data.map((json) => GroupMember.fromJson(json)).toList();
});
