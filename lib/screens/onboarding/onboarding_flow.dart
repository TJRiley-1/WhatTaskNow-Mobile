import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/onboarding_theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_welcome_page.dart';
import 'onboarding_goal_page.dart';
import 'onboarding_energy_page.dart';
import 'onboarding_categories_page.dart';
import 'onboarding_notifications_page.dart';
import 'onboarding_paywall_page.dart';
import 'onboarding_first_task_page.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final PageController _pageController;
  static const _totalPages = 7;

  // Pages that can be skipped (indices 1-4 → screens 2-5)
  static const _skippablePages = {1, 2, 3, 4};
  static const _paywallPage = 5;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(onboardingProvider).currentPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    ref.read(onboardingProvider.notifier).setPage(page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < _totalPages - 1) {
      _goToPage(current + 1);
    }
  }

  void _skip() {
    _goToPage(_paywallPage);
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar + skip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (state.currentPage + 1) / _totalPages,
                        backgroundColor:
                            OnboardingTheme.grey.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            OnboardingTheme.orange),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  if (_skippablePages.contains(state.currentPage))
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: OnboardingTheme.grey,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60), // maintain layout
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).setPage(page);
                },
                children: [
                  // Screen 1: Welcome
                  OnboardingWelcomePage(onContinue: _nextPage),

                  // Screen 2: Goal
                  OnboardingGoalPage(
                    onSelected: (goal) {
                      ref.read(onboardingProvider.notifier).setGoal(goal);
                      _nextPage();
                    },
                  ),

                  // Screen 3: Energy
                  OnboardingEnergyPage(
                    onSelected: (level) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setEnergyLevel(level);
                      _nextPage();
                    },
                  ),

                  // Screen 4: Categories
                  OnboardingCategoriesPage(
                    selectedCategories: state.selectedCategories,
                    onToggle: (cat) {
                      ref
                          .read(onboardingProvider.notifier)
                          .toggleCategory(cat);
                    },
                    onContinue: _nextPage,
                  ),

                  // Screen 5: Notifications
                  OnboardingNotificationsPage(
                    onSelected: (wants) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setNotifications(wants);
                      _nextPage();
                    },
                  ),

                  // Screen 6: Paywall
                  OnboardingPaywallPage(
                    goal: state.goal,
                    onStartTrial: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon — trial will start here'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      _nextPage();
                    },
                    onContinueFree: _nextPage,
                  ),

                  // Screen 7: First task
                  OnboardingFirstTaskPage(
                    onTaskCreated: _finishOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
