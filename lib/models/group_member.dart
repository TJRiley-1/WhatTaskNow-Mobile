enum GroupRole {
  admin,
  member;

  String get label => switch (this) {
        admin => 'Admin',
        member => 'Member',
      };

  static GroupRole fromString(String value) {
    return GroupRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GroupRole.member,
    );
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final GroupRole role;
  final bool? allowTaskAssignment;
  final String? displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.allowTaskAssignment,
    this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  bool get isAdmin => role == GroupRole.admin;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: GroupRole.fromString(json['role'] as String? ?? 'member'),
      allowTaskAssignment: json['allow_task_assignment'] as bool?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
