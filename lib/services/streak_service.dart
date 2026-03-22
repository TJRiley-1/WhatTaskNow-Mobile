import 'package:supabase_flutter/supabase_flutter.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int freezeDaysUsed;
  final List<int> milestones;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.freezeDaysUsed = 0,
    this.milestones = const [],
  });

  /// Whether the user has already completed a task today.
  bool get completedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  /// Whether the streak is at risk (last completion was yesterday, none today yet).
  bool get atRisk {
    if (lastCompletedDate == null || currentStreak == 0) return false;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return lastCompletedDate!.year == yesterday.year &&
        lastCompletedDate!.month == yesterday.month &&
        lastCompletedDate!.day == yesterday.day &&
        !completedToday;
  }

  /// Motivational message based on streak state.
  String get message {
    if (currentStreak == 0) return 'Complete a task to start!';
    if (completedToday) return "You're on fire!";
    if (atRisk) return 'Keep it going today!';
    return 'Keep going!';
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'] as String)
          : null,
      freezeDaysUsed: json['freeze_days_used'] as int? ?? 0,
    );
  }
}

class StreakService {
  StreakService._();
  static final instance = StreakService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch current streak data for the authenticated user.
  Future<StreakData> getStreak() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const StreakData();

    try {
      final data = await _client
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return const StreakData();

      final milestones = await _client
          .from('streak_milestones')
          .select('milestone')
          .eq('user_id', userId);

      return StreakData(
        currentStreak: data['current_streak'] as int? ?? 0,
        longestStreak: data['longest_streak'] as int? ?? 0,
        lastCompletedDate: data['last_completed_date'] != null
            ? DateTime.parse(data['last_completed_date'] as String)
            : null,
        freezeDaysUsed: data['freeze_days_used'] as int? ?? 0,
        milestones: (milestones as List)
            .map((m) => m['milestone'] as int)
            .toList()
          ..sort(),
      );
    } catch (_) {
      return const StreakData();
    }
  }

  /// Record a streak after task completion. Returns new milestones (if any).
  Future<List<int>> recordStreak() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final result = await _client.rpc('record_streak', params: {
        'p_user_id': userId,
      });

      final data = result as Map<String, dynamic>;
      final milestones = data['new_milestones'] as List? ?? [];
      return milestones.map((m) => (m as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Use a streak freeze day. Returns success and remaining freezes.
  Future<({bool success, String? reason, int? remaining})> useFreeze(
      {required bool isPremium}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return (success: false, reason: 'not_logged_in', remaining: null);
    }

    try {
      final result = await _client.rpc('use_streak_freeze', params: {
        'p_user_id': userId,
        'p_is_premium': isPremium,
      });

      final data = result as Map<String, dynamic>;
      return (
        success: data['success'] as bool? ?? false,
        reason: data['reason'] as String?,
        remaining: data['freezes_remaining'] as int?,
      );
    } catch (_) {
      return (success: false, reason: 'error', remaining: null);
    }
  }
}
