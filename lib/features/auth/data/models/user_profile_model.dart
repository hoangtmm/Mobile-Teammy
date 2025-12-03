import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.displayName,
    required super.email,
    super.avatarUrl,
    super.phone,
    super.gender,
    super.skills,
    super.skillsCompleted,
    super.portfolioUrl,
    super.studentCode,
    super.majorId,
    super.majorName,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      skills: _parseSkills(json['skills']),
      skillsCompleted: json['skillsCompleted'] as bool?,
      portfolioUrl: json['portfolioUrl'] as String?,
      studentCode: json['studentCode'] as String?,
      majorId: (json['majorId'] as String?) ?? _parseMajorId(json['major']),
      majorName:
          (json['majorName'] as String?) ?? _parseMajorName(json['major']),
    );
  }

  static String? _parseSkills(dynamic value) {
    if (value is List) {
      final items = value
          .map<String?>((e) {
            if (e is String) return e;
            if (e is Map && e['name'] is String) return e['name'] as String;
            return e?.toString();
          })
          .whereType<String>()
          .toList();
      if (items.isEmpty) return null;
      return items.join(', ');
    }
    if (value is String) return value;
    return value?.toString();
  }

  static String? _parseMajorId(dynamic value) {
    if (value is Map<String, dynamic>) {
      if (value['majorId'] != null) return value['majorId'].toString();
      if (value['id'] != null) return value['id'].toString();
    }
    return value?.toString();
  }

  static String? _parseMajorName(dynamic value) {
    if (value is Map<String, dynamic>) {
      if (value['name'] != null) return value['name'].toString();
      if (value['majorName'] != null) return value['majorName'].toString();
    }
    return value?.toString();
  }
}
