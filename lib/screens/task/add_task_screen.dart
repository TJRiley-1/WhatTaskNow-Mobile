import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/app_text_field.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customTypeController = TextEditingController();

  TaskType _type = TaskType.personal;
  int _time = 15;
  Level _social = Level.low;
  Level _energy = Level.low;
  Recurring _recurring = Recurring.none;
  DateTime? _dueDate;
  bool _isLoading = false;

  static const _timePresets = [5, 15, 30];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  String get _resolvedType {
    if (_type == TaskType.other &&
        _customTypeController.text.trim().isNotEmpty) {
      return _customTypeController.text.trim();
    }
    return _type.name;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == TaskType.other && _customTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom type name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(taskListProvider.notifier).addTask(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            typeString: _resolvedType,
            time: _time,
            social: _social,
            energy: _energy,
            dueDate: _dueDate,
            recurring: _recurring,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomTimePicker() {
    int hours = _time ~/ 60;
    int minutes = _time % 60;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Custom Time',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How long will this take?',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(
                height: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours wheel
                    SizedBox(
                      width: 80,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: hours),
                        itemExtent: 40,
                        selectionOverlay:
                            CupertinoPickerDefaultSelectionOverlay(
                          background: isDark
                              ? const Color(0xFFC9A84C)
                                  .withValues(alpha: 0.12)
                              : const Color(0xFFC9A84C)
                                  .withValues(alpha: 0.08),
                        ),
                        onSelectedItemChanged: (i) =>
                            setSheetState(() => hours = i),
                        children: List.generate(
                          13,
                          (i) => Center(
                            child: Text(
                              '$i',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'hr',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Minutes wheel
                    SizedBox(
                      width: 80,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: minutes ~/ 5),
                        itemExtent: 40,
                        selectionOverlay:
                            CupertinoPickerDefaultSelectionOverlay(
                          background: isDark
                              ? const Color(0xFFC9A84C)
                                  .withValues(alpha: 0.12)
                              : const Color(0xFFC9A84C)
                                  .withValues(alpha: 0.08),
                        ),
                        onSelectedItemChanged: (i) =>
                            setSheetState(() => minutes = i * 5),
                        children: List.generate(
                          12,
                          (i) => Center(
                            child: Text(
                              '${i * 5}'.padLeft(2, '0'),
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'min',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      final total = hours * 60 + minutes;
                      if (total > 0) {
                        setState(() => _time = total);
                      }
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? const Color(0xFFC9A84C) : cs.onSurface,
                      foregroundColor: isDark ? cs.onPrimary : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Set Time'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleSheet() {
    var tempRecurring = _recurring;
    var tempDueDate = _dueDate;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Schedule',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Due date
                Text(
                  'Due By',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: tempDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setSheetState(() => tempDueDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          tempDueDate != null
                              ? '${tempDueDate!.day}/${tempDueDate!.month}/${tempDueDate!.year}'
                              : 'No due date',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: tempDueDate != null
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (tempDueDate != null)
                          GestureDetector(
                            onTap: () =>
                                setSheetState(() => tempDueDate = null),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Recurring
                Text(
                  'Repeats',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Recurring.values.map((r) {
                    final selected = r == tempRecurring;
                    return ChoiceChip(
                      label: Text(r.label),
                      selected: selected,
                      onSelected: (_) =>
                          setSheetState(() => tempRecurring = r),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _recurring = tempRecurring;
                        _dueDate = tempDueDate;
                      });
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? const Color(0xFFC9A84C) : cs.onSurface,
                      foregroundColor: isDark ? cs.onPrimary : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _timeLabel {
    if (_time >= 60) {
      final h = _time ~/ 60;
      final m = _time % 60;
      return m > 0 ? '${h}hr ${m}min' : '${h}hr';
    }
    return '${_time}min';
  }

  String get _scheduleLabel {
    final parts = <String>[];
    if (_dueDate != null) {
      parts.add(
          'Due ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}');
    }
    if (_recurring != Recurring.none) {
      parts.add(_recurring.label);
    }
    return parts.isEmpty ? 'None' : parts.join(' · ');
  }

  bool get _isCustomTime => !_timePresets.contains(_time);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Name
              AppTextField(
                controller: _nameController,
                labelText: 'Task Name',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: _descriptionController,
                labelText: 'Description (optional)',
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 20),

              // Task Type
              _SectionLabel(label: 'Type'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskType.values.map((t) {
                  final selected = t == _type;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              if (_type == TaskType.other) ...[
                const SizedBox(height: 8),
                AppTextField(
                  controller: _customTypeController,
                  labelText: 'Custom Type Name',
                  textInputAction: TextInputAction.next,
                ),
              ],

              const SizedBox(height: 18),

              // Time Estimate
              _SectionLabel(label: 'Time Estimate'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._timePresets.map((t) {
                    final label = '${t}min';
                    return ChoiceChip(
                      label: Text(label),
                      selected: t == _time,
                      onSelected: (_) => setState(() => _time = t),
                    );
                  }),
                  ChoiceChip(
                    label: Text(_isCustomTime ? _timeLabel : 'Custom'),
                    selected: _isCustomTime,
                    onSelected: (_) => _showCustomTimePicker(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Social Battery
              _SectionLabel(label: 'Social Battery'),
              const SizedBox(height: 6),
              SegmentedButton<Level>(
                segments: Level.values
                    .map(
                        (l) => ButtonSegment(value: l, label: Text(l.label)))
                    .toList(),
                selected: {_social},
                onSelectionChanged: (s) =>
                    setState(() => _social = s.first),
              ),

              const SizedBox(height: 18),

              // Energy Required
              _SectionLabel(label: 'Energy Required'),
              const SizedBox(height: 6),
              SegmentedButton<Level>(
                segments: Level.values
                    .map(
                        (l) => ButtonSegment(value: l, label: Text(l.label)))
                    .toList(),
                selected: {_energy},
                onSelectionChanged: (s) =>
                    setState(() => _energy = s.first),
              ),

              const SizedBox(height: 18),

              // Schedule (Recurring + Due Date) — opens as popup
              Row(
                children: [
                  _SectionLabel(label: 'Schedule'),
                  const Spacer(),
                  Text(
                    _scheduleLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _showScheduleSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
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
                      Icon(Icons.event_repeat_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        _recurring == Recurring.none && _dueDate == null
                            ? 'Set due date or repeats'
                            : _scheduleLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: _recurring == Recurring.none &&
                                  _dueDate == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFFC9A84C) : cs.onSurface,
                    foregroundColor: isDark ? cs.onPrimary : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 17,
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
                      : const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
