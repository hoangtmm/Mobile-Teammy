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
    super.isDeleted,
    super.isPinned,
    super.deletedBy,
    super.deletedAt,
    super.pinnedBy,
    super.pinnedByName,
    super.pinnedAt,
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

    // Parse deletedAt
    DateTime? deletedAt;
    final deletedAtRaw = json['deletedAt'];
    if (deletedAtRaw is String) {
      final parsed = DateTime.tryParse(deletedAtRaw);
      if (parsed != null) {
        deletedAt = parsed.isUtc ? parsed.toLocal() : parsed;
      }
    }

    // Parse pinnedAt
    DateTime? pinnedAt;
    final pinnedAtRaw = json['pinnedAt'];
    if (pinnedAtRaw is String) {
      final parsed = DateTime.tryParse(pinnedAtRaw);
      if (parsed != null) {
        pinnedAt = parsed.isUtc ? parsed.toLocal() : parsed;
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
      isDeleted: json['isDeleted'] as bool?,
      isPinned: json['isPinned'] as bool?,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: deletedAt,
      pinnedBy: json['pinnedBy'] is Map ? (json['pinnedBy']['id'] ?? json['pinnedBy']['userId']) as String? : json['pinnedBy'] as String?,
      pinnedByName: _extractPinnedByName(json['pinnedBy']),
      pinnedAt: pinnedAt,
    );
  }

  static String? _extractPinnedByName(dynamic pinnedByData) {
    if (pinnedByData == null) return null;
    if (pinnedByData is Map) {
      return pinnedByData['displayName'] as String? ?? 
             pinnedByData['name'] as String? ?? 
             pinnedByData['userName'] as String? ??
             pinnedByData['fullName'] as String?;
    }
    return null;
  }
}
