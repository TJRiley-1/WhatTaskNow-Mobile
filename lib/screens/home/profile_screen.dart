import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/ranks.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);
    final goldLight = const Color(0xFFE8C96A);

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
                  Text('Profile',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      )),
                  const SizedBox(height: 28),

                  // Gold gradient avatar with shadow
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [gold, goldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (profile.displayName ?? '?')[0].toUpperCase(),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Playfair name
                  Text(
                    profile.displayName ?? 'Unknown',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // DM Sans email
                  Text(
                    profile.email ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Rank + premium badges
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.currentRank,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: gold,
                            ),
                          ),
                        ),
                        if (profile.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium,
                                    size: 14, color: gold),
                                const SizedBox(width: 4),
                                Text('Premium',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: gold,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Stat boxes row
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          value: '${profile.totalPoints}',
                          label: 'POINTS',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          value: '${profile.totalTasksCompleted}',
                          label: 'COMPLETED',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          value: '${(profile.totalTimeSpent / 60).floor()}',
                          label: 'HOURS',
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
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Next: ${next.name}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  )),
                              Text(
                                  '${next.minPoints - profile.totalPoints} pts to go',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  )),
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

                  // Settings items
                  _SettingsItem(
                    icon: Icons.group_rounded,
                    label: 'Groups & Leaderboards',
                    onTap: () => context.push('/groups'),
                  ),
                  const SizedBox(height: 10),

                  // Theme toggle
                  _ThemeToggle(),
                  if (!profile.isPremium) ...[
                    const SizedBox(height: 10),
                    _SettingsItem(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Upgrade to Premium',
                      onTap: () => context.push('/premium'),
                      accent: true,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _SettingsItem(
                    icon: Icons.replay_rounded,
                    label: 'Redo Onboarding',
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Redo Onboarding?'),
                          content: const Text(
                              'This will take you through the setup flow again.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        // Reset onboarding flags
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', false);
                        await prefs.remove('onboarding_step');
                        try {
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            await Supabase.instance.client
                                .from('profiles')
                                .update({'onboarding_completed': false})
                                .eq('id', user.id);
                          }
                        } catch (_) {}
                        if (context.mounted) {
                          ref.invalidate(profileProvider);
                          context.go('/onboarding');
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Sign out
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      child: Text('Sign Out',
                          style: GoogleFonts.dmSans(
                              color: cs.onSurfaceVariant)),
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

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 1.2,
              )),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);
    final iconColor = accent ? gold : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
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

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = ref.watch(themeModeProvider);
    final gold = const Color(0xFFC9A84C);

    final (icon, label) = switch (mode) {
      ThemeMode.system => (Icons.brightness_auto_rounded, 'System'),
      ThemeMode.light => (Icons.light_mode_rounded, 'Light'),
      ThemeMode.dark => (Icons.dark_mode_rounded, 'Dark'),
    };

    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).cycle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Appearance',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  )),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gold,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
