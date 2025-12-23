class ChatConversation {
  const ChatConversation({
    required this.sessionId,
    required this.type,
    this.groupId,
    this.groupName,
    this.otherUserId,
    this.otherDisplayName,
    this.otherAvatarUrl,
    this.lastMessage,
    this.updatedAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.pinnedAt,
  });

  final String sessionId;
  final String type;
  final String? groupId;
  final String? groupName;
  final String? otherUserId;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime? updatedAt;
  final int unreadCount;
  final bool isPinned;
  final DateTime? pinnedAt;

  bool get isGroup => type.toLowerCase() == 'group';
  bool get isDirect => type.toLowerCase() == 'dm';
  bool get isChannel => type.toLowerCase() == 'channel';

  String get displayName {
    if (isGroup) return groupName ?? '';
    if (isDirect) return otherDisplayName ?? '';
    return groupName ?? otherDisplayName ?? '';
  }
}
