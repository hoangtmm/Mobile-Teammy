import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../../group/data/repositories/group_repository_impl.dart';
import '../../../group/domain/entities/group.dart';
import '../../../group/domain/entities/group_member.dart';
import '../../data/datasources/board_remote_data_source.dart';
import '../../data/datasources/project_tracking_remote_data_source.dart';
import '../../data/repositories/board_repository_impl.dart';
import '../../data/repositories/project_tracking_repository_impl.dart';
import '../../domain/entities/backlog.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/task_file.dart';
import '../../domain/requests/board_requests.dart';
import '../../domain/requests/project_tracking_requests.dart';

class TasksController extends ChangeNotifier {
  TasksController({required this.session}) {
    _boardRepository = BoardRepositoryImpl(
      remoteDataSource: BoardRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _groupRepository = GroupRepositoryImpl(
      remoteDataSource: GroupRemoteDataSource(baseUrl: kApiBaseUrl),
    );
    _trackingRepository = ProjectTrackingRepositoryImpl(
      remoteDataSource: ProjectTrackingRemoteDataSource(baseUrl: kApiBaseUrl),
    );
  }

  final AuthSession session;
  late final BoardRepositoryImpl _boardRepository;
  late final GroupRepositoryImpl _groupRepository;
  late final ProjectTrackingRepositoryImpl _trackingRepository;

  List<Group> _groups = [];
  Board? _board;
  bool _groupsLoading = true;
  bool _boardLoading = false;
  String? _error;
  String? _selectedGroupId;
  DateTime? _lastUpdated;
  List<BacklogItem> _backlogItems = [];
  List<Milestone> _milestones = [];
  bool _backlogLoading = false;
  bool _milestoneLoading = false;
  String? _backlogError;
  String? _milestoneError;
  bool _mutationInFlight = false;
  String? _mutationLabel;
  String? _mutationError;
  List<GroupMember> _groupMembers = [];
  bool _membersLoading = false;
  String? _membersError;
  final Map<String, _TaskActivityState> _taskActivity = {};

  List<Group> get groups => _groups;
  Board? get board => _board;
  bool get groupsLoading => _groupsLoading;
  bool get boardLoading => _boardLoading;
  String? get error => _error;
  String? get selectedGroupId => _selectedGroupId;
  DateTime? get lastUpdated => _lastUpdated;
  List<BacklogItem> get backlogItems => _backlogItems;
  List<Milestone> get milestones => _milestones;
  bool get backlogLoading => _backlogLoading;
  bool get milestoneLoading => _milestoneLoading;
  String? get backlogError => _backlogError;
  String? get milestoneError => _milestoneError;
  bool get isMutating => _mutationInFlight;
  String? get mutationLabel => _mutationLabel;
  String? get mutationError => _mutationError;
  List<GroupMember> get groupMembers => _groupMembers;
  bool get membersLoading => _membersLoading;
  String? get membersError => _membersError;
    List<TaskComment> commentsForTask(String taskId) =>
      List.unmodifiable(_taskActivity[taskId]?.comments ?? const []);
    List<TaskFile> filesForTask(String taskId) =>
      List.unmodifiable(_taskActivity[taskId]?.files ?? const []);
    bool commentsLoading(String taskId) => _taskActivity[taskId]?.commentsLoading ?? false;
    bool filesLoading(String taskId) => _taskActivity[taskId]?.filesLoading ?? false;
    String? commentsError(String taskId) => _taskActivity[taskId]?.commentsError;
    String? filesError(String taskId) => _taskActivity[taskId]?.filesError;
    bool isUploadingFile(String taskId) => _taskActivity[taskId]?.uploadingFile ?? false;

  Group? get selectedGroup {
    if (_selectedGroupId == null) return null;
    try {
      return _groups.firstWhere((group) => group.id == _selectedGroupId);
    } catch (_) {
      return null;
    }
  }

  bool get isBootstrapping =>
      (_groupsLoading && _groups.isEmpty) || (_boardLoading && _board == null);

  Future<void> initialize() async {
    await _loadGroups();
    if (_selectedGroupId != null) {
      await _refreshCurrentGroup();
    }
  }

  Future<void> _loadGroups() async {
    try {
      _groupsLoading = true;
      _error = null;
      notifyListeners();

      final groups = await _groupRepository.fetchMyGroups(session.accessToken);
      _groups = groups;
      _selectedGroupId ??= groups.isNotEmpty ? groups.first.id : null;
      _taskActivity.clear();
      if (_selectedGroupId == null) {
        _groupMembers = [];
        _membersError = null;
      }
    } catch (e) {
      _error = e.toString();
      _groups = [];
      _groupMembers = [];
      _membersError = _error;
      _taskActivity.clear();
    } finally {
      _groupsLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectGroup(String groupId) async {
    if (_selectedGroupId == groupId) return;
    _selectedGroupId = groupId;
    _error = null;
    _groupMembers = [];
    _membersError = null;
    _taskActivity.clear();
    notifyListeners();
    await _refreshCurrentGroup();
  }

  Future<void> refreshBoard() async {
    if (_selectedGroupId == null) return;
    await _refreshCurrentGroup();
  }

  Future<void> _refreshCurrentGroup() async {
    await Future.wait([
      _loadBoard(),
      _loadBacklog(),
      _loadMilestones(),
      _loadGroupMembers(),
    ]);
  }

  Future<void> _loadBoard() async {
    if (_selectedGroupId == null) return;
    try {
      _boardLoading = true;
      _error = null;
      notifyListeners();

      final board = await _boardRepository.fetchBoard(
        session.accessToken,
        _selectedGroupId!,
      );
      _board = board;
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _boardLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBacklog() async {
    if (_selectedGroupId == null) return;
    try {
      _backlogLoading = true;
      _backlogError = null;
      notifyListeners();

      final items = await _trackingRepository.fetchBacklog(
        session.accessToken,
        _selectedGroupId!,
      );
      _backlogItems = items;
    } catch (e) {
      _backlogError = e.toString();
      _backlogItems = [];
    } finally {
      _backlogLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMilestones() async {
    if (_selectedGroupId == null) return;
    try {
      _milestoneLoading = true;
      _milestoneError = null;
      notifyListeners();

      final items = await _trackingRepository.fetchMilestones(
        session.accessToken,
        _selectedGroupId!,
      );
      _milestones = items;
    } catch (e) {
      _milestoneError = e.toString();
      _milestones = [];
    } finally {
      _milestoneLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadGroupMembers() async {
    if (_selectedGroupId == null) return;
    try {
      _membersLoading = true;
      _membersError = null;
      notifyListeners();

      final members = await _groupRepository.fetchGroupMembers(
        session.accessToken,
        _selectedGroupId!,
      );
      _groupMembers = members;
    } catch (e) {
      _membersError = e.toString();
      _groupMembers = [];
    } finally {
      _membersLoading = false;
      notifyListeners();
    }
  }

  Future<void> createColumn(CreateColumnRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'create column',
      action: () => _boardRepository.createColumn(
        session.accessToken,
        groupId,
        request,
      ),
      reloadBoard: true,
    );
  }

  Future<void> updateColumn(String columnId, UpdateColumnRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'update column',
      action: () => _boardRepository.updateColumn(
        session.accessToken,
        groupId,
        columnId,
        request,
      ),
      reloadBoard: true,
    );
  }

  Future<void> deleteColumn(String columnId) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'delete column',
      action: () => _boardRepository.deleteColumn(
        session.accessToken,
        groupId,
        columnId,
      ),
      reloadBoard: true,
    );
  }

  Future<void> createTask(CreateTaskRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'create task',
      action: () => _boardRepository.createTask(
        session.accessToken,
        groupId,
        request,
      ),
      reloadBoard: true,
    );
  }

  Future<void> updateTask(String taskId, UpdateTaskRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'update task',
      action: () => _boardRepository.updateTask(
        session.accessToken,
        groupId,
        taskId,
        request,
      ),
      reloadBoard: true,
    );
  }

  Future<void> deleteTask(String taskId) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'delete task',
      action: () => _boardRepository.deleteTask(
        session.accessToken,
        groupId,
        taskId,
      ),
      reloadBoard: true,
    );
  }

  Future<void> moveTask(String taskId, MoveTaskRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'move task',
      action: () => _boardRepository.moveTask(
        session.accessToken,
        groupId,
        taskId,
        request,
      ),
      reloadBoard: true,
    );
  }

