import '../../domain/entities/milestone.dart';

class MilestoneModel extends Milestone {
  MilestoneModel({
    required super.milestoneId,
    required super.groupId,
    required super.name,
    required super.status,
    required super.targetDate,
    required super.completedAt,
    required super.description,
    required super.totalItems,
    required super.completedItems,
    required super.completionPercent,
    required super.createdAt,
    required super.updatedAt,
    required super.items,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return MilestoneModel(
      milestoneId: json['milestoneId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'Planned',
      targetDate: _parseDate(json['targetDate'] as String?),
      completedAt: _parseDate(json['completedAt'] as String?),
      description: json['description'] as String?,
      totalItems: json['totalItems'] as int? ?? itemsJson.length,
      completedItems: json['completedItems'] as int? ?? 0,
      completionPercent: (json['completionPercent'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDate(json['createdAt'] as String?) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt'] as String?) ?? DateTime.now(),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(MilestoneItemModel.fromJson)
          .toList(growable: false),
    );
  }
}

class MilestoneItemModel extends MilestoneItem {
  MilestoneItemModel({
    required super.backlogItemId,
    required super.title,
    required super.status,
    required super.dueDate,
    required super.linkedTaskId,
    required super.columnName,
    required super.columnIsDone,
  });

  factory MilestoneItemModel.fromJson(Map<String, dynamic> json) {
    return MilestoneItemModel(
      backlogItemId: json['backlogItemId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      dueDate: _parseDate(json['dueDate'] as String?),
      linkedTaskId: json['linkedTaskId'] as String?,
      columnName: json['columnName'] as String?,
      columnIsDone: json['columnIsDone'] as bool? ?? false,
    );
  }
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final normalized = raw.length == 10 ? '${raw}T00:00:00Z' : raw;
  return DateTime.tryParse(normalized)?.toLocal();
}
