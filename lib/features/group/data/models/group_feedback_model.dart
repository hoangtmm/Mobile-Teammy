class GroupFeedbackModel {
  final String feedbackId;
  final String groupId;
  final String mentorId;
  final String mentorName;
  final String mentorEmail;
  final String mentorAvatar;
  final String category;
  final String summary;
  final String details;
  final int rating;
  final String? blockers;
  final String? nextSteps;
  final String status;
  final String? acknowledgedNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acknowledgedAt;

  const GroupFeedbackModel({
    required this.feedbackId,
    required this.groupId,
    required this.mentorId,
    required this.mentorName,
    required this.mentorEmail,
    required this.mentorAvatar,
    required this.category,
    required this.summary,
    required this.details,
    required this.rating,
    required this.blockers,
    required this.nextSteps,
    required this.status,
    required this.acknowledgedNote,
    required this.createdAt,
    required this.updatedAt,
    required this.acknowledgedAt,
  });

  factory GroupFeedbackModel.fromJson(Map<String, dynamic> json) {
    return GroupFeedbackModel(
      feedbackId: json['feedbackId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      mentorId: json['mentorId'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? '',
      mentorEmail: json['mentorEmail'] as String? ?? '',
      mentorAvatar: json['mentorAvatar'] as String? ?? '',
      category: json['category'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      blockers: json['blockers'] as String?,
      nextSteps: json['nextSteps'] as String?,
      status: json['status'] as String? ?? '',
      acknowledgedNote: json['acknowledgedNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
    );
  }
}

class GroupFeedbackResponseModel {
  final List<GroupFeedbackModel> items;
  final int page;
  final int pageSize;
  final int total;

  const GroupFeedbackResponseModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory GroupFeedbackResponseModel.fromJson(Map<String, dynamic> json) {
    return GroupFeedbackResponseModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GroupFeedbackModel.fromJson)
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
    );
  }
}
