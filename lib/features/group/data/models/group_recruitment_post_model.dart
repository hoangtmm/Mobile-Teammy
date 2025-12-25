class GroupRecruitmentPostModel {
  final String id;
  final String status;
  final String title;
  final String description;
  final String? positionNeeded;
  final List<String> skills;
  final DateTime? createdAt;
  final DateTime? applicationDeadline;
  final int? currentMembers;
  final int? maxMembers;
  final String? groupName;
  final String? mentorName;
  final String? mentorAvatarUrl;
  final String? majorName;

  const GroupRecruitmentPostModel({
    required this.id,
    required this.status,
    required this.title,
    required this.description,
    required this.positionNeeded,
    required this.skills,
    required this.createdAt,
    required this.applicationDeadline,
    required this.currentMembers,
    required this.maxMembers,
    required this.groupName,
    required this.mentorName,
    required this.mentorAvatarUrl,
    required this.majorName,
  });

  factory GroupRecruitmentPostModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final groupData = json['group'];
    String? groupName;
    int? maxMembers;
    int? currentMembers;
    if (groupData is Map<String, dynamic>) {
      groupName = groupData['name'] as String?;
      maxMembers = parseInt(groupData['maxMembers']);
      currentMembers =
          parseInt(json['currentMembers'] ?? groupData['currentMembers']);
    } else {
      currentMembers = parseInt(json['currentMembers']);
    }

    String? mentorName;
    String? mentorAvatarUrl;
    final mentorData = json['mentor'];
    if (mentorData is Map<String, dynamic>) {
      mentorName = mentorData['displayName'] as String?;
      mentorAvatarUrl = mentorData['avatarUrl'] as String?;
    } else if (groupData is Map<String, dynamic>) {
      final groupMentorData = groupData['mentor'];
      if (groupMentorData is Map<String, dynamic>) {
        mentorName = groupMentorData['displayName'] as String?;
        mentorAvatarUrl = groupMentorData['avatarUrl'] as String?;
      }
    }

    String? majorName;
    final majorData = json['major'];
    if (majorData is Map<String, dynamic>) {
      majorName = majorData['majorName'] as String?;
    }

    final rawSkills = json['skills'];
    final skills = <String>[];
    if (rawSkills is List) {
      skills.addAll(rawSkills.whereType<String>());
    } else if (rawSkills is String) {
      skills.addAll(
        rawSkills.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }

    return GroupRecruitmentPostModel(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      positionNeeded: json['position_needed'] as String? ??
          json['positionNeeded'] as String?,
      skills: skills,
      createdAt: parseDate(json['createdAt']),
      applicationDeadline: parseDate(json['applicationDeadline']),
      currentMembers: currentMembers,
      maxMembers: maxMembers,
      groupName: groupName,
      mentorName: mentorName,
      mentorAvatarUrl: mentorAvatarUrl,
      majorName: majorName,
    );
  }
}
