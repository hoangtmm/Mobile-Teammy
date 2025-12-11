import '../../domain/entities/task_comment.dart';

class TaskCommentModel extends TaskComment {
  const TaskCommentModel({
    required super.commentId,
    required super.taskId,
    required super.userId,
    required super.content,
    required super.createdAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      commentId: json['commentId'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
