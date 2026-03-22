import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../config/onboarding_theme.dart';
import '../../services/revenue_cat_service.dart';

class OnboardingPaywallPage extends ConsumerStatefulWidget {
  final String? goal;
  final VoidCallback onPurchaseSuccess;
  final VoidCallback onContinueFree;

  const OnboardingPaywallPage({
    super.key,
    this.goal,
    required this.onPurchaseSuccess,
    required this.onContinueFree,
  });

  @override
  ConsumerState<OnboardingPaywallPage> createState() =>
      _OnboardingPaywallPageState();
}

class _OnboardingPaywallPageState
    extends ConsumerState<OnboardingPaywallPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  int _selectedPlan = 1; // 0=monthly, 1=yearly, 2=lifetime
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadOfferings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
      debugPrint('Paywall: error loading offerings: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _priceForIndex(int index) {
    if (_packages.isEmpty) {
      // Fallback prices if RC not configured yet
      return switch (index) {
        0 => '\u00A33.99/mo',
        1 => '\u00A329.99/yr',
        2 => '\u00A359.99',
        _ => '',
      };
    }
    // Map by package type
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
    if (package == null) {
      // RC not configured — proceed anyway (dev mode)
      widget.onPurchaseSuccess();
      return;
    }

    setState(() => _purchasing = true);
    try {
      final success =
          await RevenueCatService.instance.purchasePackage(package);
      if (mounted) {
        if (success) {
          widget.onPurchaseSuccess();
        } else {
          // Purchase was cancelled — stay on page
          setState(() => _purchasing = false);
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

  String get _subtitle {
    return switch (widget.goal) {
      'task_paralysis' =>
        'What Now? was made for people who struggle to pick what to do.',
      'focus' =>
        'The focus timer helps you stay on track once you pick a task.',
      'memory' =>
        'Quick-add tasks so nothing slips through the cracks.',
      'simplicity' =>
        'One task at a time. No complicated lists or settings.',
      _ => 'Everything you need to get things done, one task at a time.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              'Try Whatnow Premium\nfree for 7 days',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Features
            ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: OnboardingTheme.gold, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        f,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else ...[
              // Pricing options
              _PricingOption(
                label: 'Monthly',
                price: _priceForIndex(0),
                isSelected: _selectedPlan == 0,
                onTap: () => setState(() => _selectedPlan = 0),
              ),
              const SizedBox(height: 8),
              _PricingOption(
                label: 'Yearly',
                price: _priceForIndex(1),
                badge: 'Save 37%',
                isSelected: _selectedPlan == 1,
                onTap: () => setState(() => _selectedPlan = 1),
              ),
              const SizedBox(height: 8),
              _PricingOption(
                label: 'Lifetime',
                price: _priceForIndex(2),
                badge: 'Best value',
                isSelected: _selectedPlan == 2,
                onTap: () => setState(() => _selectedPlan = 2),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _purchasing ? null : _handlePurchase,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? OnboardingTheme.gold : cs.onSurface,
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
            TextButton(
              onPressed: widget.onContinueFree,
              child: Text(
                'Continue with free plan',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static const _features = [
    'What Now? swipe',
    'Focus timer',
    'No ads',
    'Create event groups',
  ];
}

class _PricingOption extends StatelessWidget {
  final String label;
  final String price;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingOption({
    required this.label,
    required this.price,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? OnboardingTheme.gold.withValues(alpha: 0.08)
            : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? OnboardingTheme.gold : Colors.transparent,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? OnboardingTheme.gold
                      : cs.onSurfaceVariant,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          OnboardingTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OnboardingTheme.gold,
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
        ),
      ),
    );
  }
}
