import '../../domain/entities/group_member.dart';

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.userId,
    required super.email,
    required super.displayName,
    required super.role,
    required super.joinedAt,
    super.avatarUrl,
    super.assignedRole,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      assignedRole: json['assignedRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'avatarUrl': avatarUrl,
      'assignedRole': assignedRole,
    };
  }
}
