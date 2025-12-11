class GroupInvitation {
  const GroupInvitation({
    required this.type, // "invitation" or "application"
    required this.id,
    required this.postId,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.createdAt,
    required this.message,
    required this.topicId,
    required this.topicTitle,
  });

  final String type;
  final String id;
  final String? postId;
  final String userId;
  final String email;
  final String displayName;
  final String avatarUrl;
  final DateTime createdAt;
  final String? message;
  final String? topicId;
  final String? topicTitle;

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
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
}
