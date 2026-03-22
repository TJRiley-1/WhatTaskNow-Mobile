import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';

class SwipeCard extends StatefulWidget {
  final Task task;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  const SwipeCard({
    super.key,
    required this.task,
    this.currentIndex = 0,
    this.totalCount = 1,
    required this.onAccept,
    required this.onSkip,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  Offset _offset = Offset.zero;
  bool _userHasInteracted = false;
  bool _hapticFired = false;

  static const _threshold = 100.0;

  // Idle hint animation
  AnimationController? _hintController;
  Animation<double>? _hintAnimation;

  @override
  void initState() {
    super.initState();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _hintController = controller;
    // Sway: 0 → right → 0 → left → 0
    _hintAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 30), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 30, end: 0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0, end: -30), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -30, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    // Start hint after 3 seconds of idle
    _scheduleHint();
  }

  void _scheduleHint() {
    Future.delayed(const Duration(seconds: 3), () {
      _playHintLoop();
    });
  }

  void _playHintLoop() {
    if (!mounted || _userHasInteracted || _hintController == null) return;
    _hintController!.forward(from: 0).then((_) {
      if (!mounted || _userHasInteracted) return;
      Future.delayed(const Duration(seconds: 3), () {
        _playHintLoop();
      });
    });
  }

  @override
  void dispose() {
    _hintController?.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!_userHasInteracted) {
      _userHasInteracted = true;
      _hintController?.stop();
      _hintController?.reset();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
    // Haptic when crossing threshold
    if (_offset.dx.abs() > _threshold && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    } else if (_offset.dx.abs() < _threshold && _hapticFired) {
      _hapticFired = false;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_offset.dx > _threshold) {
      _animateOff(1);
    } else if (_offset.dx < -_threshold) {
      _animateOff(-1);
    } else {
      // Snap back with light haptic
      HapticFeedback.selectionClick();
      setState(() {
        _offset = Offset.zero;
      });
    }
  }

  void _animateOff(int direction) {
    HapticFeedback.lightImpact();
    setState(() {
      _offset = Offset(direction * 500, _offset.dy);
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (direction > 0) {
        widget.onAccept();
      } else {
        widget.onSkip();
      }
    });
  }

  IconData _typeIcon(TaskType type) {
    return switch (type) {
      TaskType.work => Icons.work_outline_rounded,
      TaskType.personal => Icons.home_outlined,
      TaskType.health => Icons.fitness_center_rounded,
      TaskType.social => Icons.people_outline_rounded,
      TaskType.errand => Icons.shopping_cart_outlined,
      TaskType.other => Icons.push_pin_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = widget.task;
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';

    final gold = isDark ? const Color(0xFFC9A84C) : const Color(0xFFC9A84C);
    final goldDim = gold.withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: _hintController ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        // Use hint offset when idle, user drag offset otherwise
        final hintValue = _hintAnimation?.value ?? 0.0;
        final dx = _userHasInteracted ? _offset.dx : hintValue;
        final dy = _userHasInteracted ? _offset.dy : 0.0;
        final effectiveOffset = Offset(dx, dy);
        final rotation = dx / 300;

        // Color overlay intensity based on swipe distance
        final swipeProgress = (dx.abs() / _threshold).clamp(0.0, 1.0);
        final isRight = dx > 0;

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: effectiveOffset,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: swipeProgress > 0.05
                      ? Border.all(
                          color: (isRight
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE57373))
                              .withValues(alpha: swipeProgress * 0.4),
                          width: 2,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isDark ? 16 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Swipe color overlay
                      if (swipeProgress > 0.05)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: isRight
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                end: isRight
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                colors: [
                                  (isRight
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFE57373))
                                      .withValues(
                                          alpha: swipeProgress * 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Gold radial gradient accent blob in top-right
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                gold.withValues(alpha: 0.12),
                                gold.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Card content
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Group badge + Category tag
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (task.isGroupTask)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.group_outlined,
                                            size: 13,
                                            color: Color(0xFF2196F3)),
                                        const SizedBox(width: 5),
                                        Text(
                                          task.groupName ?? 'Group',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2196F3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: goldDim,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_typeIcon(task.type),
                                          size: 14, color: gold),
                                      const SizedBox(width: 6),
                                      Text(
                                        task.typeLabel.toUpperCase(),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: gold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Task name
                            Text(
                              task.name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (task.description != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                task.description!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Meta pills
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetaPill(
                                    icon: Icons.timer_outlined,
                                    label: timeLabel),
                                _MetaPill(
                                    icon: Icons.people_outline,
                                    label: task.social.label),
                                _MetaPill(
                                    icon: Icons.bolt_outlined,
                                    label: task.energy.label),
                                if (task.recurring != Recurring.none)
                                  _MetaPill(
                                      icon: Icons.repeat,
                                      label: task.recurring.label),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Progress dots
                            if (widget.totalCount > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    widget.totalCount.clamp(0, 8),
                                    (i) => Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      width:
                                          i == widget.currentIndex ? 18 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: i == widget.currentIndex
                                            ? gold
                                            : cs.onSurfaceVariant
                                                .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
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
            ),
          ),
        );
      },
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
            : const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}
