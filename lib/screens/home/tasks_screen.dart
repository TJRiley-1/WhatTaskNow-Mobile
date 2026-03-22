import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task.dart';
import '../../providers/filter_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/shimmer_placeholder.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const gold = Color(0xFFC9A84C);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BannerAdWidget(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tasks',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      )),
                  IconButton(
                    icon: Icon(Icons.upload_outlined,
                        color: cs.onSurfaceVariant),
                    tooltip: 'Import Tasks',
                    onPressed: () => context.push('/import-tasks'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surfaceContainerHighest
                      : const Color(0xFFF2EFE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? gold : cs.onSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: isDark ? cs.onPrimary : Colors.white,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Open'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OpenTasksTab(),
                  _CompletedTasksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-task'),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _OpenTasksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tasksAsync = ref.watch(openTasksProvider);

    return tasksAsync.when(
      loading: () => const ShimmerTaskList(),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading tasks: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(taskListProvider),
              style:
                  FilledButton.styleFrom(minimumSize: const Size(160, 48)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist_rounded,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                Text('No open tasks', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Tap + to add your first task',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(taskListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.only(
                left: 24, right: 24, top: 8, bottom: 120),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _TaskCard(task: tasks[index]);
            },
          ),
        );
      },
    );
  }
}

class _CompletedTasksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(completedTasksProvider);
    const gold = Color(0xFFC9A84C);

    return tasksAsync.when(
      loading: () => const ShimmerTaskList(),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 56, color: gold.withValues(alpha: 0.4)),
                const SizedBox(height: 20),
                Text('No completed tasks yet',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    )),
                const SizedBox(height: 8),
                Text('Complete tasks from What Now to see them here',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    )),
              ],
            ),
          );
        }

        // Calculate stats
        final totalCompleted = tasks.fold<int>(
            0, (sum, t) => sum + t.timesCompleted);
        final totalMinutes = tasks.fold<int>(
            0, (sum, t) => sum + (t.time * t.timesCompleted));
        final totalHours = totalMinutes / 60;

        // Projection: tasks completed per day (based on account age)
        final oldestTask = tasks.reduce(
            (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);
        final daysSinceStart =
            DateTime.now().difference(oldestTask.createdAt).inDays;
        final daysActive = daysSinceStart < 1 ? 1 : daysSinceStart;
        final tasksPerDay = totalCompleted / daysActive;
        final projMonth = (tasksPerDay * 30).round();
        final proj6Month = (tasksPerDay * 180).round();
        final projYear = (tasksPerDay * 365).round();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(taskListProvider),
          child: ListView(
            padding: const EdgeInsets.only(
                left: 24, right: 24, top: 8, bottom: 120),
            children: [
              // Stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            gold.withValues(alpha: 0.15),
                            gold.withValues(alpha: 0.05),
                          ]
                        : [
                            gold.withValues(alpha: 0.1),
                            const Color(0xFFFAF8F3),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: gold.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        size: 36, color: gold),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re doing great!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            value: '$totalCompleted',
                            label: 'Tasks done',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.15),
                        ),
                        Expanded(
                          child: _StatItem(
                            value: totalHours >= 1
                                ? '${totalHours.toStringAsFixed(1)}h'
                                : '${totalMinutes}m',
                            label: 'Productive',
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'At this pace you\'ll complete...',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProjectionRow(
                              period: '1 month',
                              count: projMonth),
                          const SizedBox(height: 6),
                          _ProjectionRow(
                              period: '6 months',
                              count: proj6Month),
                          const SizedBox(height: 6),
                          _ProjectionRow(
                              period: '1 year',
                              count: projYear),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Completed Tasks',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Completed task list
              ...tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CompletedTaskCard(task: task),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const gold = Color(0xFFC9A84C);

    return Column(
      children: [
        Icon(icon, size: 18, color: gold),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String period;
  final int count;

  const _ProjectionRow({required this.period, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const gold = Color(0xFFC9A84C);

    return Row(
      children: [
        Icon(Icons.trending_up_rounded, size: 16, color: gold),
        const SizedBox(width: 8),
        Text(
          period,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          '$count tasks',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  final Task task;

  const _CompletedTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';
    const gold = Color(0xFFC9A84C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.check_rounded,
                  size: 22, color: Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$timeLabel  •  Completed ${task.timesCompleted}x',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              task.typeLabel,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  IconData _typeIcon(TaskType type) {
    return switch (type) {
      TaskType.work => Icons.work_outline_rounded,
      TaskType.personal => Icons.home_outlined,
      TaskType.health => Icons.fitness_center_rounded,
      TaskType.social => Icons.people_outline_rounded,
      TaskType.errand => Icons.shopping_cart_outlined,
      TaskType.other => Icons.push_pin_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';
    const gold = Color(0xFFC9A84C);

    return GestureDetector(
      onTap: () => context.push('/edit-task', extra: task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child:
                    Icon(_typeIcon(task.type), size: 22, color: gold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$timeLabel  •  ${task.energy.label} energy',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (task.isGroupTask) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined,
                        size: 12, color: Color(0xFF2196F3)),
                    const SizedBox(width: 3),
                    Text(
                      task.groupName ?? 'Group',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.typeLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
