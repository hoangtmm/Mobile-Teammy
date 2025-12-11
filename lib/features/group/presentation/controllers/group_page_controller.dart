import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_invitation.dart';

class GroupPageController extends ChangeNotifier {
  final AuthSession session;
  late final GroupRepositoryImpl _repository;

  List<Group> _groups = [];
  List<GroupInvitation> _invitations = [];
  List<GroupInvitation> _pendingInvitations = [];
  bool _loading = true;
  bool _invitationsLoading = false;
  String? _error;
  Map<String, int?> _groupProgress = {};
  int _selectedTabIndex = 0;

  // Getters
  List<Group> get groups => _groups;
  List<GroupInvitation> get invitations => _invitations;
  List<GroupInvitation> get pendingInvitations => _pendingInvitations;
  bool get loading => _loading;
  bool get invitationsLoading => _invitationsLoading;
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
      _pendingInvitations.clear(); // Clear pending invitations before reloading
      notifyListeners();

      final groups = await _repository.fetchMyGroups(session.accessToken);

      // Load progress for each group
      for (final group in groups) {
        await _loadGroupProgress(group.id);
      }

      _groups = groups;
      _loading = false;
      notifyListeners();

      // Load invitations
      await loadInvitations();

      // Load pending invitations for each group
      for (final group in groups) {
        await _loadPendingInvitations(group.id);
      }
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadInvitations() async {
    try {
      _invitationsLoading = true;
      notifyListeners();

      _invitations = await _repository.fetchInvitations(session.accessToken);
      _invitationsLoading = false;
      notifyListeners();
    } catch (e) {
      _invitationsLoading = false;
      notifyListeners();
      // Don't set error for invitations, just silently fail
    }
  }

  Future<void> _loadPendingInvitations(String groupId) async {
    try {
      final pending = await _repository.fetchPendingInvitations(
        session.accessToken,
        groupId,
      );
      _pendingInvitations.addAll(pending);
      notifyListeners();
    } catch (_) {
      // Ignore pending invitations load errors
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
