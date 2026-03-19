import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
import '../../providers/premium_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrJoin(context),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_outlined,
                        size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No groups yet',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Create a group or join one with an invite code',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 8, bottom: 96),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(group: group);
            },
          );
        },
      ),
    );
  }

  void _showCreateOrJoin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _CreateOrJoinSheet(),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final Group group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const gold = Color(0xFFC9A84C);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (group.isEventDriven) {
            context.push('/group-detail', extra: group);
          } else {
            context.push('/leaderboard', extra: group);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  group.name[0].toUpperCase(),
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(group.name,
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: group.isEventDriven
                                ? gold.withValues(alpha: 0.12)
                                : theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            group.groupType.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: group.isEventDriven
                                  ? gold
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (group.description != null)
                      Text(group.description!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy invite code',
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: group.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Invite code copied: ${group.inviteCode}')),
                  );
                },
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateOrJoinSheet extends ConsumerStatefulWidget {
  const _CreateOrJoinSheet();

  @override
  ConsumerState<_CreateOrJoinSheet> createState() => _CreateOrJoinSheetState();
}

class _CreateOrJoinSheetState extends ConsumerState<_CreateOrJoinSheet> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  bool _isCreate = false;
  bool _isLoading = false;

  // Create-mode fields
  GroupType _groupType = GroupType.friendsFamily;
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;
  LeaderboardMetric _metric = LeaderboardMetric.points;
  DateTime? _eventDate;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final error =
        await ref.read(userGroupsProvider.notifier).joinByCode(code);
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined group!')));
      }
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Premium gate for event groups
    if (_groupType == GroupType.eventDriven) {
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event groups require a premium subscription')),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(userGroupsProvider.notifier).createGroup(
            name: name,
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            groupType: _groupType,
            eventDate: _groupType == GroupType.eventDriven ? _eventDate : null,
            leaderboardPeriod: _period,
            leaderboardMetric: _metric,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Join')),
              ButtonSegment(value: true, label: Text('Create')),
            ],
            selected: {_isCreate},
            onSelectionChanged: (s) =>
                setState(() => _isCreate = s.first),
          ),
          const SizedBox(height: 24),
          if (!_isCreate) ...[
            Text('Enter Invite Code',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            AppTextField(
              controller: _codeController,
              labelText: 'Invite Code',
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Join Group',
              isLoading: _isLoading,
              onPressed: _join,
            ),
          ] else ...[
            Text('Create New Group',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Group type selection
            Text('Group Type',
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            SegmentedButton<GroupType>(
              segments: [
                ButtonSegment(
                  value: GroupType.friendsFamily,
                  label: Text('Friends & Family',
                      style: GoogleFonts.dmSans(fontSize: 12)),
                ),
                ButtonSegment(
                  value: GroupType.eventDriven,
                  label:
                      Text('Event', style: GoogleFonts.dmSans(fontSize: 12)),
                ),
              ],
              selected: {_groupType},
              onSelectionChanged: (s) =>
                  setState(() => _groupType = s.first),
            ),

            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              labelText: 'Group Name',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descController,
              labelText: 'Description (optional)',
              textInputAction: TextInputAction.done,
            ),

            // Event-specific: event date
            if (_groupType == GroupType.eventDriven) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _eventDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        _eventDate != null
                            ? 'Event: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                            : 'Set event date (optional)',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: _eventDate != null
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // F&F-specific: period + metric
            if (_groupType == GroupType.friendsFamily) ...[
              const SizedBox(height: 12),
              Text('Leaderboard Period',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              SegmentedButton<LeaderboardPeriod>(
                segments: LeaderboardPeriod.values
                    .map((p) => ButtonSegment(
                          value: p,
                          label: Text(p.label,
                              style: GoogleFonts.dmSans(fontSize: 12)),
                        ))
                    .toList(),
                selected: {_period},
                onSelectionChanged: (s) =>
                    setState(() => _period = s.first),
              ),
              const SizedBox(height: 12),
              Text('Leaderboard Metric',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              SegmentedButton<LeaderboardMetric>(
                segments: LeaderboardMetric.values
                    .map((m) => ButtonSegment(
                          value: m,
                          label: Text(m.label,
                              style: GoogleFonts.dmSans(fontSize: 12)),
                        ))
                    .toList(),
                selected: {_metric},
                onSelectionChanged: (s) =>
                    setState(() => _metric = s.first),
              ),
            ],

            const SizedBox(height: 20),
            AppButton(
              label: 'Create Group',
              isLoading: _isLoading,
              onPressed: _create,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
