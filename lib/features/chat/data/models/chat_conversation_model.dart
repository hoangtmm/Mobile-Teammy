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
    super.unreadCount,
    super.isPinned,
    super.pinnedAt,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final updatedAtRaw = json['updatedAt'];
    if (updatedAtRaw is String && updatedAtRaw.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedAtRaw);
    }

    DateTime? pinnedAt;
    final pinnedAtRaw = json['pinnedAt'];
    if (pinnedAtRaw is String && pinnedAtRaw.isNotEmpty) {
      pinnedAt = DateTime.tryParse(pinnedAtRaw);
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
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedAt: pinnedAt,
    );
  }

  factory ChatConversationModel.fromGroupJson(Map<String, dynamic> json) {
    DateTime? updatedAt;
    final updatedAtRaw = json['updatedAt'];
    if (updatedAtRaw is String && updatedAtRaw.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedAtRaw);
    }

    DateTime? pinnedAt;
    final pinnedAtRaw = json['pinnedAt'];
    if (pinnedAtRaw is String && pinnedAtRaw.isNotEmpty) {
      pinnedAt = DateTime.tryParse(pinnedAtRaw);
    }

    final groupId = json['id'] as String? ?? '';
    
    return ChatConversationModel(
      sessionId: groupId, 
      type: 'group',
      groupId: groupId,
      groupName: json['name'] as String?,
      otherUserId: null,
      otherDisplayName: null,
      otherAvatarUrl: null,
      lastMessage: json['description'] as String?,
      updatedAt: updatedAt,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedAt: pinnedAt,
    );
  }
}

