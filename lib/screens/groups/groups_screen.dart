import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/leaderboard', extra: group),
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
                    Text(group.name,
                        style: theme.textTheme.titleMedium),
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

    setState(() => _isLoading = true);
    try {
      await ref.read(userGroupsProvider.notifier).createGroup(
            name,
            _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
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
