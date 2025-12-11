class ForumMembership {
  const ForumMembership({
    required this.hasGroup,
    this.groupId,
    this.status,
    this.groupName,
  });

  /// User hiện có nhóm không
  final bool hasGroup;

  /// ID nhóm (nếu có)
  final String? groupId;

  /// Tên nhóm (nếu có)
  final String? groupName;

  /// 'leader' | 'member' | 'student' | ...
  final String? status;
}
