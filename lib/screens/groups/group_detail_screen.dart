import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/group.dart';
import '../../models/group_task.dart';
import '../../models/group_member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/group_tasks_provider.dart';
import '../../providers/group_members_provider.dart';
import '../../widgets/assign_task_sheet.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
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

  bool _isAdmin(List<GroupMember> members) {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    return members.any((m) => m.userId == user.id && m.isAdmin);
  }

  void _shareInvite() {
    Share.share(
      'Join my group on Whatnow! Code: ${widget.group.inviteCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id));
    const gold = Color(0xFFC9A84C);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share invite',
            onPressed: _shareInvite,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_code',
                child: Text('Copy Invite Code'),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave Group'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'copy_code') {
                Clipboard.setData(
                    ClipboardData(text: widget.group.inviteCode));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Invite code copied: ${widget.group.inviteCode}')),
                  );
                }
              } else if (value == 'leave') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave Group'),
                    content: const Text(
                        'Are you sure you want to leave this group?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref
                      .read(userGroupsProvider.notifier)
                      .leaveGroup(widget.group.id);
                  if (context.mounted) context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Event date banner
          if (widget.group.eventDate != null) _EventDateBanner(group: widget.group),
          if (widget.group.eventDate == null && widget.group.isEventDriven)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: gold.withValues(alpha: 0.08),
              child: Text(
                'Ongoing Event',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: gold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  Tab(text: 'Tasks'),
                  Tab(text: 'Members'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TasksTab(group: widget.group),
                _MembersTab(group: widget.group),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: membersAsync.whenOrNull(
        data: (members) => _isAdmin(members)
            ? FloatingActionButton(
                onPressed: () => context.push('/add-group-task', extra: {
                  'groupId': widget.group.id,
                  'members': members,
                }),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

class _EventDateBanner extends StatelessWidget {
  final Group group;

  const _EventDateBanner({required this.group});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC9A84C);
    final eventDate = group.eventDate!;
    final daysUntil = eventDate.difference(DateTime.now()).inDays;

    final label = daysUntil < 0
        ? 'Event passed ${-daysUntil} days ago'
        : daysUntil == 0
            ? 'Event is today!'
            : '$daysUntil days until event';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: gold.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_rounded, size: 16, color: gold),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksTab extends ConsumerWidget {
  final Group group;

  const _TasksTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tasksAsync = ref.watch(groupTasksProvider(group.id));
    final currentUser = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(groupMembersProvider(group.id));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_outlined,
                      size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No tasks yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Admins can add tasks for the group',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final isAdmin = membersAsync.whenOrNull(
              data: (members) =>
                  members.any((m) => m.userId == currentUser?.id && m.isAdmin),
            ) ??
            false;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(groupTasksProvider(group.id)),
          child: ListView.separated(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 96),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _GroupTaskCard(
                task: tasks[index],
                isAdmin: isAdmin,
                currentUserId: currentUser?.id,
                groupId: group.id,
              );
            },
          ),
        );
      },
    );
  }
}

class _GroupTaskCard extends ConsumerWidget {
  final GroupTask task;
  final bool isAdmin;
  final String? currentUserId;
  final String groupId;

  const _GroupTaskCard({
    required this.task,
    required this.isAdmin,
    this.currentUserId,
    required this.groupId,
  });

  Color _statusColor(GroupTaskStatus status) {
    return switch (status) {
      GroupTaskStatus.unassigned => const Color(0xFF9E9E9E),
      GroupTaskStatus.claimed => const Color(0xFF2196F3),
      GroupTaskStatus.inProgress => const Color(0xFFFF9800),
      GroupTaskStatus.done => const Color(0xFF4CAF50),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(task.status);
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    decoration:
                        task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.status.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 0,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                timeLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (task.dueDate != null)
                Text(
                  '  •  Due ${task.dueDate!.day}/${task.dueDate!.month}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (task.assignedToName != null) ...[
                Text(
                  '  •  ',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  task.assignedToName!,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          if (!task.isDone) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (task.isUnassigned && !isAdmin)
                  _ActionChip(
                    label: 'Claim',
                    icon: Icons.front_hand_outlined,
                    onTap: () => ref
                        .read(groupTasksProvider(groupId).notifier)
                        .claimTask(task.id),
                  ),
                if (task.isUnassigned && isAdmin) ...[
                  _ActionChip(
                    label: 'Assign',
                    icon: Icons.person_add_outlined,
                    onTap: () => _showAssignSheet(context, ref),
                  ),
                  _ActionChip(
                    label: 'Claim',
                    icon: Icons.front_hand_outlined,
                    onTap: () => ref
                        .read(groupTasksProvider(groupId).notifier)
                        .claimTask(task.id),
                  ),
                ],
                if (task.status == GroupTaskStatus.claimed &&
                    task.assignedTo == currentUserId)
                  _ActionChip(
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => ref
                        .read(groupTasksProvider(groupId).notifier)
                        .updateStatus(task.id, GroupTaskStatus.inProgress),
                  ),
                if (task.status == GroupTaskStatus.inProgress &&
                    task.assignedTo == currentUserId)
                  _ActionChip(
                    label: 'Done',
                    icon: Icons.check_rounded,
                    onTap: () => ref
                        .read(groupTasksProvider(groupId).notifier)
                        .updateStatus(task.id, GroupTaskStatus.done),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignSheet(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.read(groupMembersProvider(groupId));
    final members = membersAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) => AssignTaskSheet(
        members: members,
        onAssign: (userId) {
          ref
              .read(groupTasksProvider(groupId).notifier)
              .assignTask(task.id, userId);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC9A84C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: gold),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final Group group;

  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final currentUser = ref.watch(currentUserProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        final isAdmin =
            members.any((m) => m.userId == currentUser?.id && m.isAdmin);

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = members[index];
            final isCurrentUser = member.userId == currentUser?.id;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: isCurrentUser
                    ? Border.all(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      member.displayName != null && member.displayName!.isNotEmpty
                          ? member.displayName![0].toUpperCase()
                          : '?',
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName ?? 'Unknown',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (member.isAdmin)
                          Text(
                            'Admin',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFFC9A84C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isAdmin && !isCurrentUser)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        if (!member.isAdmin)
                          const PopupMenuItem(
                            value: 'promote',
                            child: Text('Promote to Admin'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'promote') {
                          await ref
                              .read(userGroupsProvider.notifier)
                              .promoteToAdmin(group.id, member.userId);
                          ref.invalidate(groupMembersProvider(group.id));
                        } else if (value == 'remove') {
                          await ref
                              .read(userGroupsProvider.notifier)
                              .removeFromGroup(group.id, member.userId);
                          ref.invalidate(groupMembersProvider(group.id));
                        }
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
