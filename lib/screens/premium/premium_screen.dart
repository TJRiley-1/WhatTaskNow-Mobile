import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/premium_provider.dart';
import '../../services/revenue_cat_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  int _selectedPlan = 1;
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await RevenueCatService.instance.getOfferings();
      final current = offerings?.current;
      if (current != null && mounted) {
        setState(() {
          _packages = current.availablePackages;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _priceForIndex(int index) {
    if (_packages.isEmpty) {
      return switch (index) {
        0 => '\u00A33.99/mo',
        1 => '\u00A329.99/yr',
        2 => '\u00A359.99',
        _ => '',
      };
    }
    for (final pkg in _packages) {
      if (index == 0 && pkg.packageType == PackageType.monthly) {
        return pkg.storeProduct.priceString;
      }
      if (index == 1 && pkg.packageType == PackageType.annual) {
        return pkg.storeProduct.priceString;
      }
      if (index == 2 && pkg.packageType == PackageType.lifetime) {
        return pkg.storeProduct.priceString;
      }
    }
    return switch (index) {
      0 => '\u00A33.99/mo',
      1 => '\u00A329.99/yr',
      2 => '\u00A359.99',
      _ => '',
    };
  }

  Package? _selectedPackage() {
    if (_packages.isEmpty) return null;
    final targetType = switch (_selectedPlan) {
      0 => PackageType.monthly,
      1 => PackageType.annual,
      2 => PackageType.lifetime,
      _ => PackageType.annual,
    };
    try {
      return _packages.firstWhere((p) => p.packageType == targetType);
    } catch (_) {
      return _packages.first;
    }
  }

  Future<void> _handlePurchase() async {
    final package = _selectedPackage();
    if (package == null) return;

    setState(() => _purchasing = true);
    try {
      final success =
          await RevenueCatService.instance.purchasePackage(package);
      if (mounted) {
        setState(() => _purchasing = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to Premium!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _restoring = true);
    try {
      final restored = await RevenueCatService.instance.restorePurchases();
      if (mounted) {
        setState(() => _restoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restored
                ? 'Purchases restored!'
                : 'No previous purchases found.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _restoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = ref.watch(isPremiumProvider);
    final status = ref.watch(subscriptionStatusProvider);
    const gold = Color(0xFFC9A84C);

    if (isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, size: 64, color: gold),
                const SizedBox(height: 16),
                Text(
                  "You're a Premium member!",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == SubscriptionStatus.trial
                      ? 'Enjoying your free trial'
                      : 'Full access to all features',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.workspace_premium, size: 72, color: gold),
            const SizedBox(height: 24),
            Text(
              'Unlock Whatnow Premium',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '7-day free trial, cancel anytime',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _FeatureRow(
              icon: Icons.shuffle_rounded,
              title: 'What Now? Swipe',
              subtitle: 'Let the app pick your next task',
            ),
            const SizedBox(height: 16),
            _FeatureRow(
              icon: Icons.timer_rounded,
              title: 'Focus Timer',
              subtitle: 'Stay on track with timed focus sessions',
            ),
            const SizedBox(height: 16),
            _FeatureRow(
              icon: Icons.block,
              title: 'No Ads',
              subtitle: 'Clean, distraction-free experience',
            ),
            const SizedBox(height: 16),
            _FeatureRow(
              icon: Icons.group_rounded,
              title: 'Create Event Groups',
              subtitle: 'Organise group tasks for events and projects',
            ),
            const SizedBox(height: 32),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _PlanOption(
                label: 'Monthly',
                price: _priceForIndex(0),
                isSelected: _selectedPlan == 0,
                onTap: () => setState(() => _selectedPlan = 0),
              ),
              const SizedBox(height: 8),
              _PlanOption(
                label: 'Yearly',
                price: _priceForIndex(1),
                badge: 'Save 37%',
                isSelected: _selectedPlan == 1,
                onTap: () => setState(() => _selectedPlan = 1),
              ),
              const SizedBox(height: 8),
              _PlanOption(
                label: 'Lifetime',
                price: _priceForIndex(2),
                badge: 'Best value',
                isSelected: _selectedPlan == 2,
                onTap: () => setState(() => _selectedPlan = 2),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _purchasing ? null : _handlePurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? gold : cs.onSurface,
                  foregroundColor: isDark ? cs.onPrimary : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Start Free Trial'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _restoring ? null : _handleRestore,
                child: _restoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Restore Purchases',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const gold = Color(0xFFC9A84C);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: gold),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  )),
              Text(subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String label;
  final String price;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.label,
    required this.price,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const gold = Color(0xFFC9A84C);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? gold.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? gold : Colors.transparent,
            width: 2,
          ),
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
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? gold : cs.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              price,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
