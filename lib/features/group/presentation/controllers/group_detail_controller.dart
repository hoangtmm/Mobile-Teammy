import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';

class GroupDetailController extends ChangeNotifier {
  final String groupId;
  final AuthSession session;
  late final GroupRepositoryImpl _repository;
  late final GroupRemoteDataSource _dataSource;

  Group? _group;
  bool _loading = true;
  String? _error;
  int _groupProgress = 0;
  List<GroupMember> _members = [];

  // Getters
  Group? get group => _group;
  bool get loading => _loading;
  String? get error => _error;
  int get groupProgress => _groupProgress;
  List<GroupMember> get members => _members;

  GroupDetailController({
    required this.groupId,
    required this.session,
  }) {
    _repository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _dataSource = GroupRemoteDataSource(baseUrl: kApiBaseUrl);
  }

  Future<void> loadGroupDetail() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final groups = await _repository.fetchMyGroups(session.accessToken);
      final group = groups.firstWhere((g) => g.id == groupId);

      int progress = 0;
      try {
        final tracking = await _repository.fetchGroupTracking(
          session.accessToken,
          groupId,
        );
        progress = tracking['project']?['completionPercent'] as int? ?? 0;
      } catch (_) {
        progress = 0;
      }

      final members = await _repository.fetchGroupMembers(
        session.accessToken,
        groupId,
      );

      _group = group;
      _groupProgress = progress;
      _members = members;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> inviteUserToGroup(String userId) async {
    try {
      await _dataSource.inviteUserToGroup(
        session.accessToken,
        groupId,
        userId,
      );
      await loadGroupDetail();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGroup(Map<String, dynamic> updateData) async {
    try {
      await _dataSource.updateGroup(
        session.accessToken,
        groupId,
        updateData,
      );
      await loadGroupDetail();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
