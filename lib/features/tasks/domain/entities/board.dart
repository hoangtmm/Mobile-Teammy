class Board {
  final String boardId;
  final String groupId;
  final String boardName;
  final List<BoardColumn> columns;

  const Board({
    required this.boardId,
    required this.groupId,
    required this.boardName,
    required this.columns,
  });

  int get totalTasks => columns.fold(0, (count, column) => count + column.tasks.length);

  int get completedTasks => columns
      .where((column) => column.isDone)
      .fold(0, (count, column) => count + column.tasks.length);

  List<BoardTask> get allTasks =>
      columns.expand((column) => column.tasks).toList(growable: false);
}

class BoardColumn {
  final String columnId;
  final String columnName;
  final int position;
  final bool isDone;
  final DateTime? dueDate;
  final List<BoardTask> tasks;

  const BoardColumn({
    required this.columnId,
    required this.columnName,
    required this.position,
    required this.isDone,
    required this.dueDate,
    required this.tasks,
  });

  bool get isEmpty => tasks.isEmpty;
}

class BoardTask {
  final String taskId;
  final String columnId;
  final String title;
  final String? description;
  final String? priority;
  final String status;
  final DateTime? dueDate;
  final String? backlogItemId;
  final int? sortOrder;
  final List<TaskAssignee> assignees;

  const BoardTask({
    required this.taskId,
    required this.columnId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.backlogItemId,
    required this.sortOrder,
    required this.assignees,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }
}

class TaskAssignee {
  final String userId;
  final String displayName;
  final String? avatarUrl;

  const TaskAssignee({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });
}
