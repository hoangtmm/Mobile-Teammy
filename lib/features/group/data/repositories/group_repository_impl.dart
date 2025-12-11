import '../../domain/entities/group.dart';
import '../../domain/entities/group_invitation.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/major.dart';
import '../../domain/entities/skill.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_data_source.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource remoteDataSource;

  GroupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Group>> fetchMyGroups(String accessToken) async {
    return await remoteDataSource.fetchMyGroups(accessToken);
  }

  @override
  Future<Map<String, dynamic>> fetchGroupTracking(
    String accessToken,
    String groupId,
  ) async {
    return await remoteDataSource.fetchGroupTracking(accessToken, groupId);
  }

  @override
  Future<List<Major>> fetchMajors(String accessToken) async {
    return await remoteDataSource.fetchMajors(accessToken);
  }

  @override
  Future<List<Skill>> fetchSkillsByMajor(
    String accessToken,
    String majorName,
  ) async {
    return await remoteDataSource.fetchSkillsByMajor(accessToken, majorName);
  }

  @override
  Future<Group> createGroup(
    String accessToken, {
    required String name,
    String? description,
    required int maxMembers,
    required List<String> skills,
  }) async {
    return await remoteDataSource.createGroup(
      accessToken,
      name: name,
      description: description,
      maxMembers: maxMembers,
      skills: skills,
    );
  }

  @override
  Future<void> leaveGroup(String accessToken, String groupId) async {
    return await remoteDataSource.leaveGroup(accessToken, groupId);
  }

  @override
  Future<List<GroupMember>> fetchGroupMembers(
    String accessToken,
    String groupId,
  ) async {
    return await remoteDataSource.fetchGroupMembers(accessToken, groupId);
  }

  Future<List<GroupInvitation>> fetchInvitations(String accessToken) async {
    return await remoteDataSource.fetchInvitations(accessToken);
  }

  Future<List<GroupInvitation>> fetchPendingInvitations(
    String accessToken,
    String groupId,
  ) async {
    return await remoteDataSource.fetchPendingInvitations(accessToken, groupId);
  }
}
