import '../../domain/entities/board.dart';

class BoardModel extends Board {
  BoardModel({
    required super.boardId,
    required super.groupId,
    required super.boardName,
    required super.columns,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    final columnsJson = json['columns'] as List<dynamic>? ?? const [];
    return BoardModel(
      boardId: json['boardId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      boardName: json['boardName'] as String? ?? 'Board',
      columns: columnsJson
          .whereType<Map<String, dynamic>>()
          .map(BoardColumnModel.fromJson)
          .toList(growable: false),
    );
  }
}

class BoardColumnModel extends BoardColumn {
  BoardColumnModel({
    required super.columnId,
    required super.columnName,
    required super.position,
    required super.isDone,
    required super.dueDate,
    required super.tasks,
  });

  factory BoardColumnModel.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as List<dynamic>? ?? const [];
    return BoardColumnModel(
      columnId: json['columnId'] as String? ?? '',
      columnName: json['columnName'] as String? ?? '',
      position: _toInt(json['position']) ?? 0,
      isDone: json['isDone'] as bool? ?? false,
      dueDate: _parseDate(json['dueDate'] as String?),
      tasks: tasksJson
          .whereType<Map<String, dynamic>>()
          .map(BoardTaskModel.fromJson)
          .toList(growable: false),
    );
  }
}

class BoardTaskModel extends BoardTask {
  BoardTaskModel({
    required super.taskId,
    required super.columnId,
    required super.title,
    required super.description,
    required super.priority,
    required super.status,
    required super.dueDate,
    required super.backlogItemId,
    required super.sortOrder,
    required super.assignees,
  });

  factory BoardTaskModel.fromJson(Map<String, dynamic> json) {
    final assigneesJson = json['assignees'] as List<dynamic>? ?? const [];
    return BoardTaskModel(
      taskId: json['taskId'] as String? ?? '',
      columnId: json['columnId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String? ?? 'Open',
      dueDate: _parseDate(json['dueDate'] as String?),
      backlogItemId: json['backlogItemId'] as String?,
      sortOrder: _toInt(json['sortOrder']),
      assignees: assigneesJson
          .whereType<Map<String, dynamic>>()
          .map(TaskAssigneeModel.fromJson)
          .toList(growable: false),
    );
  }
}

class TaskAssigneeModel extends TaskAssignee {
  TaskAssigneeModel({
    required super.userId,
    required super.displayName,
    required super.avatarUrl,
  });

  factory TaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    return TaskAssigneeModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Member',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
