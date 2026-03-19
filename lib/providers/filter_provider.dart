import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import 'task_provider.dart';

class FilterState {
  final int? maxTime;
  final Level? maxSocial;
  final Level? maxEnergy;
  final TaskType? taskType;

  const FilterState({this.maxTime, this.maxSocial, this.maxEnergy, this.taskType});

  FilterState copyWith({
    int? Function()? maxTime,
    Level? Function()? maxSocial,
    Level? Function()? maxEnergy,
    TaskType? Function()? taskType,
  }) {
    return FilterState(
      maxTime: maxTime != null ? maxTime() : this.maxTime,
      maxSocial: maxSocial != null ? maxSocial() : this.maxSocial,
      maxEnergy: maxEnergy != null ? maxEnergy() : this.maxEnergy,
      taskType: taskType != null ? taskType() : this.taskType,
    );
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setMaxTime(int? time) {
    state = state.copyWith(maxTime: () => time);
  }

  void setMaxSocial(Level? level) {
    state = state.copyWith(maxSocial: () => level);
  }

  void setMaxEnergy(Level? level) {
    state = state.copyWith(maxEnergy: () => level);
  }

  void setTaskType(TaskType? type) {
    state = state.copyWith(taskType: () => type);
  }

  /// Cycle social filter: null → low → medium → high → null
  void cycleSocial() {
    final current = state.maxSocial;
    final next = switch (current) {
      null => Level.low,
      Level.low => Level.medium,
      Level.medium => Level.high,
      Level.high => null,
    };
    state = state.copyWith(maxSocial: () => next);
  }

  /// Cycle energy filter: null → low → medium → high → null
  void cycleEnergy() {
    final current = state.maxEnergy;
    final next = switch (current) {
      null => Level.low,
      Level.low => Level.medium,
      Level.medium => Level.high,
      Level.high => null,
    };
    state = state.copyWith(maxEnergy: () => next);
  }

  /// Cycle time filter: null → 5 → 15 → 30 → 60 → null
  static const _timeSteps = [5, 15, 30, 60];
  void cycleTime() {
    final current = state.maxTime;
    if (current == null) {
      state = state.copyWith(maxTime: () => _timeSteps.first);
    } else {
      final idx = _timeSteps.indexOf(current);
      if (idx < 0 || idx >= _timeSteps.length - 1) {
        state = state.copyWith(maxTime: () => null);
      } else {
        state = state.copyWith(maxTime: () => _timeSteps[idx + 1]);
      }
    }
  }

  void clearAll() {
    state = const FilterState();
  }
}

/// Open (non-completed) tasks only.
final openTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  return ref.watch(taskListProvider).whenData(
        (tasks) => tasks.where((t) => !t.isCompleted).toList(),
      );
});

/// Completed tasks only.
final completedTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  return ref.watch(taskListProvider).whenData(
        (tasks) => tasks.where((t) => t.isCompleted).toList(),
      );
});

/// Filtered tasks for What Now swipe — only open tasks, with user filters applied.
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(openTasksProvider);
  final filters = ref.watch(filterProvider);

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      if (filters.taskType != null && task.type != filters.taskType) {
        return false;
      }
      if (filters.maxTime != null && task.time > filters.maxTime!) {
        return false;
      }
      if (filters.maxSocial != null &&
          task.social.index > filters.maxSocial!.index) {
        return false;
      }
      if (filters.maxEnergy != null &&
          task.energy.index > filters.maxEnergy!.index) {
        return false;
      }
      return true;
    }).toList()
      ..shuffle();
  });
});
