import '../../domain/entities/group_invitation.dart';

class InvitationModel extends GroupInvitation {
  const InvitationModel({
    required super.type,
    required super.id,
    required super.userId,
    required super.email,
    required super.displayName,
    required super.avatarUrl,
    required super.createdAt,
    super.postId,
    super.message,
    super.topicId,
    super.topicTitle,
    required this.invitationId,
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.invitedBy,
  });

  final String invitationId;
  final String groupId;
  final String groupName;
  final String status;
  final String invitedBy;

  bool get isPending => status == 'pending';

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      invitationId: json['invitationId'] as String,
      groupId: json['groupId'] as String,
      groupName: (json['groupName'] ?? '') as String,
      type: (json['type'] ?? 'member') as String,
      status: (json['status'] ?? 'pending') as String,
      id: (json['id'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      displayName: (json['displayName'] ?? '') as String,
      avatarUrl: (json['avatarUrl'] ?? '') as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      invitedBy: json['invitedBy'] as String,
      topicId: json['topicId'] as String?,
      topicTitle: json['topicTitle'] as String?,
      postId: json['postId'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'groupId': groupId,
      'groupName': groupName,
      'type': type,
      'status': status,
      'id': id,
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'invitedBy': invitedBy,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'postId': postId,
      'message': message,
    };
  }
}
