class Milestone {
  const Milestone({
    required this.milestoneId,
    required this.groupId,
    required this.name,
    required this.status,
    required this.targetDate,
    required this.completedAt,
    required this.description,
    required this.totalItems,
    required this.completedItems,
    required this.completionPercent,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  final String milestoneId;
  final String groupId;
  final String name;
  final String status;
  final DateTime? targetDate;
  final DateTime? completedAt;
  final String? description;
  final int totalItems;
  final int completedItems;
  final double completionPercent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MilestoneItem> items;

  bool get isCompleted => completedAt != null || status.toLowerCase() == 'completed';
  bool get hasItems => items.isNotEmpty;
}

class MilestoneItem {
  const MilestoneItem({
    required this.backlogItemId,
    required this.title,
    required this.status,
    required this.dueDate,
    required this.linkedTaskId,
    required this.columnName,
    required this.columnIsDone,
  });

  final String backlogItemId;
  final String title;
  final String status;
  final DateTime? dueDate;
  final String? linkedTaskId;
  final String? columnName;
  final bool columnIsDone;
}
