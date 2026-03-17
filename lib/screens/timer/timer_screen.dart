import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task.dart';
import '../../config/ranks.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final Task task;

  const TimerScreen({super.key, required this.task});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _running = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.task.time * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {
          _running = false;
          _completed = true;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _markComplete() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final task = widget.task;
    final timeSpent = (task.time * 60 - _secondsRemaining) ~/ 60;
    final points = _calculatePoints(task);

    try {
      await Supabase.instance.client.from('completed_tasks').insert({
        'user_id': user.id,
        'task_name': task.name,
        'task_type': task.typeRaw,
        'points': points,
        'time_spent': timeSpent > 0 ? timeSpent : task.time,
        'task_time': task.time,
        'task_social': task.social.name,
        'task_energy': task.energy.name,
      });

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('total_points, total_tasks_completed, total_time_spent')
          .eq('id', user.id)
          .single();

      final newPoints = (profile['total_points'] as int) + points;
      final newRank = rankForPoints(newPoints);

      await Supabase.instance.client.from('profiles').update({
        'total_points': newPoints,
        'total_tasks_completed':
            (profile['total_tasks_completed'] as int) + 1,
        'total_time_spent':
            (profile['total_time_spent'] as int) +
                (timeSpent > 0 ? timeSpent : task.time),
        'current_rank': newRank,
      }).eq('id', user.id);

      await ref.read(taskListProvider.notifier).updateTask(Task(
            id: task.id,
            userId: task.userId,
            name: task.name,
            description: task.description,
            typeRaw: task.typeRaw,
            time: task.time,
            social: task.social,
            energy: task.energy,
            dueDate: task.dueDate,
            recurring: task.recurring,
            timesShown: task.timesShown,
            timesSkipped: task.timesSkipped,
            timesCompleted: task.timesCompleted + 1,
            pointsEarned: task.pointsEarned + points,
            createdAt: task.createdAt,
            updatedAt: DateTime.now().toUtc(),
          ));

      ref.invalidate(taskListProvider);
      ref.invalidate(profileProvider);

      if (mounted) {
        context.go('/celebration', extra: {
          'taskName': task.name,
          'points': points,
          'timeSpent': timeSpent > 0 ? timeSpent : task.time,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  int _calculatePoints(Task task) {
    int base = 10;
    if (task.time >= 60) base += 10;
    if (task.energy == Level.high) base += 5;
    if (task.social == Level.high) base += 5;
    return base;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final progress = 1 - (_secondsRemaining / (widget.task.time * 60));
    final ringColor = isDark ? const Color(0xFFD4A853) : cs.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button + task name
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: cs.onSurfaceVariant),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.task.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timer ring
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: ringColor,
                            ),
                            Center(
                              child: Text(
                                _formatTime(_secondsRemaining),
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        widget.task.name,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      if (_completed) ...[
                        Icon(Icons.celebration_rounded,
                            size: 48, color: cs.primary),
                        const SizedBox(height: 16),
                        Text("Time's up!",
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _markComplete,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(220, 52)),
                          child: const Text('Complete Task'),
                        ),
                      ] else ...[
                        if (!_running)
                          FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start'),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(180, 52)),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _pause,
                            icon: const Icon(Icons.pause_rounded),
                            label: const Text('Pause'),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(180, 52)),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _markComplete,
                          child: const Text('Done Early'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
