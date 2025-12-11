import '../../domain/entities/backlog.dart';

class BacklogItemModel extends BacklogItem {
  BacklogItemModel({
    required super.backlogItemId,
    required super.groupId,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.category,
    required super.storyPoints,
    required super.ownerUserId,
    required super.ownerDisplayName,
    required super.dueDate,
    required super.linkedTaskId,
    required super.columnId,
    required super.columnName,
    required super.columnIsDone,
    required super.milestoneId,
    required super.milestoneName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BacklogItemModel.fromJson(Map<String, dynamic> json) {
    return BacklogItemModel(
      backlogItemId: json['backlogItemId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'Medium',
      category: json['category'] as String? ?? 'General',
      storyPoints: _toInt(json['storyPoints']),
      ownerUserId: json['ownerUserId'] as String? ?? '',
      ownerDisplayName: json['ownerDisplayName'] as String? ?? '',
      dueDate: _parseDate(json['dueDate'] as String?),
      linkedTaskId: json['linkedTaskId'] as String?,
      columnId: json['columnId'] as String?,
      columnName: json['columnName'] as String?,
      columnIsDone: json['columnIsDone'] as bool? ?? false,
      milestoneId: json['milestoneId'] as String?,
      milestoneName: json['milestoneName'] as String?,
      createdAt: _parseDate(json['createdAt'] as String?) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt'] as String?) ?? DateTime.now(),
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
