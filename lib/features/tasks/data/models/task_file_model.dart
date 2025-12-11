import '../../domain/entities/task_file.dart';

class TaskFileModel extends TaskFile {
  const TaskFileModel({
    required super.fileId,
    required super.groupId,
    required super.uploadedBy,
    required super.uploadedByName,
    required super.uploadedByAvatarUrl,
    required super.taskId,
    required super.fileName,
    required super.fileUrl,
    required super.fileType,
    required super.fileSize,
    required super.description,
    required super.createdAt,
  });

  factory TaskFileModel.fromJson(Map<String, dynamic> json) {
    return TaskFileModel(
      fileId: json['fileId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploadedByName: json['uploadedByName'] as String? ?? '',
      uploadedByAvatarUrl: json['uploadedByAvatarUrl'] as String?,
      taskId: json['taskId'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
