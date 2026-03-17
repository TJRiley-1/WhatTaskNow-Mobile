import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/onboarding_theme.dart';

class OnboardingEnergyPage extends StatefulWidget {
  final void Function(String level) onSelected;

  const OnboardingEnergyPage({super.key, required this.onSelected});

  @override
  State<OnboardingEnergyPage> createState() => _OnboardingEnergyPageState();
}

class _OnboardingEnergyPageState extends State<OnboardingEnergyPage>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _fadeController;

  static const _levels = [
    (key: 'low', icon: Icons.battery_1_bar, label: 'Low', description: "I'm dragging a bit"),
    (key: 'medium', icon: Icons.battery_4_bar, label: 'Medium', description: "I'm alright"),
    (key: 'high', icon: Icons.battery_full, label: 'High', description: "Let's go!"),
  ];

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

  void _select(String key) {
    if (_selected != null) return;
    setState(() => _selected = key);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onSelected(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              "How's your energy right now?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: OnboardingTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We'll match tasks to how you're feeling.",
              style: TextStyle(
                fontSize: 16,
                color: OnboardingTheme.grey,
              ),
            ),
            const SizedBox(height: 40),
            ..._levels.map((level) {
              final isSelected = _selected == level.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _EnergyCard(
                  icon: level.icon,
                  label: level.label,
                  description: level.description,
                  isSelected: isSelected,
                  onTap: () => _select(level.key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnergyCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? OnboardingTheme.teal.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? OnboardingTheme.teal : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : icon,
                  color: isSelected ? OnboardingTheme.teal : OnboardingTheme.navy,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: OnboardingTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: OnboardingTheme.grey,
                        ),
                      ),
                    ],
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
