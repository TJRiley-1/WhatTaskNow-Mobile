enum TaskType {
  work,
  personal,
  health,
  social,
  errand,
  other;

  String get label => switch (this) {
        work => 'Work',
        personal => 'Personal',
        health => 'Health',
        social => 'Social',
        errand => 'Errand',
        other => 'Other',
      };

  static TaskType fromString(String value) {
    return TaskType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskType.other,
    );
  }
}

enum Level {
  low,
  medium,
  high;

  String get label => switch (this) {
        low => 'Low',
        medium => 'Med',
        high => 'High',
      };

  static Level fromString(String value) {
    return Level.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Level.low,
    );
  }
}

enum Recurring {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
        none => 'None',
        daily => 'Daily',
        weekly => 'Weekly',
        monthly => 'Monthly',
      };

  static Recurring fromString(String value) {
    return Recurring.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Recurring.none,
    );
  }
}

class Task {
  final String id;
  final String userId;
  final String? localId;
  final String name;
  final String? description;
  final String typeRaw;
  final int time;
  final Level social;
  final Level energy;
  final DateTime? dueDate;
  final Recurring recurring;
  final int timesShown;
  final int timesSkipped;
  final int timesCompleted;
  final int pointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.userId,
    this.localId,
    required this.name,
    this.description,
    required this.typeRaw,
    required this.time,
    required this.social,
    required this.energy,
    this.dueDate,
    this.recurring = Recurring.none,
    this.timesShown = 0,
    this.timesSkipped = 0,
    this.timesCompleted = 0,
    this.pointsEarned = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this task is considered "done" (completed at least once, non-recurring).
  bool get isCompleted => timesCompleted > 0 && recurring == Recurring.none;

  /// The parsed TaskType enum. Custom types map to [TaskType.other].
  TaskType get type => TaskType.fromString(typeRaw);

  /// Display label: uses enum label for known types, raw string for custom.
  String get typeLabel {
    final parsed = TaskType.fromString(typeRaw);
    if (parsed == TaskType.other && typeRaw != 'other') {
      return typeRaw[0].toUpperCase() + typeRaw.substring(1);
    }
    return parsed.label;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      localId: json['local_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      typeRaw: json['type'] as String,
      time: json['time'] as int,
      social: Level.fromString(json['social'] as String),
      energy: Level.fromString(json['energy'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      recurring: Recurring.fromString(json['recurring'] as String? ?? 'none'),
      timesShown: json['times_shown'] as int? ?? 0,
      timesSkipped: json['times_skipped'] as int? ?? 0,
      timesCompleted: json['times_completed'] as int? ?? 0,
      pointsEarned: json['points_earned'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'type': typeRaw,
      'time': time,
      'social': social.name,
      'energy': energy.name,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'recurring': recurring.name,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'type': typeRaw,
      'time': time,
      'social': social.name,
      'energy': energy.name,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'recurring': recurring.name,
      'times_shown': timesShown,
      'times_skipped': timesSkipped,
      'times_completed': timesCompleted,
      'points_earned': pointsEarned,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
