import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task.dart';
import '../../providers/premium_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/banner_ad_widget.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tasksAsync = ref.watch(taskListProvider);
    final canAdd = ref.watch(canAddTaskProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BannerAdWidget(),
            // Playfair heading
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

            // Filter chips row
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipFilter(label: 'All', selected: true, onTap: () {}),
                  ...TaskType.values.map((type) => _ChipFilter(
                        label: type.label,
                        selected: false,
                        onTap: () {},
                      )),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Expanded(
              child: tasksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading tasks: $error'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(taskListProvider),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(160, 48)),
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
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 20),
                          Text('No tasks yet',
                              style: theme.textTheme.titleMedium),
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (canAdd) {
            context.push('/add-task');
          } else {
            context.push('/premium');
          }
        },
        child: Icon(canAdd ? Icons.add_rounded : Icons.lock_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ChipFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipFilter({
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
              color: selected ? Colors.transparent : cs.outline,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);

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
            // Emoji icon square
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(_typeIcon(task.type), size: 22, color: gold),
              ),
            ),
            const SizedBox(width: 14),
            // Name + time
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
            // Status badge
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
