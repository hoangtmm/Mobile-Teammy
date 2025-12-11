import '../../domain/entities/group_invitation.dart';

class GroupInvitationModel extends GroupInvitation {
  const GroupInvitationModel({
    required super.type,
    required super.id,
    required super.postId,
    required super.userId,
    required super.email,
    required super.displayName,
    required super.avatarUrl,
    required super.createdAt,
    required super.message,
    required super.topicId,
    required super.topicTitle,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      type: json['type'] as String,
      id: json['id'] as String,
      postId: json['postId'] as String?,
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      message: json['message'] as String?,
      topicId: json['topicId'] as String?,
      topicTitle: json['topicTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'postId': postId,
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
      'topicId': topicId,
      'topicTitle': topicTitle,
    };
  }
}
