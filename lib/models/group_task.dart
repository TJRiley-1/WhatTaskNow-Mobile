enum GroupTaskStatus {
  unassigned,
  claimed,
  inProgress,
  done;

  String get label => switch (this) {
        unassigned => 'Unassigned',
        claimed => 'Claimed',
        inProgress => 'In Progress',
        done => 'Done',
      };

  String get dbValue => switch (this) {
        unassigned => 'unassigned',
        claimed => 'claimed',
        inProgress => 'in_progress',
        done => 'done',
      };

  static GroupTaskStatus fromString(String value) {
    return switch (value) {
      'unassigned' => GroupTaskStatus.unassigned,
      'claimed' => GroupTaskStatus.claimed,
      'in_progress' => GroupTaskStatus.inProgress,
      'done' => GroupTaskStatus.done,
      _ => GroupTaskStatus.unassigned,
    };
  }
}

class GroupTask {
  final String id;
  final String groupId;
  final String name;
  final String? description;
  final String typeRaw;
  final int time;
  final String social;
  final String energy;
  final DateTime? dueDate;
  final GroupTaskStatus status;
  final String createdBy;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? claimedAt;
  final DateTime? completedAt;
  final String? syncedTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupTask({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.typeRaw,
    required this.time,
    required this.social,
    required this.energy,
    this.dueDate,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    this.assignedToName,
    this.claimedAt,
    this.completedAt,
    this.syncedTaskId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUnassigned => status == GroupTaskStatus.unassigned;
  bool get isDone => status == GroupTaskStatus.done;

  factory GroupTask.fromJson(Map<String, dynamic> json) {
    final assignedProfile = json['assigned_profile'] as Map<String, dynamic>?;
    return GroupTask(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      typeRaw: json['type'] as String,
      time: json['time'] as int,
      social: json['social'] as String,
      energy: json['energy'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: GroupTaskStatus.fromString(json['status'] as String),
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: assignedProfile?['display_name'] as String?,
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      syncedTaskId: json['synced_task_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
