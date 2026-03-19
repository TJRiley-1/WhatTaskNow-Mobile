import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task.dart';
import '../../models/group_member.dart';
import '../../providers/group_tasks_provider.dart';
import '../../widgets/common/app_text_field.dart';

class AddGroupTaskScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupMember> members;

  const AddGroupTaskScreen({
    super.key,
    required this.groupId,
    required this.members,
  });

  @override
  ConsumerState<AddGroupTaskScreen> createState() => _AddGroupTaskScreenState();
}

class _AddGroupTaskScreenState extends ConsumerState<AddGroupTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  TaskType _type = TaskType.other;
  int _time = 15;
  Level _social = Level.low;
  Level _energy = Level.low;
  DateTime? _dueDate;
  String? _assignedTo;
  bool _isLoading = false;

  static const _timePresets = [5, 15, 30];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(groupTasksProvider(widget.groupId).notifier).addGroupTask(
            name: _nameController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            type: _type.name,
            time: _time,
            social: _social.name,
            energy: _energy.name,
            dueDate: _dueDate,
            assignedTo: _assignedTo,
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
              SizedBox(
                height: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      child: CupertinoPicker(
                        scrollController:
                            FixedExtentScrollController(initialItem: hours),
                        itemExtent: 40,
                        selectionOverlay:
                            CupertinoPickerDefaultSelectionOverlay(
                          background: const Color(0xFFC9A84C)
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                        ),
                        onSelectedItemChanged: (i) =>
                            setSheetState(() => hours = i),
                        children: List.generate(
                          13,
                          (i) => Center(
                            child: Text('$i',
                                style: GoogleFonts.dmSans(
                                    fontSize: 22, color: cs.onSurface)),
                          ),
                        ),
                      ),
                    ),
                    Text('hr',
                        style: GoogleFonts.dmSans(
                            fontSize: 16, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 80,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: minutes ~/ 5),
                        itemExtent: 40,
                        selectionOverlay:
                            CupertinoPickerDefaultSelectionOverlay(
                          background: const Color(0xFFC9A84C)
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                        ),
                        onSelectedItemChanged: (i) =>
                            setSheetState(() => minutes = i * 5),
                        children: List.generate(
                          12,
                          (i) => Center(
                            child: Text('${i * 5}'.padLeft(2, '0'),
                                style: GoogleFonts.dmSans(
                                    fontSize: 22, color: cs.onSurface)),
                          ),
                        ),
                      ),
                    ),
                    Text('min',
                        style: GoogleFonts.dmSans(
                            fontSize: 16, color: cs.onSurfaceVariant)),
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
                      if (total > 0) setState(() => _time = total);
                      Navigator.pop(ctx);
                    },
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

  String get _timeLabel {
    if (_time >= 60) {
      final h = _time ~/ 60;
      final m = _time % 60;
      return m > 0 ? '${h}hr ${m}min' : '${h}hr';
    }
    return '${_time}min';
  }

  bool get _isCustomTime => !_timePresets.contains(_time);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                controller: _descController,
                labelText: 'Description (optional)',
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 20),

              // Due date
              _SectionLabel(label: 'Due Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  width: double.infinity,
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
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'No due date',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: _dueDate != null
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Type
              _SectionLabel(label: 'Type'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskType.values.map((t) {
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: t == _type,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Time
              _SectionLabel(label: 'Time Estimate'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._timePresets.map((t) {
                    return ChoiceChip(
                      label: Text('${t}min'),
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

              // Social
              _SectionLabel(label: 'Social Battery'),
              const SizedBox(height: 6),
              SegmentedButton<Level>(
                segments: Level.values
                    .map((l) => ButtonSegment(value: l, label: Text(l.label)))
                    .toList(),
                selected: {_social},
                onSelectionChanged: (s) => setState(() => _social = s.first),
              ),

              const SizedBox(height: 18),

              // Energy
              _SectionLabel(label: 'Energy Required'),
              const SizedBox(height: 6),
              SegmentedButton<Level>(
                segments: Level.values
                    .map((l) => ButtonSegment(value: l, label: Text(l.label)))
                    .toList(),
                selected: {_energy},
                onSelectionChanged: (s) => setState(() => _energy = s.first),
              ),

              const SizedBox(height: 18),

              // Assign to
              _SectionLabel(label: 'Assign To'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _assignedTo,
                    isExpanded: true,
                    hint: Text('Leave unassigned',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, color: cs.onSurfaceVariant)),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned',
                            style: GoogleFonts.dmSans(fontSize: 15)),
                      ),
                      ...widget.members.map((m) => DropdownMenuItem(
                            value: m.userId,
                            child: Text(m.displayName ?? 'Unknown',
                                style: GoogleFonts.dmSans(fontSize: 15)),
                          )),
                    ],
                    onChanged: (v) => setState(() => _assignedTo = v),
                  ),
                ),
              ),

              const SizedBox(height: 28),

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
