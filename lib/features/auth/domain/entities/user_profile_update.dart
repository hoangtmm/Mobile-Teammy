class UserProfileUpdate {
  const UserProfileUpdate({
    required this.displayName,
    required this.phone,
    required this.gender,
    required this.skills,
    required this.skillsCompleted,
    required this.portfolioUrl,
  });

  final String displayName;
  final String phone;
  final String gender;
  final String skills;
  final bool skillsCompleted;
  final String portfolioUrl;

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phone': phone,
      'gender': gender,
      'skills': skills,
      'skillsCompleted': skillsCompleted,
      'portfolioUrl': portfolioUrl,
    };
  }
}
