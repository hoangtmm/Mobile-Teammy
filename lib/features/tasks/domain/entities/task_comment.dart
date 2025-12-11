class TaskComment {
  const TaskComment({
    required this.commentId,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  final String commentId;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
}
