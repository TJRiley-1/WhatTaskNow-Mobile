import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';

class OnboardingNotificationsPage extends StatefulWidget {
  final void Function(bool wantsNotifications) onSelected;

  const OnboardingNotificationsPage({super.key, required this.onSelected});

  @override
  State<OnboardingNotificationsPage> createState() =>
      _OnboardingNotificationsPageState();
}

class _OnboardingNotificationsPageState
    extends State<OnboardingNotificationsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

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
              'One last thing — reminders',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: OnboardingTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gentle reminders to keep you on track.',
              style: TextStyle(
                fontSize: 16,
                color: OnboardingTheme.grey,
              ),
            ),
            const Spacer(flex: 2),

            // Notification illustration
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: OnboardingTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 64,
                      color: OnboardingTheme.teal,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 20, color: OnboardingTheme.orange),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              "Hey, you've got this. Time for your next task.",
                              style: TextStyle(
                                fontSize: 14,
                                color: OnboardingTheme.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 3),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => widget.onSelected(true),
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
                child: const Text('Yes, remind me'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => widget.onSelected(false),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    fontSize: 16,
                    color: OnboardingTheme.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
