import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.messageId,
    required super.sessionId,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.createdAt,
    required super.isMine,
    super.senderAvatarUrl,
    super.type,
  });

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? fallbackSessionId,
  }) {
    final createdAtRaw = json['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? createdAt;
    }

    final senderId = json['senderId']?.toString() ?? '';
    final senderName =
        json['senderName'] as String? ??
        json['senderDisplayName'] as String? ??
        json['displayName'] as String? ??
        '';

    return ChatMessageModel(
      messageId:
          json['messageId']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId:
          json['sessionId']?.toString() ??
          json['conversationId']?.toString() ??
          fallbackSessionId ??
          '',
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl:
          json['senderAvatarUrl'] as String? ?? json['avatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: createdAt,
      type: json['type'] as String?,
      isMine: currentUserId != null && currentUserId == senderId,
    );
  }
}
