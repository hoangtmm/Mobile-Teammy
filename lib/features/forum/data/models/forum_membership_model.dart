import '../../domain/entities/forum_membership.dart';

class ForumMembershipModel extends ForumMembership {
  const ForumMembershipModel({
    required super.hasGroup,
    super.groupId,
    super.status,
    super.groupName,
  });

  factory ForumMembershipModel.fromJson(Map<String, dynamic> json) {
    return ForumMembershipModel(
      hasGroup: json['hasGroup'] as bool? ?? false,
      groupId: json['groupId']?.toString(),
      status: json['status'] as String?,
      groupName: json['groupName'] as String?,
    );
  }
}
