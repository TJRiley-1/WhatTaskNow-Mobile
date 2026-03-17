import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/ranks.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profile', style: theme.appBarTheme.titleTextStyle),
                  const SizedBox(height: 28),

                  // Avatar
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFD4A853)
                              : cs.primary,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: cs.surface,
                        child: Text(
                          (profile.displayName ?? '?')[0].toUpperCase(),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName ?? 'Unknown',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email ?? '',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Rank badge
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.currentRank,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.secondary,
                            ),
                          ),
                        ),
                        if (profile.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFD4A853)
                                      .withValues(alpha: 0.15)
                                  : cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium,
                                    size: 14,
                                    color: isDark
                                        ? const Color(0xFFD4A853)
                                        : cs.primary),
                                const SizedBox(width: 4),
                                Text('Premium',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFD4A853)
                                          : cs.primary,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Stats row — colored containers
                  Row(
                    children: [
                      Expanded(
                        child: _StatContainer(
                          value: '${profile.totalPoints}',
                          label: 'Points',
                          color: cs.primary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatContainer(
                          value: '${profile.totalTasksCompleted}',
                          label: 'Completed',
                          color: cs.secondary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatContainer(
                          value: '${(profile.totalTimeSpent / 60).floor()}',
                          label: 'Hours',
                          color: cs.onSurface,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress to next rank
                  Builder(builder: (context) {
                    final next = nextRank(profile.totalPoints);
                    if (next == null) return const SizedBox.shrink();
                    final prevMin = ranks
                        .lastWhere(
                            (r) => r.minPoints <= profile.totalPoints)
                        .minPoints;
                    final progress = (profile.totalPoints - prevMin) /
                        (next.minPoints - prevMin);
                    return Container(
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
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Next: ${next.name}',
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              Text(
                                  '${next.minPoints - profile.totalPoints} pts to go',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Groups card
                  _NavCard(
                    icon: Icons.group_rounded,
                    label: 'Groups & Leaderboards',
                    onTap: () => context.push('/groups'),
                  ),
                  if (!profile.isPremium) ...[
                    const SizedBox(height: 10),
                    _NavCard(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Upgrade to Premium',
                      onTap: () => context.push('/premium'),
                      accent: true,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Sign out
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      child: Text('Sign Out',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatContainer extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatContainer({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.15 : 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.7),
              )),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = accent
        ? (isDark ? const Color(0xFFD4A853) : cs.primary)
        : cs.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: borderColor == cs.outline
                ? cs.onSurfaceVariant
                : borderColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  )),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
