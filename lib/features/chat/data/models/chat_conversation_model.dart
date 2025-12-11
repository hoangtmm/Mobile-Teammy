import '../../domain/entities/chat_conversation.dart';

class ChatConversationModel extends ChatConversation {
  ChatConversationModel({
    required super.sessionId,
    required super.type,
    super.groupId,
    super.groupName,
    super.otherUserId,
    super.otherDisplayName,
    super.otherAvatarUrl,
    super.lastMessage,
    super.updatedAt,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final updatedAtRaw = json['updatedAt'];
    if (updatedAtRaw is String && updatedAtRaw.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedAtRaw);
    }

    return ChatConversationModel(
      sessionId: json['sessionId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      otherUserId: json['otherUserId'] as String?,
      otherDisplayName: json['otherDisplayName'] as String?,
      otherAvatarUrl: json['otherAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      updatedAt: updatedAt,
    );
  }

  factory ChatConversationModel.fromGroupJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final updatedAtRaw = json['updatedAt'];
    if (updatedAtRaw is String && updatedAtRaw.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedAtRaw);
    }

    // Generate a unique sessionId for group (use groupId as sessionId)
    final groupId = json['id'] as String? ?? '';
    
    return ChatConversationModel(
      sessionId: groupId,  // Use groupId as sessionId for groups
      type: 'group',
      groupId: groupId,
      groupName: json['name'] as String?,
      otherUserId: null,
      otherDisplayName: null,
      otherAvatarUrl: null,
      lastMessage: json['description'] as String?,
      updatedAt: updatedAt,
    );
  }
}

