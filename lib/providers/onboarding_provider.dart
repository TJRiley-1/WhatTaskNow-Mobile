import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

class OnboardingState {
  final int currentPage;
  final String? goal;
  final String? energyLevel;
  final Set<String> selectedCategories;
  final bool wantsNotifications;
  final bool isLoading;

  const OnboardingState({
    this.currentPage = 0,
    this.goal,
    this.energyLevel,
    this.selectedCategories = const {},
    this.wantsNotifications = false,
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    String? Function()? goal,
    String? Function()? energyLevel,
    Set<String>? selectedCategories,
    bool? wantsNotifications,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      goal: goal != null ? goal() : this.goal,
      energyLevel: energyLevel != null ? energyLevel() : this.energyLevel,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      wantsNotifications: wantsNotifications ?? this.wantsNotifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    _restoreStep();
    return const OnboardingState();
  }

  Future<void> _restoreStep() async {
    final prefs = await SharedPreferences.getInstance();
    final step = prefs.getInt('onboarding_step') ?? 0;
    if (step > 0) {
      state = state.copyWith(currentPage: step);
    }
  }

  Future<void> _saveStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboarding_step', step);
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    _saveStep(page);
  }

  void setGoal(String goal) {
    state = state.copyWith(goal: () => goal);
  }

  void setEnergyLevel(String level) {
    state = state.copyWith(energyLevel: () => level);
  }

  void toggleCategory(String category) {
    final current = Set<String>.from(state.selectedCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedCategories: current);
  }

  void setNotifications(bool value) {
    state = state.copyWith(wantsNotifications: value);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Save to Supabase
      await Supabase.instance.client.from('profiles').update({
        'onboarding_completed': true,
        'onboarding_goal': state.goal,
        'preferred_categories': state.selectedCategories.toList(),
        'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      // Save local preferences
      final prefs = await SharedPreferences.getInstance();
      if (state.energyLevel != null) {
        await prefs.setString('default_energy_filter', state.energyLevel!);
      }
      await prefs.setBool('wants_notifications', state.wantsNotifications);
      await prefs.remove('onboarding_step');

      // Refresh profile so the gate picks up the change
      ref.invalidate(profileProvider);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

/// Derived provider: has the user completed onboarding?
final onboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).valueOrNull?.onboardingCompleted ?? false;
});
