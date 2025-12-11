import '../entities/board.dart';
import '../entities/task_comment.dart';
import '../entities/task_file.dart';
import '../requests/board_requests.dart';

abstract class BoardRepository {
  Future<Board> fetchBoard(String accessToken, String groupId);
  Future<String> createColumn(
    String accessToken,
    String groupId,
    CreateColumnRequest request,
  );

  Future<void> updateColumn(
    String accessToken,
    String groupId,
    String columnId,
    UpdateColumnRequest request,
  );

  Future<void> deleteColumn(String accessToken, String groupId, String columnId);

  Future<String> createTask(
    String accessToken,
    String groupId,
    CreateTaskRequest request,
  );

  Future<void> updateTask(
    String accessToken,
    String groupId,
    String taskId,
    UpdateTaskRequest request,
  );

  Future<void> deleteTask(String accessToken, String groupId, String taskId);

  Future<MoveTaskResponse> moveTask(
    String accessToken,
    String groupId,
    String taskId,
    MoveTaskRequest request,
  );

  Future<void> replaceAssignees(
    String accessToken,
    String groupId,
    String taskId,
    ReplaceAssigneesRequest request,
  );

  Future<List<TaskComment>> fetchTaskComments(
    String accessToken,
    String groupId,
    String taskId,
  );

  Future<String> createTaskComment(
    String accessToken,
    String groupId,
    String taskId,
    CreateCommentRequest request,
  );

  Future<void> deleteTaskComment(
    String accessToken,
    String groupId,
    String commentId,
  );

  Future<List<TaskFile>> fetchTaskFiles(
    String accessToken,
    String groupId,
    String taskId,
  );

  Future<TaskFile> uploadTaskFile(
    String accessToken,
    String groupId,
    UploadTaskFileRequest request,
  );

  Future<void> deleteTaskFile(
    String accessToken,
    String groupId,
    String fileId,
  );
}
