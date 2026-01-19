import 'forum_post.dart';

class ForumPostSuggestion {
  const ForumPostSuggestion({
    required this.post,
    this.scorePercent,
    this.aiReason,
    this.aiBalanceNote,
    this.desiredPosition,
    this.matchingSkills = const [],
    this.requiredSkills = const [],
  });

  final ForumPost post;
  final int? scorePercent;
  final String? aiReason;
  final String? aiBalanceNote;
  final String? desiredPosition;
  final List<String> matchingSkills;
  final List<String> requiredSkills;
}
