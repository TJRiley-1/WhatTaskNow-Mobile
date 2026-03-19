enum GroupType {
  eventDriven,
  friendsFamily;

  String get label => switch (this) {
        eventDriven => 'Event',
        friendsFamily => 'Friends & Family',
      };

  String get dbValue => switch (this) {
        eventDriven => 'event_driven',
        friendsFamily => 'friends_family',
      };

  static GroupType fromString(String value) {
    return switch (value) {
      'event_driven' => GroupType.eventDriven,
      'friends_family' => GroupType.friendsFamily,
      _ => GroupType.friendsFamily,
    };
  }
}

enum LeaderboardPeriod {
  weekly,
  monthly,
  quarterly;

  String get label => switch (this) {
        weekly => 'Weekly',
        monthly => 'Monthly',
        quarterly => 'Quarterly',
      };

  static LeaderboardPeriod fromString(String value) {
    return LeaderboardPeriod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LeaderboardPeriod.weekly,
    );
  }
}

enum LeaderboardMetric {
  points,
  tasks,
  combined;

  String get label => switch (this) {
        points => 'Points',
        tasks => 'Tasks',
        combined => 'Combined',
      };

  static LeaderboardMetric fromString(String value) {
    return LeaderboardMetric.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LeaderboardMetric.points,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String? createdBy;
  final GroupType groupType;
  final DateTime? eventDate;
  final LeaderboardPeriod leaderboardPeriod;
  final LeaderboardMetric leaderboardMetric;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    this.createdBy,
    this.groupType = GroupType.friendsFamily,
    this.eventDate,
    this.leaderboardPeriod = LeaderboardPeriod.weekly,
    this.leaderboardMetric = LeaderboardMetric.points,
    required this.createdAt,
  });

  bool get isEventDriven => groupType == GroupType.eventDriven;
  bool get isFriendsFamily => groupType == GroupType.friendsFamily;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String?,
      groupType: GroupType.fromString(json['group_type'] as String? ?? 'friends_family'),
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      leaderboardPeriod: LeaderboardPeriod.fromString(
          json['leaderboard_period'] as String? ?? 'weekly'),
      leaderboardMetric: LeaderboardMetric.fromString(
          json['leaderboard_metric'] as String? ?? 'points'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? currentRank;
  final int periodPoints;
  final int periodTasks;
  final int score;

  const LeaderboardEntry({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.currentRank,
    required this.periodPoints,
    required this.periodTasks,
    required this.score,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      currentRank: json['current_rank'] as String?,
      periodPoints: (json['period_points'] as int?) ?? (json['weekly_points'] as int?) ?? 0,
      periodTasks: (json['period_tasks'] as int?) ?? (json['weekly_tasks'] as int?) ?? 0,
      score: (json['score'] as int?) ?? (json['weekly_points'] as int?) ?? 0,
    );
  }
}
