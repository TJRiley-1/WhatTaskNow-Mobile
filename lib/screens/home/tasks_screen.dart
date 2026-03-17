import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tasks', style: theme.appBarTheme.titleTextStyle),
                  IconButton(
                    icon: Icon(Icons.upload_outlined,
                        color: cs.onSurfaceVariant),
                    tooltip: 'Import Tasks',
                    onPressed: () => context.push('/import-tasks'),
                  ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: () {
            if (canAdd) {
              context.push('/add-task');
            } else {
              context.push('/premium');
            }
          },
          child: Icon(canAdd ? Icons.add_rounded : Icons.lock_rounded),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  Color _typeColor(TaskType type) {
    return switch (type) {
      TaskType.work => const Color(0xFF4A90D9),
      TaskType.personal => const Color(0xFF9B59B6),
      TaskType.health => const Color(0xFF27AE60),
      TaskType.social => const Color(0xFFE67E22),
      TaskType.errand => const Color(0xFF1ABC9C),
      TaskType.other => const Color(0xFF95A5A6),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';
    final typeColor = _typeColor(task.type);

    return GestureDetector(
      onTap: () => context.push('/edit-task', extra: task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _MetaLabel(icon: Icons.timer_outlined, label: timeLabel),
                _MetaLabel(
                    icon: Icons.bolt_outlined,
                    label: task.energy.label),
                _MetaLabel(
                    icon: Icons.people_outline,
                    label: task.social.label),
                if (task.recurring != Recurring.none)
                  _MetaLabel(
                      icon: Icons.repeat, label: task.recurring.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
