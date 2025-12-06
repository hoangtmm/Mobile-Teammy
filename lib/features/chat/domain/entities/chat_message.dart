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
}
