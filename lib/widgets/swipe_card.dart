import 'package:flutter/material.dart';
import '../models/task.dart';

class SwipeCard extends StatefulWidget {
  final Task task;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  const SwipeCard({
    super.key,
    required this.task,
    required this.onAccept,
    required this.onSkip,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  Offset _offset = Offset.zero;

  static const _threshold = 100.0;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_offset.dx > _threshold) {
      _animateOff(1);
    } else if (_offset.dx < -_threshold) {
      _animateOff(-1);
    } else {
      setState(() {
        _offset = Offset.zero;
      });
    }
  }

  void _animateOff(int direction) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = widget.task;
    final timeLabel =
        task.time >= 60 ? '${task.time ~/ 60}hr' : '${task.time}min';

    final rotation = _offset.dx / 300;
    final acceptOpacity = (_offset.dx / _threshold).clamp(0.0, 1.0);
    final skipOpacity = (-_offset.dx / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? cs.outline.withValues(alpha: 0.6)
                    : cs.outline,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? cs.primary.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Swipe indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Opacity(
                        opacity: skipOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('LATER',
                              style: TextStyle(
                                  color: cs.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                      Opacity(
                        opacity: acceptOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("LET'S GO",
                              style: TextStyle(
                                  color: cs.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Task type pill
                  _TypePill(label: task.typeLabel, type: task.type),

                  const SizedBox(height: 20),

                  // Task name
                  Text(
                    task.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Metadata pills
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _MetaPill(
                          icon: Icons.timer_outlined, label: timeLabel),
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

                  const SizedBox(height: 24),

                  // Swipe hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left, size: 16,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe to decide',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final TaskType type;

  const _TypePill({required this.label, required this.type});

  Color _pillColor(TaskType type) {
    return switch (type) {
      TaskType.work => const Color(0xFF4A90D9),
      TaskType.personal => const Color(0xFF9B59B6),
      TaskType.health => const Color(0xFF27AE60),
      TaskType.social => const Color(0xFFE67E22),
      TaskType.errand => const Color(0xFF1ABC9C),
      TaskType.other => const Color(0xFF95A5A6),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _pillColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}
