import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/onboarding_theme.dart';

class OnboardingGoalPage extends StatefulWidget {
  final void Function(String goal) onSelected;

  const OnboardingGoalPage({super.key, required this.onSelected});

  @override
  State<OnboardingGoalPage> createState() => _OnboardingGoalPageState();
}

class _OnboardingGoalPageState extends State<OnboardingGoalPage>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _fadeController;

  static const _goals = [
    (
      key: 'task_paralysis',
      icon: Icons.all_inclusive,
      title: "Too many tasks, don't know where to start",
    ),
    (
      key: 'focus',
      icon: Icons.center_focus_strong,
      title: 'I struggle to focus once I pick something',
    ),
    (
      key: 'memory',
      icon: Icons.lightbulb_outline,
      title: 'I forget tasks unless I write them down',
    ),
    (
      key: 'simplicity',
      icon: Icons.auto_awesome,
      title: 'I want a simpler way to manage my day',
    ),
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
    if (_selected != null) return; // prevent double-tap
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
              'What brings you here?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: OnboardingTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No wrong answers — this helps us personalise your experience.',
              style: TextStyle(
                fontSize: 16,
                color: OnboardingTheme.grey,
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(_goals.length, (i) {
              final goal = _goals[i];
              final isSelected = _selected == goal.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(
                  icon: goal.icon,
                  title: goal.title,
                  isSelected: isSelected,
                  onTap: () => _select(goal.key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.title,
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
            ? OnboardingTheme.orange.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? OnboardingTheme.orange : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : icon,
                  color: isSelected ? OnboardingTheme.orange : OnboardingTheme.teal,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: OnboardingTheme.navy,
                    ),
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
