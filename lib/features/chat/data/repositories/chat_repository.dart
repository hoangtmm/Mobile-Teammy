import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepository {
  ChatRepository({required this.remoteDataSource});

  final ChatRemoteDataSource remoteDataSource;

  Future<List<ChatConversation>> fetchConversations({
    required String accessToken,
  }) {
    return remoteDataSource.fetchConversations(accessToken);
  }

  Future<List<ChatMessage>> fetchSessionMessages({
    required String accessToken,
    required String sessionId,
    required String currentUserId,
    int page = 1,
    int pageSize = 50,
  }) {
    return remoteDataSource.fetchSessionMessages(
      accessToken: accessToken,
      sessionId: sessionId,
      currentUserId: currentUserId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<ChatMessage>> fetchGroupMessages({
    required String accessToken,
    required String groupId,
    required String currentUserId,
    int page = 1,
    int pageSize = 50,
  }) {
    return remoteDataSource.fetchGroupMessages(
      accessToken: accessToken,
      groupId: groupId,
      currentUserId: currentUserId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> sendMessage({
    required String accessToken,
    required String sessionId,
    required String content,
    String type = 'text',
  }) {
    return remoteDataSource.sendMessage(
      accessToken: accessToken,
      sessionId: sessionId,
      content: content,
      type: type,
    );
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembers({
    required String accessToken,
    required String groupId,
  }) {
    return remoteDataSource.fetchGroupMembers(
      accessToken: accessToken,
      groupId: groupId,
    );
  }
}