  Future<void> replaceTaskAssignees(
    String taskId,
    ReplaceAssigneesRequest request,
  ) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'update assignees',
      action: () => _boardRepository.replaceAssignees(
        session.accessToken,
        groupId,
        taskId,
        request,
      ),
      reloadBoard: true,
    );
  }

  Future<void> createBacklog(CreateBacklogRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'create backlog',
      action: () => _trackingRepository.createBacklog(
        session.accessToken,
        groupId,
        request,
      ),
      reloadBacklog: true,
    );
  }

  Future<void> updateBacklog(
    String backlogItemId,
    UpdateBacklogRequest request,
  ) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'update backlog',
      action: () => _trackingRepository.updateBacklog(
        session.accessToken,
        groupId,
        backlogItemId,
        request,
      ),
      reloadBacklog: true,
    );
  }

  Future<void> deleteBacklog(String backlogItemId) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'delete backlog',
      action: () => _trackingRepository.deleteBacklog(
        session.accessToken,
        groupId,
        backlogItemId,
      ),
      reloadBacklog: true,
    );
  }

  Future<void> promoteBacklog(
    String backlogItemId,
    PromoteBacklogRequest request,
  ) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'promote backlog',
      action: () => _trackingRepository.promoteBacklog(
        session.accessToken,
        groupId,
        backlogItemId,
        request,
      ),
      reloadBacklog: true,
      reloadBoard: true,
    );
  }

  Future<void> createMilestone(CreateMilestoneRequest request) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'create milestone',
      action: () => _trackingRepository.createMilestone(
        session.accessToken,
        groupId,
        request,
      ),
      reloadMilestones: true,
    );
  }

  Future<void> updateMilestone(
    String milestoneId,
    UpdateMilestoneRequest request,
  ) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'update milestone',
      action: () => _trackingRepository.updateMilestone(
        session.accessToken,
        groupId,
        milestoneId,
        request,
      ),
      reloadMilestones: true,
    );
  }

  Future<void> deleteMilestone(String milestoneId) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'delete milestone',
      action: () => _trackingRepository.deleteMilestone(
        session.accessToken,
        groupId,
        milestoneId,
      ),
      reloadMilestones: true,
    );
  }

  Future<void> assignMilestoneItems(
    String milestoneId,
    AssignMilestoneItemsRequest request,
  ) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'assign milestone items',
      action: () => _trackingRepository.assignMilestoneItems(
        session.accessToken,
        groupId,
        milestoneId,
        request,
      ),
      reloadMilestones: true,
      reloadBacklog: true,
    );
  }

  Future<void> removeMilestoneItem(String milestoneId, String backlogItemId) async {
    final groupId = _requireGroupId();
    await _performMutation(
      label: 'remove milestone item',
      action: () => _trackingRepository.removeMilestoneItem(
        session.accessToken,
        groupId,
        milestoneId,
        backlogItemId,
      ),
      reloadMilestones: true,
      reloadBacklog: true,
    );
  }

  Future<void> loadTaskComments(String taskId) async {
    final groupId = _requireGroupId();
    final activity = _obtainActivity(taskId);
    try {
      activity.commentsLoading = true;
      activity.commentsError = null;
      notifyListeners();
      final comments = await _boardRepository.fetchTaskComments(
        session.accessToken,
        groupId,
        taskId,
      );
      activity.comments = comments;
    } catch (e) {
      activity.commentsError = e.toString();
      activity.comments = const [];
    } finally {
      activity.commentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTaskComment(String taskId, String content) async {
    final groupId = _requireGroupId();
    await _boardRepository.createTaskComment(
      session.accessToken,
      groupId,
      taskId,
      CreateCommentRequest(content: content),
    );
    await loadTaskComments(taskId);
  }

  Future<void> deleteTaskComment(String taskId, String commentId) async {
    final groupId = _requireGroupId();
    await _boardRepository.deleteTaskComment(
      session.accessToken,
      groupId,
      commentId,
    );
    await loadTaskComments(taskId);
  }

  Future<void> loadTaskFiles(String taskId) async {
    final groupId = _requireGroupId();
    final activity = _obtainActivity(taskId);
    try {
      activity.filesLoading = true;
      activity.filesError = null;
      notifyListeners();
      final files = await _boardRepository.fetchTaskFiles(
        session.accessToken,
        groupId,
        taskId,
      );
      activity.files = files;
    } catch (e) {
      activity.filesError = e.toString();
      activity.files = const [];
    } finally {
      activity.filesLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadTaskFile(String taskId, UploadTaskFileRequest request) async {
    final groupId = _requireGroupId();
    final activity = _obtainActivity(taskId);
    try {
      activity.uploadingFile = true;
      activity.filesError = null;
      notifyListeners();
      final file = await _boardRepository.uploadTaskFile(
        session.accessToken,
        groupId,
        request,
      );
      activity.files = [file, ...activity.files];
    } catch (e) {
      activity.filesError = e.toString();
      rethrow;
    } finally {
      activity.uploadingFile = false;
      notifyListeners();
    }
  }

  Future<void> deleteTaskFile(String taskId, String fileId) async {
    final groupId = _requireGroupId();
    final activity = _obtainActivity(taskId);
    await _boardRepository.deleteTaskFile(
      session.accessToken,
      groupId,
      fileId,
    );
    activity.files = activity.files.where((file) => file.fileId != fileId).toList();
    notifyListeners();
  }

  Future<void> _performMutation({
    required String label,
    required Future<void> Function() action,
    bool reloadBoard = false,
    bool reloadBacklog = false,
    bool reloadMilestones = false,
  }) async {
    try {
      _mutationInFlight = true;
      _mutationLabel = label;
      _mutationError = null;
      notifyListeners();

      await action();

      if (reloadBoard) {
        await _loadBoard();
      }
      if (reloadBacklog) {
        await _loadBacklog();
      }
      if (reloadMilestones) {
        await _loadMilestones();
      }
    } catch (e) {
      _mutationError = e.toString();
      rethrow;
    } finally {
      _mutationInFlight = false;
      _mutationLabel = null;
      notifyListeners();
    }
  }

  String _requireGroupId() {
    final groupId = _selectedGroupId;
    if (groupId == null || groupId.isEmpty) {
      throw StateError('A group must be selected before performing this action.');
    }
    return groupId;
  }

  _TaskActivityState _obtainActivity(String taskId) {
    return _taskActivity.putIfAbsent(taskId, () => _TaskActivityState());
  }
}

class _TaskActivityState {
  List<TaskComment> comments = const [];
  List<TaskFile> files = const [];
  bool commentsLoading = false;
  bool filesLoading = false;
  String? commentsError;
  String? filesError;
  bool uploadingFile = false;
}
