import '../../domain/entities/backlog.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/requests/project_tracking_requests.dart';
import '../../domain/repositories/project_tracking_repository.dart';
import '../datasources/project_tracking_remote_data_source.dart';

class ProjectTrackingRepositoryImpl implements ProjectTrackingRepository {
  ProjectTrackingRepositoryImpl({required this.remoteDataSource});

  final ProjectTrackingRemoteDataSource remoteDataSource;

  @override
  Future<List<BacklogItem>> fetchBacklog(String accessToken, String groupId) {
    return remoteDataSource.fetchBacklog(
      accessToken: accessToken,
      groupId: groupId,
    );
  }

  @override
  Future<List<Milestone>> fetchMilestones(String accessToken, String groupId) {
    return remoteDataSource.fetchMilestones(
      accessToken: accessToken,
      groupId: groupId,
    );
  }

  @override
  Future<void> createBacklog(
    String accessToken,
    String groupId,
    CreateBacklogRequest request,
  ) {
    return remoteDataSource.createBacklog(
      accessToken: accessToken,
      groupId: groupId,
      request: request,
    );
  }

  @override
  Future<void> updateBacklog(
    String accessToken,
    String groupId,
    String backlogItemId,
    UpdateBacklogRequest request,
  ) {
    return remoteDataSource.updateBacklog(
      accessToken: accessToken,
      groupId: groupId,
      backlogItemId: backlogItemId,
      request: request,
    );
  }

  @override
  Future<void> deleteBacklog(String accessToken, String groupId, String backlogItemId) {
    return remoteDataSource.deleteBacklog(
      accessToken: accessToken,
      groupId: groupId,
      backlogItemId: backlogItemId,
    );
  }

  @override
  Future<void> promoteBacklog(
    String accessToken,
    String groupId,
    String backlogItemId,
    PromoteBacklogRequest request,
  ) {
    return remoteDataSource.promoteBacklog(
      accessToken: accessToken,
      groupId: groupId,
      backlogItemId: backlogItemId,
      request: request,
    );
  }

  @override
  Future<void> createMilestone(
    String accessToken,
    String groupId,
    CreateMilestoneRequest request,
  ) {
    return remoteDataSource.createMilestone(
      accessToken: accessToken,
      groupId: groupId,
      request: request,
    );
  }

  @override
  Future<void> updateMilestone(
    String accessToken,
    String groupId,
    String milestoneId,
    UpdateMilestoneRequest request,
  ) {
    return remoteDataSource.updateMilestone(
      accessToken: accessToken,
      groupId: groupId,
      milestoneId: milestoneId,
      request: request,
    );
  }

  @override
  Future<void> deleteMilestone(String accessToken, String groupId, String milestoneId) {
    return remoteDataSource.deleteMilestone(
      accessToken: accessToken,
      groupId: groupId,
      milestoneId: milestoneId,
    );
  }

  @override
  Future<void> assignMilestoneItems(
    String accessToken,
    String groupId,
    String milestoneId,
    AssignMilestoneItemsRequest request,
  ) {
    return remoteDataSource.assignMilestoneItems(
      accessToken: accessToken,
      groupId: groupId,
      milestoneId: milestoneId,
      request: request,
    );
  }

  @override
  Future<void> removeMilestoneItem(
    String accessToken,
    String groupId,
    String milestoneId,
    String backlogItemId,
  ) {
    return remoteDataSource.removeMilestoneItem(
      accessToken: accessToken,
      groupId: groupId,
      milestoneId: milestoneId,
      backlogItemId: backlogItemId,
    );
  }
}
