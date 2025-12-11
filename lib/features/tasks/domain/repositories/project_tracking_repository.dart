import '../entities/backlog.dart';
import '../entities/milestone.dart';
import '../requests/project_tracking_requests.dart';

abstract class ProjectTrackingRepository {
  Future<List<BacklogItem>> fetchBacklog(String accessToken, String groupId);
  Future<List<Milestone>> fetchMilestones(String accessToken, String groupId);

  Future<void> createBacklog(
    String accessToken,
    String groupId,
    CreateBacklogRequest request,
  );

  Future<void> updateBacklog(
    String accessToken,
    String groupId,
    String backlogItemId,
    UpdateBacklogRequest request,
  );

  Future<void> deleteBacklog(String accessToken, String groupId, String backlogItemId);

  Future<void> promoteBacklog(
    String accessToken,
    String groupId,
    String backlogItemId,
    PromoteBacklogRequest request,
  );

  Future<void> createMilestone(
    String accessToken,
    String groupId,
    CreateMilestoneRequest request,
  );

  Future<void> updateMilestone(
    String accessToken,
    String groupId,
    String milestoneId,
    UpdateMilestoneRequest request,
  );

  Future<void> deleteMilestone(String accessToken, String groupId, String milestoneId);

  Future<void> assignMilestoneItems(
    String accessToken,
    String groupId,
    String milestoneId,
    AssignMilestoneItemsRequest request,
  );

  Future<void> removeMilestoneItem(
    String accessToken,
    String groupId,
    String milestoneId,
    String backlogItemId,
  );
}
