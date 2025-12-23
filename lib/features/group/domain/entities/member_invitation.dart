class MemberInvitation {
  const MemberInvitation({
    required this.invitationId,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.invitedBy,
    required this.invitedByName,
    required this.groupId,
    required this.groupName,
    this.topicId,
    this.topicTitle,
  });

  final String invitationId;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String invitedBy;
  final String invitedByName;
  final String groupId;
  final String groupName;
  final String? topicId;
  final String? topicTitle;

  factory MemberInvitation.fromJson(Map<String, dynamic> json) {
    return MemberInvitation(
      invitationId: json['invitationId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      invitedBy: json['invitedBy'] as String,
      invitedByName: json['invitedByName'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      topicId: json['topicId'] as String?,
      topicTitle: json['topicTitle'] as String?,
    );
  }
}
