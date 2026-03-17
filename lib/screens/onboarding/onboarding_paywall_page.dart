import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';

class OnboardingPaywallPage extends StatefulWidget {
  final String? goal;
  final VoidCallback onStartTrial;
  final VoidCallback onContinueFree;

  const OnboardingPaywallPage({
    super.key,
    this.goal,
    required this.onStartTrial,
    required this.onContinueFree,
  });

  @override
  State<OnboardingPaywallPage> createState() => _OnboardingPaywallPageState();
}

class _OnboardingPaywallPageState extends State<OnboardingPaywallPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  int _selectedPlan = 1; // 0=monthly, 1=yearly, 2=lifetime

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _subtitle {
    return switch (widget.goal) {
      'task_paralysis' =>
        'The What Now? swipe was made for people who struggle to pick what to do.',
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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: OnboardingTheme.navy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: OnboardingTheme.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Features
            ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: OnboardingTheme.teal, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        f,
                        style: TextStyle(
                          fontSize: 16,
                          color: OnboardingTheme.navy,
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Pricing options
            _PricingOption(
              label: 'Monthly',
              price: '\u00A33.99/mo',
              isSelected: _selectedPlan == 0,
              onTap: () => setState(() => _selectedPlan = 0),
            ),
            const SizedBox(height: 8),
            _PricingOption(
              label: 'Yearly',
              price: '\u00A329.99/yr',
              badge: 'Save 37%',
              isSelected: _selectedPlan == 1,
              onTap: () => setState(() => _selectedPlan = 1),
            ),
            const SizedBox(height: 8),
            _PricingOption(
              label: 'Lifetime',
              price: '\u00A359.99',
              badge: 'Best value',
              isSelected: _selectedPlan == 2,
              onTap: () => setState(() => _selectedPlan = 2),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: widget.onStartTrial,
                style: FilledButton.styleFrom(
                  backgroundColor: OnboardingTheme.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Start Free Trial'),
              ),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onContinueFree,
              child: Text(
                'Continue with free plan',
                style: TextStyle(
                  fontSize: 14,
                  color: OnboardingTheme.grey,
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
    'Unlimited tasks',
    'No ads',
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? OnboardingTheme.orange.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? OnboardingTheme.orange : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? OnboardingTheme.orange
                      : OnboardingTheme.grey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: OnboardingTheme.navy,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: OnboardingTheme.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OnboardingTheme.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OnboardingTheme.navy,
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
