class ProfilePostInvitation {
  const ProfilePostInvitation({
    required this.candidateId,
    required this.postId,
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.createdAt,
    required this.semesterId,
    required this.groupMajorId,
    required this.groupMajorName,
    required this.leaderUserId,
    required this.leaderDisplayName,
    required this.leaderEmail,
  });

  final String candidateId;
  final String postId;
  final String groupId;
  final String groupName;
  final String status;
  final DateTime createdAt;
  final String semesterId;
  final String groupMajorId;
  final String groupMajorName;
  final String leaderUserId;
  final String leaderDisplayName;
  final String leaderEmail;

  factory ProfilePostInvitation.fromJson(Map<String, dynamic> json) {
    return ProfilePostInvitation(
      candidateId: json['candidateId'] as String,
      postId: json['postId'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      semesterId: json['semesterId'] as String,
      groupMajorId: json['groupMajorId'] as String,
      groupMajorName: json['groupMajorName'] as String,
      leaderUserId: json['leaderUserId'] as String,
      leaderDisplayName: json['leaderDisplayName'] as String,
      leaderEmail: json['leaderEmail'] as String,
    );
  }
}
