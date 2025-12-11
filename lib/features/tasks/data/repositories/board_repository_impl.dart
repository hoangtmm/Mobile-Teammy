import '../../domain/entities/board.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/task_file.dart';
import '../../domain/requests/board_requests.dart';
import '../../domain/repositories/board_repository.dart';
import '../datasources/board_remote_data_source.dart';

class BoardRepositoryImpl implements BoardRepository {
  BoardRepositoryImpl({required this.remoteDataSource});

  final BoardRemoteDataSource remoteDataSource;

  @override
  Future<Board> fetchBoard(String accessToken, String groupId) {
    return remoteDataSource.fetchBoard(
      accessToken: accessToken,
      groupId: groupId,
    );
  }

  @override
  Future<String> createColumn(
    String accessToken,
    String groupId,
    CreateColumnRequest request,
  ) {
    return remoteDataSource.createColumn(
      accessToken: accessToken,
      groupId: groupId,
      request: request,
    );
  }

  @override
  Future<void> updateColumn(
    String accessToken,
    String groupId,
    String columnId,
    UpdateColumnRequest request,
  ) {
    return remoteDataSource.updateColumn(
      accessToken: accessToken,
      groupId: groupId,
      columnId: columnId,
      request: request,
    );
  }

  @override
  Future<void> deleteColumn(String accessToken, String groupId, String columnId) {
    return remoteDataSource.deleteColumn(
      accessToken: accessToken,
      groupId: groupId,
      columnId: columnId,
    );
  }

  @override
  Future<String> createTask(
    String accessToken,
    String groupId,
    CreateTaskRequest request,
  ) {
    return remoteDataSource.createTask(
      accessToken: accessToken,
      groupId: groupId,
      request: request,
    );
  }

  @override
  Future<void> updateTask(
    String accessToken,
    String groupId,
    String taskId,
    UpdateTaskRequest request,
  ) {
    return remoteDataSource.updateTask(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
      request: request,
    );
  }

  @override
  Future<void> deleteTask(String accessToken, String groupId, String taskId) {
    return remoteDataSource.deleteTask(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
    );
  }

  @override
  Future<MoveTaskResponse> moveTask(
    String accessToken,
    String groupId,
    String taskId,
    MoveTaskRequest request,
  ) {
    return remoteDataSource.moveTask(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
      request: request,
    );
  }

  @override
  Future<void> replaceAssignees(
    String accessToken,
    String groupId,
    String taskId,
    ReplaceAssigneesRequest request,
  ) {
    return remoteDataSource.replaceAssignees(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
      request: request,
    );
  }

  @override
  Future<List<TaskComment>> fetchTaskComments(
    String accessToken,
    String groupId,
    String taskId,
  ) {
    return remoteDataSource.fetchTaskComments(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
    );
  }

  @override
  Future<String> createTaskComment(
    String accessToken,
    String groupId,
    String taskId,
    CreateCommentRequest request,
  ) {
    return remoteDataSource.createTaskComment(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
      request: request,
    );
  }

  @override
  Future<void> deleteTaskComment(
    String accessToken,
    String groupId,
    String commentId,
  ) {
    return remoteDataSource.deleteTaskComment(
      accessToken: accessToken,
      groupId: groupId,
      commentId: commentId,
    );
  }

  @override
  Future<List<TaskFile>> fetchTaskFiles(
    String accessToken,
    String groupId,
    String taskId,
  ) {
    return remoteDataSource.fetchTaskFiles(
      accessToken: accessToken,
      groupId: groupId,
      taskId: taskId,
    );
  }

  @override
  Future<TaskFile> uploadTaskFile(
    String accessToken,
    String groupId,
    UploadTaskFileRequest request,
  ) {
    return remoteDataSource.uploadTaskFile(
      accessToken: accessToken,
      groupId: groupId,
      request: request,
    );
  }

  @override
  Future<void> deleteTaskFile(
    String accessToken,
    String groupId,
    String fileId,
  ) {
    return remoteDataSource.deleteTaskFile(
      accessToken: accessToken,
      groupId: groupId,
      fileId: fileId,
    );
  }
}
