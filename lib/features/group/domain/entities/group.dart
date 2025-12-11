import 'group_member.dart';
import 'major.dart';
import 'semester.dart';

class Topic {
  final String topicId;
  final String topicName;
  final String description;
  final String? majorName;
  final String? status;
  final List<TopicMentor>? mentors;
  final List<String>? skills;
  final DateTime? createdAt;

  const Topic({
    required this.topicId,
    required this.topicName,
    required this.description,
    this.majorName,
    this.status,
    this.mentors,
    this.skills,
    this.createdAt,
  });
}

class TopicMentor {
  final String mentorId;
  final String mentorName;
  final String mentorEmail;

  const TopicMentor({
    required this.mentorId,
    required this.mentorName,
    required this.mentorEmail,
  });
}

class Mentor {
  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;

  const Mentor({
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });
}

class Group {
  final String id;
  final String name;
  final String? description;
  final String status;
  final int maxMembers;
  final int currentMembers;
  final String role;
  final List<String> skills;
  final Semester semester;
  final Major major;
  final Topic? topic;
  final Mentor? mentor;
  final GroupMember? leader;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.maxMembers,
    required this.currentMembers,
    required this.role,
    required this.skills,
    required this.semester,
    required this.major,
    this.topic,
    this.mentor,
    this.leader,
    this.members = const [],
  });
}
