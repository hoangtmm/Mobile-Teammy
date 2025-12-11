class CreateColumnRequest {
  const CreateColumnRequest({
    required this.columnName,
    required this.position,
  });

  final String columnName;
  final int position;

  Map<String, dynamic> toJson() => {
        'columnName': columnName,
        'position': position,
      };
}

class UpdateColumnRequest {
  const UpdateColumnRequest({
    required this.columnName,
    required this.position,
    required this.isDone,
    required this.dueDate,
  });

  final String columnName;
  final int position;
  final bool isDone;
  final DateTime? dueDate;

  Map<String, dynamic> toJson() => {
        'columnName': columnName,
        'position': position,
        'isDone': isDone,
        'dueDate': _formatDate(dueDate),
      };
}

class CreateTaskRequest {
  const CreateTaskRequest({
    required this.columnId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.backlogItemId,
  });

  final String columnId;
  final String title;
  final String? description;
  final String? priority;
  final String status;
  final DateTime? dueDate;
  final String? backlogItemId;

  Map<String, dynamic> toJson() => {
        'columnId': columnId,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'dueDate': _formatDate(dueDate),
        'backlogItemId': backlogItemId,
      };
}

class UpdateTaskRequest {
  const UpdateTaskRequest({
    required this.columnId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.backlogItemId,
  });

  final String columnId;
  final String title;
  final String? description;
  final String? priority;
  final String status;
  final DateTime? dueDate;
  final String? backlogItemId;

  Map<String, dynamic> toJson() => {
        'columnId': columnId,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'dueDate': _formatDate(dueDate),
        'backlogItemId': backlogItemId,
      };
}

class MoveTaskRequest {
  const MoveTaskRequest({
    required this.columnId,
    required this.prevTaskId,
    required this.nextTaskId,
  });

  final String columnId;
  final String? prevTaskId;
  final String? nextTaskId;

  Map<String, dynamic> toJson() => {
        'columnId': columnId,
        'prevTaskId': prevTaskId,
        'nextTaskId': nextTaskId,
      };
}

class MoveTaskResponse {
  const MoveTaskResponse({
    required this.taskId,
    required this.columnId,
    required this.sortOrder,
  });

  final String taskId;
  final String columnId;
  final int sortOrder;

  factory MoveTaskResponse.fromJson(Map<String, dynamic> json) {
    return MoveTaskResponse(
      taskId: json['taskId'] as String? ?? '',
      columnId: json['columnId'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class ReplaceAssigneesRequest {
  const ReplaceAssigneesRequest({required this.userIds});

  final List<String> userIds;

  Map<String, dynamic> toJson() => {
        'userIds': userIds,
      };
}

String? _formatDate(DateTime? date) => date?.toUtc().toIso8601String();
