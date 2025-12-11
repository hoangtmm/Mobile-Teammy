class TaskFile {
  const TaskFile({
    required this.fileId,
    required this.groupId,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedByAvatarUrl,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.description,
    required this.createdAt,
  });

  final String fileId;
  final String groupId;
  final String uploadedBy;
  final String uploadedByName;
  final String? uploadedByAvatarUrl;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String? description;
  final DateTime createdAt;
}
