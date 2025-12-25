class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isMine,
    this.senderAvatarUrl,
    this.type,
    this.isDeleted,
    this.isPinned,
    this.deletedBy,
    this.deletedAt,
    this.pinnedBy,
    this.pinnedByName,
    this.pinnedAt,
  });

  final String messageId;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final String? type;
  final bool? isDeleted;
  final bool? isPinned;
  final String? deletedBy;
  final DateTime? deletedAt;
  final String? pinnedBy;
  final String? pinnedByName;
  final DateTime? pinnedAt;
}
