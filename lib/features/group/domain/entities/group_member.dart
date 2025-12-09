class GroupMember {
  final String userId;
  final String email;
  final String displayName;
  final String role;
  final DateTime joinedAt;
  final String? avatarUrl;
  final String? assignedRole;

  const GroupMember({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
    this.assignedRole,
  });
}
