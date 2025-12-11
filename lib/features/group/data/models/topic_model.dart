import '../../domain/entities/group.dart';

class TopicModel {
  final String topicId;
  final String semesterId;
  final String semesterSeason;
  final int semesterYear;
  final String majorId;
  final String majorName;
  final String title;
  final String description;
  final String? source;
  final String? status;
  final String? createdById;
  final String? createdByName;
  final String? createdByEmail;
  final List<MentorModel> mentors;
  final List<dynamic> skills;
  final String? createdAt;

  TopicModel({
    required this.topicId,
    required this.semesterId,
    required this.semesterSeason,
    required this.semesterYear,
    required this.majorId,
    required this.majorName,
    required this.title,
    required this.description,
    this.source,
    this.status,
    this.createdById,
    this.createdByName,
    this.createdByEmail,
    required this.mentors,
    required this.skills,
    this.createdAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      topicId: json['topicId'] as String,
      semesterId: json['semesterId'] as String,
      semesterSeason: json['semesterSeason'] as String? ?? '',
      semesterYear: json['semesterYear'] as int? ?? 0,
      majorId: json['majorId'] as String,
      majorName: json['majorName'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      source: json['source'] as String?,
      status: json['status'] as String?,
      createdById: json['createdById'] as String?,
      createdByName: json['createdByName'] as String?,
      createdByEmail: json['createdByEmail'] as String?,
      mentors: (json['mentors'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(MentorModel.fromJson)
          .toList() ?? [],
      skills: json['skills'] as List<dynamic>? ?? [],
      createdAt: json['createdAt'] as String?,
    );
  }

  Topic toEntity() => Topic(
    topicId: topicId,
    topicName: title,
    description: description,
    majorName: majorName,
    status: status,
    mentors: mentors
        .map((m) => TopicMentor(
              mentorId: m.mentorId,
              mentorName: m.mentorName,
              mentorEmail: m.mentorEmail,
            ))
        .toList(),
    skills: (skills as List<dynamic>?)?.whereType<String>().toList() ?? [],
    createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
  );
}

class MentorModel {
  final String mentorId;
  final String mentorName;
  final String mentorEmail;

  MentorModel({
    required this.mentorId,
    required this.mentorName,
    required this.mentorEmail,
  });

  factory MentorModel.fromJson(Map<String, dynamic> json) {
    return MentorModel(
      mentorId: json['mentorId'] as String,
      mentorName: json['mentorName'] as String? ?? '',
      mentorEmail: json['mentorEmail'] as String? ?? '',
    );
  }
}
