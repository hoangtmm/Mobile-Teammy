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
      final parsed = DateTime.tryParse(createdAtRaw);
      if (parsed != null) {
        createdAt = parsed.isUtc ? parsed.toLocal() : parsed;
      }
    }
    String senderId = '';
    String senderName = '';
    String? senderAvatarUrl;
    final senderObj = json['sender'];
    if (senderObj is Map) {
      final senderMap = Map<String, dynamic>.from(senderObj);
      senderId = senderMap['userId']?.toString() ?? '';
      senderName = senderMap['displayName'] as String? ?? '';
      senderAvatarUrl = senderMap['avatarUrl'] as String?;
    } else {
      senderId = json['senderId']?.toString() ?? '';
      senderName =
          json['senderName'] as String? ??
          json['senderDisplayName'] as String? ??
          json['displayName'] as String? ??
          '';
      senderAvatarUrl = json['senderAvatarUrl'] as String? ?? json['avatarUrl'] as String?;
    }

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
      senderAvatarUrl: senderAvatarUrl,
      content: json['content'] as String? ?? '',
      createdAt: createdAt,
      type: json['type'] as String?,
      isMine: currentUserId != null && currentUserId == senderId,
    );
  }
}
