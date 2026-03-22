import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task.dart';
import '../../config/ranks.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/streak_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final Task task;

  const TimerScreen({super.key, required this.task});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  late int _secondsRemaining;
  Timer? _timer;
  bool _running = false;
  bool _completed = false;
  DateTime? _lastTickTime;

  static const _prefTaskId = 'timer_task_id';
  static const _prefSecondsRemaining = 'timer_seconds_remaining';
  static const _prefLastTickTime = 'timer_last_tick_time';
  static const _prefWasRunning = 'timer_was_running';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.task.time * 60;
    _restoreTimerState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveTimerState();
    } else if (state == AppLifecycleState.resumed) {
      _restoreElapsedTime();
    }
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTaskId, widget.task.id);
    await prefs.setInt(_prefSecondsRemaining, _secondsRemaining);
    await prefs.setString(
        _prefLastTickTime, DateTime.now().toUtc().toIso8601String());
    await prefs.setBool(_prefWasRunning, _running);
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTaskId = prefs.getString(_prefTaskId);
    if (savedTaskId != widget.task.id) return;

    final savedSeconds = prefs.getInt(_prefSecondsRemaining);
    final savedTime = prefs.getString(_prefLastTickTime);
    final wasRunning = prefs.getBool(_prefWasRunning) ?? false;

    if (savedSeconds != null && savedTime != null) {
      final lastTick = DateTime.tryParse(savedTime);
      if (lastTick != null && wasRunning) {
        final elapsed = DateTime.now().toUtc().difference(lastTick).inSeconds;
        final adjusted = (savedSeconds - elapsed).clamp(0, widget.task.time * 60);
        setState(() => _secondsRemaining = adjusted);
        if (adjusted > 0) {
          _start();
        } else {
          setState(() => _completed = true);
        }
      } else {
        setState(() => _secondsRemaining = savedSeconds);
      }
    }
  }

  void _restoreElapsedTime() {
    if (!_running || _lastTickTime == null) return;
    final elapsed =
        DateTime.now().toUtc().difference(_lastTickTime!).inSeconds;
    if (elapsed > 0) {
      setState(() {
        _secondsRemaining = (_secondsRemaining - elapsed)
            .clamp(0, widget.task.time * 60);
        if (_secondsRemaining <= 0) {
          _timer?.cancel();
          _running = false;
          _completed = true;
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTaskId);
    await prefs.remove(_prefSecondsRemaining);
    await prefs.remove(_prefLastTickTime);
    await prefs.remove(_prefWasRunning);
  }

  void _start() {
    HapticFeedback.mediumImpact();
    _lastTickTime = DateTime.now().toUtc();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lastTickTime = DateTime.now().toUtc();
      if (_secondsRemaining <= 0) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _clearTimerState();
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
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _markComplete() async {
    _timer?.cancel();
    _clearTimerState();
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

      final newPoints = ((profile['total_points'] as int?) ?? 0) + points;
      final newRank = rankForPoints(newPoints);

      await Supabase.instance.client.from('profiles').update({
        'total_points': newPoints,
        'total_tasks_completed':
            ((profile['total_tasks_completed'] as int?) ?? 0) + 1,
        'total_time_spent':
            ((profile['total_time_spent'] as int?) ?? 0) +
                (timeSpent > 0 ? timeSpent : task.time),
        'current_rank': newRank,
      }).eq('id', user.id);

      // If this is a group task, mark it done in group_tasks too
      if (task.groupTaskId != null) {
        await Supabase.instance.client.from('group_tasks').update({
          'status': 'done',
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', task.groupTaskId!);
      }

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

      // Record streak and check for new milestones
      final newMilestones = await StreakService.instance.recordStreak();

      ref.invalidate(taskListProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(streakProvider);

      if (mounted) {
        context.go('/celebration', extra: {
          'taskName': task.name,
          'points': points,
          'timeSpent': timeSpent > 0 ? timeSpent : task.time,
          if (newMilestones.isNotEmpty) 'newMilestones': newMilestones,
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
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: cs.onSurfaceVariant),
                    onPressed: () => context.pop(),
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
                      // Timer ring with gold stroke
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
                              color: gold,
                            ),
                            // Playfair time display inside ring
                            Center(
                              child: Text(
                                _formatTime(_secondsRemaining),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Task name in Playfair
                      Text(
                        widget.task.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      if (_completed) ...[
                        Icon(Icons.celebration_rounded,
                            size: 48, color: gold),
                        const SizedBox(height: 16),
                        Text("Time's up!",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            )),
                        const SizedBox(height: 24),
                        _CircleButton(
                          label: 'Complete Task',
                          filled: true,
                          onPressed: _markComplete,
                        ),
                      ] else ...[
                        // Circular control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_running) ...[
                              _CircleButton(
                                label: 'Pause',
                                icon: Icons.pause_rounded,
                                filled: false,
                                onPressed: _pause,
                              ),
                            ] else ...[
                              _CircleButton(
                                label: 'Start',
                                icon: Icons.play_arrow_rounded,
                                filled: true,
                                onPressed: _start,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        // "Done Early" as subtle text link
                        GestureDetector(
                          onTap: _markComplete,
                          child: Text(
                            'Done Early',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                              decorationColor: cs.onSurfaceVariant,
                            ),
                          ),
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

class _CircleButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onPressed;

  const _CircleButton({
    required this.label,
    this.icon,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);

    final bgColor = filled
        ? (isDark ? gold : cs.onSurface)
        : Colors.transparent;
    final fgColor = filled
        ? (isDark ? cs.onPrimary : Colors.white)
        : cs.onSurface;
    final borderColor = filled ? Colors.transparent : cs.outline;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(icon ?? Icons.check_rounded, size: 28, color: fgColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
