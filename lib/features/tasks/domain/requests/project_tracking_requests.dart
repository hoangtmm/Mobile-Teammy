class CreateBacklogRequest {
  const CreateBacklogRequest({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.storyPoints,
    required this.dueDate,
    required this.ownerUserId,
  });

  final String title;
  final String? description;
  final String priority;
  final String category;
  final int? storyPoints;
  final DateTime? dueDate;
  final String ownerUserId;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'storyPoints': storyPoints,
        'dueDate': _formatDate(dueDate),
        'ownerUserId': ownerUserId,
      };
}

class UpdateBacklogRequest {
  const UpdateBacklogRequest({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.storyPoints,
    required this.dueDate,
    required this.status,
    required this.ownerUserId,
  });

  final String title;
  final String? description;
  final String priority;
  final String category;
  final int? storyPoints;
  final DateTime? dueDate;
  final String status;
  final String ownerUserId;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'storyPoints': storyPoints,
        'dueDate': _formatDate(dueDate),
        'status': status,
        'ownerUserId': ownerUserId,
      };
}

class PromoteBacklogRequest {
  const PromoteBacklogRequest({
    required this.columnId,
    required this.taskStatus,
    required this.taskDueDate,
  });

  final String columnId;
  final String taskStatus;
  final DateTime? taskDueDate;

  Map<String, dynamic> toJson() => {
        'columnId': columnId,
        'taskStatus': taskStatus,
        'taskDueDate': _formatDate(taskDueDate),
      };
}

class CreateMilestoneRequest {
  const CreateMilestoneRequest({
    required this.name,
    required this.description,
    required this.targetDate,
  });

  final String name;
  final String? description;
  final DateTime? targetDate;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'targetDate': _formatDate(targetDate),
      };
}

class UpdateMilestoneRequest {
  const UpdateMilestoneRequest({
    required this.name,
    required this.description,
    required this.targetDate,
    required this.status,
    required this.completedAt,
  });

  final String name;
  final String? description;
  final DateTime? targetDate;
  final String status;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'targetDate': _formatDate(targetDate),
        'status': status,
        'completedAt': _formatDate(completedAt),
      };
}

class AssignMilestoneItemsRequest {
  const AssignMilestoneItemsRequest({required this.backlogItemIds});

  final List<String> backlogItemIds;

  Map<String, dynamic> toJson() => {
        'backlogItemIds': backlogItemIds,
      };
}

String? _formatDate(DateTime? date) => date?.toUtc().toIso8601String();
