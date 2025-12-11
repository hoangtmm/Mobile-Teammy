class BacklogItem {
  const BacklogItem({
    required this.backlogItemId,
    required this.groupId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.storyPoints,
    required this.ownerUserId,
    required this.ownerDisplayName,
    required this.dueDate,
    required this.linkedTaskId,
    required this.columnId,
    required this.columnName,
    required this.columnIsDone,
    required this.milestoneId,
    required this.milestoneName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String backlogItemId;
  final String groupId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String category;
  final int? storyPoints;
  final String ownerUserId;
  final String ownerDisplayName;
  final DateTime? dueDate;
  final String? linkedTaskId;
  final String? columnId;
  final String? columnName;
  final bool columnIsDone;
  final String? milestoneId;
  final String? milestoneName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasLinkedTask => linkedTaskId != null && linkedTaskId!.isNotEmpty;
  bool get isOverdue {
    if (dueDate == null) return false;
    final today = DateTime.now();
    final localDue = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final localNow = DateTime(today.year, today.month, today.day);
    return localDue.isBefore(localNow) && !columnIsDone;
  }
}
