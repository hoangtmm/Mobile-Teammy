import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<List<ChatConversationModel>> fetchConversations(
    String accessToken,
  ) async {
    // Fetch DM conversations
    final uri = Uri.parse('$baseUrl${ApiPath.chatConversations}');
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    print('[ChatRemoteDataSource] API Response: $decoded');

    final conversations = decoded
        .whereType<Map<String, dynamic>>()
        .map((json) {
          print('[ChatRemoteDataSource] Parsing conversation: $json');
          return ChatConversationModel.fromJson(json);
        })
        .toList();

    print('[ChatRemoteDataSource] Total DM conversations: ${conversations.length}');
    conversations.forEach((c) {
      print('[ChatRemoteDataSource] - ${c.displayName} (type: ${c.type}, isGroup: ${c.isGroup})');
    });

    // Fetch group chats
    final groupConversations = await _fetchGroupConversations(accessToken);
    
    final allConversations = [...conversations, ...groupConversations];
    print('[ChatRemoteDataSource] Total conversations (DM + Groups): ${allConversations.length}');

    return allConversations;
  }

  Future<List<ChatConversationModel>> _fetchGroupConversations(
    String accessToken,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiPath.groupsMyGroups}');
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print('[ChatRemoteDataSource] Failed to fetch groups: ${response.statusCode}');
        return [];
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

      print('[ChatRemoteDataSource] Groups API Response: $decoded');

      final groupConversations = decoded
          .whereType<Map<String, dynamic>>()
          .map((json) {
            print('[ChatRemoteDataSource] Parsing group: $json');
            return ChatConversationModel.fromGroupJson(json);
          })
          .toList();

      print('[ChatRemoteDataSource] Total groups: ${groupConversations.length}');
      groupConversations.forEach((c) {
        print('[ChatRemoteDataSource] - ${c.displayName} (type: ${c.type}, groupId: ${c.groupId})');
      });

      return groupConversations;
    } catch (e) {
      print('[ChatRemoteDataSource] Error fetching groups: $e');
      return [];
    }
  }


  Future<List<ChatMessageModel>> fetchSessionMessages({
    required String accessToken,
    required String sessionId,
    required String currentUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final offset = page <= 1 ? 0 : (page - 1) * pageSize;
    final uri = Uri.parse(
      '$baseUrl${ApiPath.chatSessionMessages(sessionId)}',
    ).replace(queryParameters: {'limit': '$pageSize', 'offset': '$offset'});
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ChatMessageModel.fromJson(
            json,
            currentUserId: currentUserId,
            fallbackSessionId: sessionId,
          ),
        )
        .toList();
  }

  Future<List<ChatMessageModel>> fetchGroupMessages({
    required String accessToken,
    required String groupId,
    required String currentUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final offset = page <= 1 ? 0 : (page - 1) * pageSize;
    final uri = Uri.parse(
      '$baseUrl${ApiPath.groupChatMessages(groupId)}',
    ).replace(queryParameters: {'limit': '$pageSize', 'offset': '$offset'});

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ChatMessageModel.fromJson(
            json,
            currentUserId: currentUserId,
            fallbackSessionId: groupId,
          ),
        )
        .toList();
  }

  Future<void> sendMessage({
    required String accessToken,
    required String sessionId,
    required String content,
    String type = 'text',
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.chatSessionSend(sessionId)}');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'content': content, 'type': type}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembers({
    required String accessToken,
    required String groupId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMembers(groupId)}');
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
