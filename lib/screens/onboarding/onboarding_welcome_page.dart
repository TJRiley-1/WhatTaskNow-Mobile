import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/onboarding_theme.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingWelcomePage({super.key, required this.onContinue});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = OnboardingTheme.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Animated card stack
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                return _CardStack(progress: _cardController.value);
              },
            ),
          ),

          const SizedBox(height: 40),

          // Logo text
          FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                Text(
                  'WHAT NOW?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Stop overthinking. Start doing.',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 3),

          // Continue button
          FadeTransition(
            opacity: _fadeController,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: widget.onContinue,
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
                child: const Text("Let's get you set up"),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _CardStack extends StatelessWidget {
  final double progress;

  const _CardStack({required this.progress});

  @override
  Widget build(BuildContext context) {
    final curve = Curves.easeInOut.transform(progress);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Back card (left)
        Transform.translate(
          offset: Offset(-60.0 * (1 - curve), -20.0 * (1 - curve)),
          child: Transform.rotate(
            angle: -0.15 * (1 - curve),
            child: _buildCard(
                OnboardingTheme.goldLight.withValues(alpha: 0.3 + 0.7 * curve)),
          ),
        ),
        // Back card (right)
        Transform.translate(
          offset: Offset(60.0 * (1 - curve), -10.0 * (1 - curve)),
          child: Transform.rotate(
            angle: 0.12 * (1 - curve),
            child: _buildCard(
                OnboardingTheme.gold.withValues(alpha: 0.3 + 0.7 * curve)),
          ),
        ),
        // Front card (center)
        _buildCard(OnboardingTheme.gold),
      ],
    );
  }

  Widget _buildCard(Color color) {
    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: 36,
        ),
      ),
    );
  }
}
