import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class CelebrationScreen extends StatefulWidget {
  final String taskName;
  final int points;
  final int timeSpent;

  const CelebrationScreen({
    super.key,
    required this.taskName,
    required this.points,
    required this.timeSpent,
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fireworkController;
  late final AnimationController _contentController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _fireworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = CurvedAnimation(
      parent: _contentController,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    );

    // Generate particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        color: [
          const Color(0xFFFF6B6B),
          const Color(0xFFFFD93D),
          const Color(0xFF6BCB77),
          const Color(0xFF4D96FF),
          const Color(0xFFB983FF),
          const Color(0xFFFF9F45),
        ][_random.nextInt(6)],
        startX: 0.5,
        startY: 0.4,
        velocityX: (_random.nextDouble() - 0.5) * 2,
        velocityY: (_random.nextDouble() - 0.8) * 2,
        size: _random.nextDouble() * 8 + 4,
      ));
    }

    _fireworkController.forward();
    // Celebration haptic burst
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _fireworkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = widget.timeSpent >= 60
        ? '${widget.timeSpent ~/ 60}hr ${widget.timeSpent % 60}min'
        : '${widget.timeSpent}min';

    return Scaffold(
      body: Stack(
        children: [
          // Firework particles
          AnimatedBuilder(
            animation: _fireworkController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _FireworkPainter(
                  particles: _particles,
                  progress: _fireworkController.value,
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Task Complete!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.taskName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '+${widget.points}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'points earned',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Time spent: $timeLabel',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 40),
                        FilledButton(
                          onPressed: () => context.go('/'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(200, 52),
                          ),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;

  _Particle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.size,
  });
}

class _FireworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _FireworkPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final gravity = 0.5 * progress * progress;
      final x = size.width * p.startX + p.velocityX * progress * size.width * 0.4;
      final y = size.height * p.startY +
          p.velocityY * progress * size.height * 0.3 +
          gravity * size.height * 0.3;

      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
