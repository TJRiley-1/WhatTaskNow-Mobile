import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final Group group;

  const LeaderboardScreen({super.key, required this.group});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late LeaderboardPeriod _period;
  late LeaderboardMetric _metric;

  @override
  void initState() {
    super.initState();
    _period = widget.group.leaderboardPeriod;
    _metric = widget.group.leaderboardMetric;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const gold = Color(0xFFC9A84C);

    final leaderboardAsync = ref.watch(leaderboardProvider((
      groupId: widget.group.id,
      period: _period.name,
      metric: _metric.name,
    )));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share invite code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.group.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Invite code copied: ${widget.group.inviteCode}')),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave Group'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'leave') {
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
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHighest
                    : const Color(0xFFF2EFE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: LeaderboardPeriod.values.map((p) {
                  final selected = p == _period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? (isDark ? gold : cs.onSurface)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          p.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? (isDark ? cs.onPrimary : Colors.white)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Metric indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ranked by: ',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
                Text(
                  _metric.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: leaderboardAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.leaderboard_outlined,
                              size: 64, color: cs.outline),
                          const SizedBox(height: 16),
                          Text('No activity this ${_period.name}',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                              'Complete tasks to appear on the leaderboard',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isCurrentUser = entry.userId == currentUser?.id;
                    final rank = index + 1;

                    return Card(
                      color: isCurrentUser
                          ? cs.primaryContainer.withValues(alpha: 0.3)
                          : null,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                rank <= 3
                                    ? ['🥇', '🥈', '🥉'][rank - 1]
                                    : '#$rank',
                                style: rank <= 3
                                    ? const TextStyle(fontSize: 24)
                                    : theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 20,
                              child: Text(
                                entry.displayName != null && entry.displayName!.isNotEmpty
                                    ? entry.displayName![0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.displayName ?? 'Unknown',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    entry.currentRank ?? '',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${entry.score}',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${entry.periodTasks} tasks',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
