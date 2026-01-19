import '../entities/group.dart';
import '../entities/group_member.dart';
import '../entities/major.dart';
import '../entities/skill.dart';
import '../entities/tracking_scores.dart';

abstract class GroupRepository {
  /// Lấy danh sách nhóm của user
  Future<List<Group>> fetchMyGroups(String accessToken);

  /// Lấy chi tiết nhóm với progress tracking
  Future<Map<String, dynamic>> fetchGroupTracking(
    String accessToken,
    String groupId,
  );

  /// Lấy tracking scores của nhóm
  Future<TrackingScores> fetchTrackingScores(
    String accessToken,
    String groupId, {
    String? from,
    String? to,
    int? high,
    int? medium,
    int? low,
  });

  /// Lấy danh sách majors
  Future<List<Major>> fetchMajors(String accessToken);

  /// Lấy danh sách skills theo major
  Future<List<Skill>> fetchSkillsByMajor(String accessToken, String majorName);

  /// Lấy danh sách thành viên của nhóm
  Future<List<GroupMember>> fetchGroupMembers(
    String accessToken,
    String groupId,
  );

  /// Tạo nhóm mới
  Future<Group> createGroup(
    String accessToken, {
    required String name,
    String? description,
    required int maxMembers,
    required List<String> skills,
  });

  /// Rời khỏi nhóm
  Future<void> leaveGroup(String accessToken, String groupId);
}
