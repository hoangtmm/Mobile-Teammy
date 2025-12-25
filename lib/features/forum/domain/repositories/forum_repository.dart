import '../entities/forum_membership.dart';
import '../entities/forum_post.dart';
import '../entities/forum_post_suggestion.dart';

abstract class ForumRepository {
  /// Lấy membership hiện tại (để biết user có groupId không)
  Future<ForumMembership?> fetchMembership(String accessToken);

  /// Danh sách bài post tuyển thành viên (recruitment posts)
  Future<List<ForumPost>> fetchRecruitmentPosts(String accessToken);

  /// Danh sách bài post cá nhân (sinh viên tìm nhóm)
  Future<List<ForumPost>> fetchPersonalPosts(String accessToken);

  /// Tạo recruitment post
  Future<ForumPost> createRecruitmentPost(
    String accessToken, {
    required String groupId,
    required String title,
    required String description,
    required String positionNeeded,
    DateTime? expiresAt,
    List<String>? skills,
  });

  /// Tạo personal post
  Future<ForumPost> createPersonalPost(
    String accessToken, {
    required String title,
    required String description,
    List<String>? skills,
  });

  /// Apply vào 1 recruitment post
  Future<void> applyToRecruitmentPost(
    String accessToken, {
    required String postId,
    required String message,
  });
  Future<void> inviteToProfilePost(
    String accessToken, {
    required String postId,
  });

  /// Fetch skills by major
  Future<List<Map<String, dynamic>>> fetchSkills(
    String accessToken, {
    required String major,
  });

  /// AI suggestions: recruitment posts for a major
  Future<List<ForumPostSuggestion>> fetchRecruitmentSuggestions(
    String accessToken, {
    required String majorId,
    int? limit,
  });

  /// AI suggestions: profile posts for a group
  Future<List<ForumPostSuggestion>> fetchProfileSuggestions(
    String accessToken, {
    required String groupId,
    int? limit,
  });

  /// AI generate draft for recruitment post by group
  Future<Map<String, dynamic>> generateRecruitmentPostDraft(
    String accessToken, {
    required String groupId,
  });

  /// AI generate draft for personal post
  Future<Map<String, dynamic>> generatePersonalPostDraft(
    String accessToken,
  );

  /// Fetch group details by groupId
  Future<Map<String, dynamic>?> fetchGroupDetails(
    String accessToken,
    String groupId,
  );
}
