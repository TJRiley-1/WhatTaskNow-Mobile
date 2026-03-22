import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/premium_provider.dart';
import '../services/revenue_cat_service.dart';

/// Shows trial countdown or "Trial ended" CTA.
/// Only visible during trial or when trial has just expired.
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionStatusProvider);
    final trialEnd = ref.watch(trialEndDateProvider);
    final cs = Theme.of(context).colorScheme;
    const gold = Color(0xFFC9A84C);

    if (status == SubscriptionStatus.trial && trialEnd != null) {
      final daysLeft = trialEnd.difference(DateTime.now()).inDays;
      final label = daysLeft <= 0
          ? 'Trial ends today'
          : '$daysLeft day${daysLeft == 1 ? '' : 's'} left in trial';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_bottom_rounded, size: 18, color: gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: gold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/premium'),
              child: Text(
                'Subscribe',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == SubscriptionStatus.expired) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your trial has ended',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/premium'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Subscribe',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
