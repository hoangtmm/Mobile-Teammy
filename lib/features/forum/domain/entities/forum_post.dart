class ForumPost {
  const ForumPost({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.groupId,
    this.groupName,
    this.groupDescription,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    this.positionNeeded,
    this.skills = const [],
    this.createdAt,
    this.expiresAt,
    this.status,
    this.hasApplied = false,
    this.myApplicationStatus,
    this.applicationsCount = 0,
    this.currentMembers,
    this.maxMembers,
    this.semesterSeason,
    this.semesterYear,
    this.majorName,
    this.topicName,
    this.mentorName,
    this.mentorEmail,
    this.mentorAvatarUrl,
    this.members = const [],
  });

  /// ID bài post
  final String id;

  /// "group_hiring" (post tuyển thành viên) hoặc "individual" (sinh viên tìm nhóm)
  final String type;

  final String title;
  final String description;

  final String? groupId;
  final String? groupName;
  final String? groupDescription;

  final String? authorId;
  final String? authorName;
  final String? authorAvatarUrl;

  /// Chuỗi mô tả vị trí cần tuyển (BE dùng field `position_needed`)
  final String? positionNeeded;

  /// Danh sách skill (tách từ mảng JSON hoặc CSV)
  final List<String> skills;

  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? status;

  /// User hiện tại đã apply bài này chưa
  final bool hasApplied;
  final String? myApplicationStatus; // pending | accepted | rejected | ...

  /// Tổng số ứng tuyển
  final int applicationsCount;

  final int? currentMembers;
  final int? maxMembers;

  /// Semester info
  final String? semesterSeason;
  final int? semesterYear;

  /// Major info
  final String? majorName;

  /// Topic info
  final String? topicName;

  /// Mentor info
  final String? mentorName;
  final String? mentorEmail;
  final String? mentorAvatarUrl;

  /// Group members
  final List<GroupMember> members;
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.role,
    this.assignedRole,
  });

  final String userId;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? role;
  final String? assignedRole;
}
