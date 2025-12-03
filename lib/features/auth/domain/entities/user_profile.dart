class UserProfile {
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.gender,
    this.skills,
    this.skillsCompleted,
    this.portfolioUrl,
    this.studentCode,
    this.majorId,
    this.majorName,
  });

  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? gender;
  final String? skills;
  final bool? skillsCompleted;
  final String? portfolioUrl;
  final String? studentCode;
  final String? majorId;
  final String? majorName;
}
