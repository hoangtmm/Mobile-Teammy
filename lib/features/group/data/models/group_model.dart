import '../../domain/entities/group.dart';
import 'group_member_model.dart';
import 'major_model.dart';
import 'semester_model.dart';

class GroupModel extends Group {
  const GroupModel({
    required super.id,
    required super.name,
    required super.description,
    required super.status,
    required super.maxMembers,
    required super.currentMembers,
    required super.role,
    required super.skills,
    required super.semester,
    required super.major,
    super.topic,
    super.mentor,
    super.leader,
    super.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? '',
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 0,
      currentMembers: (json['currentMembers'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? '',
      skills: List<String>.from(json['skills'] as List<dynamic>? ?? []),
      semester: (json['semester'] as Map<String, dynamic>?) != null
          ? SemesterModel.fromJson(json['semester'] as Map<String, dynamic>)
          : SemesterModel(
              semesterId: '',
              season: '',
              year: 0,
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              isActive: false,
            ),
      major: (json['major'] as Map<String, dynamic>?) != null
          ? MajorModel.fromJson(json['major'] as Map<String, dynamic>)
          : MajorModel(majorId: '', majorName: ''),
      topic: json['topic'] as String?,
      mentor: json['mentor'] as String?,
      leader: json['leader'] != null
          ? GroupMemberModel.fromJson(json['leader'] as Map<String, dynamic>)
          : null,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'role': role,
      'skills': skills,
      'semester': (semester as SemesterModel).toJson(),
      'major': (major as MajorModel).toJson(),
      'topic': topic,
      'mentor': mentor,
      'leader': leader != null ? (leader as GroupMemberModel).toJson() : null,
      'members': members
          .map((m) => (m as GroupMemberModel).toJson())
          .toList(),
    };
  }
}
