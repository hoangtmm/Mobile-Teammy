import 'group_member.dart';
import 'major.dart';
import 'semester.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String status;
  final int maxMembers;
  final int currentMembers;
  final String role;
  final List<String> skills;
  final Semester semester;
  final Major major;
  final String? topic;
  final String? mentor;
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
