import '../../domain/entities/forum_membership.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_data_source.dart';

class ForumRepositoryImpl implements ForumRepository {
  ForumRepositoryImpl({required this.remoteDataSource});

  final ForumRemoteDataSource remoteDataSource;

  @override
  Future<ForumMembership?> fetchMembership(String accessToken) async {
    final model = await remoteDataSource.fetchMembership(accessToken);
    return model; // ForumMembershipModel extends ForumMembership
  }

  @override
  Future<List<ForumPost>> fetchRecruitmentPosts(String accessToken) async {
    final result = await remoteDataSource.fetchRecruitmentPosts(accessToken);
    return result.map<ForumPost>((e) => e).toList(growable: false);
  }

  @override
  Future<List<ForumPost>> fetchPersonalPosts(String accessToken) async {
    final result = await remoteDataSource.fetchPersonalPosts(accessToken);
    return result.map<ForumPost>((e) => e).toList(growable: false);
  }

  @override
  Future<ForumPost> createRecruitmentPost(
    String accessToken, {
    required String groupId,
    required String title,
    required String description,
    required String positionNeeded,
    DateTime? expiresAt,
    List<String>? skills,
  }) async {
    final model = await remoteDataSource.createRecruitmentPost(
      accessToken,
      groupId: groupId,
      title: title,
      description: description,
      positionNeeded: positionNeeded,
      expiresAt: expiresAt,
      skills: skills,
    );
    return model;
  }

  @override
  Future<ForumPost> createPersonalPost(
    String accessToken, {
    required String title,
    required String description,
    List<String>? skills,
  }) async {
    final model = await remoteDataSource.createPersonalPost(
      accessToken,
      title: title,
      description: description,
      skills: skills,
    );
    return model;
  }

  @override
  Future<void> applyToRecruitmentPost(
    String accessToken, {
    required String postId,
    required String message,
  }) async {
    await remoteDataSource.applyToRecruitmentPost(
      accessToken,
      postId: postId,
      message: message,
    );
  }

  @override
  Future<void> inviteToProfilePost(
    String accessToken, {
    required String postId,
  }) async {
    await remoteDataSource.inviteToProfilePost(accessToken, postId: postId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSkills(
    String accessToken, {
    required String major,
  }) async {
    return await remoteDataSource.fetchSkills(accessToken, major: major);
  }

  @override
  Future<Map<String, dynamic>?> fetchGroupDetails(
    String accessToken,
    String groupId,
  ) async {
    return await remoteDataSource.fetchGroupDetails(accessToken, groupId);
  }
}
