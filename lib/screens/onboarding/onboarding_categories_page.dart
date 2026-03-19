import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/onboarding_theme.dart';
import '../../models/task.dart';

class OnboardingCategoriesPage extends StatefulWidget {
  final Set<String> selectedCategories;
  final void Function(String category) onToggle;
  final VoidCallback onContinue;

  const OnboardingCategoriesPage({
    super.key,
    required this.selectedCategories,
    required this.onToggle,
    required this.onContinue,
  });

  @override
  State<OnboardingCategoriesPage> createState() =>
      _OnboardingCategoriesPageState();
}

class _OnboardingCategoriesPageState extends State<OnboardingCategoriesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  static const _categoryIcons = <String, IconData>{
    'work': Icons.work_outline,
    'personal': Icons.person_outline,
    'health': Icons.favorite_border,
    'social': Icons.people_outline,
    'errand': Icons.shopping_bag_outlined,
    'other': Icons.more_horiz,
  };

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
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'What kind of tasks pile up?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply — we\'ll suggest some starter tasks.',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: TaskType.values.map((type) {
                final isSelected =
                    widget.selectedCategories.contains(type.name);
                return _CategoryChip(
                  icon: _categoryIcons[type.name] ?? Icons.category,
                  label: type.label,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onToggle(type.name);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: widget.selectedCategories.isNotEmpty
                    ? widget.onContinue
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? OnboardingTheme.gold : cs.onSurface,
                  foregroundColor: isDark ? cs.onPrimary : Colors.white,
                  disabledBackgroundColor:
                      cs.onSurfaceVariant.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? OnboardingTheme.gold.withValues(alpha: 0.1)
                  : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? OnboardingTheme.gold : Colors.transparent,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : icon,
                  size: 20,
                  color: isSelected
                      ? OnboardingTheme.gold
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
