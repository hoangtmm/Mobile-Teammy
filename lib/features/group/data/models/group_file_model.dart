class GroupFileModel {
  final String fileId;
  final String groupId;
  final String uploadedBy;
  final String uploadedByName;
  final String? uploadedByAvatarUrl;
  final String? taskId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String? description;
  final DateTime createdAt;

  const GroupFileModel({
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

  factory GroupFileModel.fromJson(Map<String, dynamic> json) {
    return GroupFileModel(
      fileId: json['fileId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploadedByName: json['uploadedByName'] as String? ?? '',
      uploadedByAvatarUrl: json['uploadedByAvatarUrl'] as String?,
      taskId: json['taskId'] as String?,
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
