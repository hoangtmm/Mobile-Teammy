import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';

class GroupPageController extends ChangeNotifier {
  final AuthSession session;
  late final GroupRepositoryImpl _repository;

  List<Group> _groups = [];
  bool _loading = true;
  String? _error;
  Map<String, int?> _groupProgress = {};
  int _selectedTabIndex = 0;

  // Getters
  List<Group> get groups => _groups;
  bool get loading => _loading;
  String? get error => _error;
  Map<String, int?> get groupProgress => _groupProgress;
  int get selectedTabIndex => _selectedTabIndex;

  GroupPageController({required this.session}) {
    _repository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
  }

  Future<void> loadGroups() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final groups = await _repository.fetchMyGroups(session.accessToken);

      // Load progress for each group
      for (final group in groups) {
        await _loadGroupProgress(group.id);
      }

      _groups = groups;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadGroupProgress(String groupId) async {
    try {
      final tracking = await _repository.fetchGroupTracking(
        session.accessToken,
        groupId,
      );
      final completionPercent =
          tracking['project']?['completionPercent'] as int? ?? 0;
      _groupProgress[groupId] = completionPercent;
      notifyListeners();
    } catch (_) {
      // Ignore tracking load errors
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _repository.leaveGroup(session.accessToken, groupId);
      await loadGroups();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void setSelectedTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }
}
