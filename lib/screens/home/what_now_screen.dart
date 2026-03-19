import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task.dart';
import '../../providers/filter_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/swipe_card.dart';

class WhatNowScreen extends ConsumerStatefulWidget {
  const WhatNowScreen({super.key});

  @override
  ConsumerState<WhatNowScreen> createState() => _WhatNowScreenState();
}

class _WhatNowScreenState extends ConsumerState<WhatNowScreen> {
  int _currentIndex = 0;
  Task? _chosenTask;

  void _onAccept(Task task) async {
    try {
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
            timesShown: task.timesShown + 1,
            timesSkipped: task.timesSkipped,
            timesCompleted: task.timesCompleted,
            pointsEarned: task.pointsEarned,
            createdAt: task.createdAt,
            updatedAt: DateTime.now().toUtc(),
          ));
    } catch (_) {}
    setState(() => _chosenTask = task);
  }

  void _onSkip(Task task) async {
    try {
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
            timesShown: task.timesShown + 1,
            timesSkipped: task.timesSkipped + 1,
            timesCompleted: task.timesCompleted,
            pointsEarned: task.pointsEarned,
            createdAt: task.createdAt,
            updatedAt: DateTime.now().toUtc(),
          ));
    } catch (_) {}
    setState(() => _currentIndex++);
  }

  void _reset() {
    setState(() {
      _currentIndex = 0;
      _chosenTask = null;
    });
    ref.invalidate(taskListProvider);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tasksAsync = ref.watch(filteredTasksProvider);
    final user = ref.watch(currentUserProvider);
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);

    // Extract display name from user metadata or email
    final displayName = user?.userMetadata?['display_name'] as String? ??
        user?.email?.split('@').first ??
        'there';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BannerAdWidget(),

            // Greeting header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gold avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [gold, const Color(0xFFE8C96A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Streak bar (placeholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 18, color: gold),
                    const SizedBox(width: 8),
                    Text(
                      '0 day streak',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: gold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Keep going!',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: true,
                    onTap: () {},
                  ),
                  ...TaskType.values.map((type) => _FilterChip(
                        label: type.label,
                        selected: false,
                        onTap: () {},
                      )),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Main content
            Expanded(
              child: tasksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error: $error')),
                data: (tasks) {
                  if (_chosenTask != null) {
                    return _ChosenView(
                      task: _chosenTask!,
                      onReset: _reset,
                    );
                  }

                  if (tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 56,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 20),
                            Text('No tasks match your filters',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Try adjusting filters or add more tasks',
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () =>
                                  ref.read(filterProvider.notifier).clearAll(),
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_currentIndex >= tasks.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded,
                                size: 56,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 20),
                            Text("You've seen all tasks",
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _reset,
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(180, 48)),
                              child: const Text('Start Over'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final task = tasks[_currentIndex];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        Expanded(
                          child: Center(
                            child: SwipeCard(
                              key: ValueKey(task.id),
                              task: task,
                              currentIndex: _currentIndex,
                              totalCount: tasks.length,
                              onAccept: () => _onAccept(task),
                              onSkip: () => _onSkip(task),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action row: ghost "Later" left, filled "Done" right
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _onSkip(task),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    foregroundColor: cs.onSurfaceVariant,
                                    side: BorderSide(
                                        color: cs.outline),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('←'),
                                      const SizedBox(width: 6),
                                      Text('Later',
                                          style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: () => _onAccept(task),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Done',
                                          style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      const Text('✓'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFFC9A84C) : cs.onSurface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : cs.outline,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? (isDark ? cs.onPrimary : Colors.white)
                  : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChosenView extends StatelessWidget {
  final Task task;
  final VoidCallback onReset;

  const _ChosenView({required this.task, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rocket_launch_rounded, size: 48, color: gold),
          const SizedBox(height: 12),
          Text("Let's do it!",
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: gold)),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(task.name,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                if (task.description != null) ...[
                  const SizedBox(height: 10),
                  Text(task.description!,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(timeLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: gold,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.push('/timer', extra: task),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Task'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onReset,
            child: const Text('Pick Another'),
          ),
        ],
      ),
    );
  }
}

