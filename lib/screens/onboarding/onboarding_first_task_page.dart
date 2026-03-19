import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/onboarding_theme.dart';
import '../../config/task_templates.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingFirstTaskPage extends ConsumerStatefulWidget {
  final VoidCallback onTaskCreated;

  const OnboardingFirstTaskPage({super.key, required this.onTaskCreated});

  @override
  ConsumerState<OnboardingFirstTaskPage> createState() =>
      _OnboardingFirstTaskPageState();
}

class _OnboardingFirstTaskPageState
    extends ConsumerState<OnboardingFirstTaskPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  int _time = 15;
  Level _energy = Level.low;
  String _type = 'personal';
  bool _isLoading = false;
  late final AnimationController _fadeController;

  static const _timeOptions = [5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    final categories =
        ref.read(onboardingProvider).selectedCategories;
    if (categories.isNotEmpty) {
      _type = categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<TaskTemplate> get _suggestions {
    final categories =
        ref.read(onboardingProvider).selectedCategories;
    return getTemplateSuggestions(
      categories.isNotEmpty ? categories.toList() : null,
    );
  }

  void _fillFromTemplate(TaskTemplate template) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = template.name;
      _time = template.time;
      _energy = template.energy;
      _type = template.type;
    });
  }

  Future<void> _createTask() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your task a name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(taskListProvider.notifier).addTask(
            name: name,
            typeString: _type,
            time: _time,
            social: Level.low,
            energy: _energy,
          );
      HapticFeedback.mediumImpact();
      widget.onTaskCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);
    final suggestions = _suggestions;

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Add your first task',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Something small — you can always add more later.",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Task name input
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _createTask(),
              decoration: InputDecoration(
                hintText: 'What do you need to do?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: OnboardingTheme.gold, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Time estimate
            Text(
              'How long will it take?',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _timeOptions.map((t) {
                final label = t >= 60 ? '${t ~/ 60}hr' : '${t}min';
                return ChoiceChip(
                  label: Text(label),
                  selected: _time == t,
                  onSelected: (_) => setState(() => _time = t),
                  selectedColor: OnboardingTheme.gold.withValues(alpha: 0.2),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Energy level
            Text(
              'Energy needed?',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<Level>(
              segments: Level.values
                  .map((l) => ButtonSegment(value: l, label: Text(l.label)))
                  .toList(),
              selected: {_energy},
              onSelectionChanged: (s) => setState(() => _energy = s.first),
            ),

            const SizedBox(height: 28),

            // Template suggestions
            if (suggestions.isNotEmpty) ...[
              Text(
                'Or pick from suggestions',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...suggestions.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TemplateTile(
                      template: t,
                      onTap: () => _fillFromTemplate(t),
                    ),
                  )),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _createTask,
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
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Task'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final TaskTemplate template;
  final VoidCallback onTap;

  const _TemplateTile({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);
    final timeLabel =
        template.time >= 60 ? '${template.time ~/ 60}hr' : '${template.time}min';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.add_circle_outline,
                  size: 20, color: OnboardingTheme.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  template.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
