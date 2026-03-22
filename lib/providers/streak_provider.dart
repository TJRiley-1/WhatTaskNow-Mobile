import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import 'auth_provider.dart';

/// Provides current streak data — invalidate after task completion.
final streakProvider = FutureProvider<StreakData>((ref) async {
  // Re-fetch when user changes
  ref.watch(currentUserProvider);
  return StreakService.instance.getStreak();
});
