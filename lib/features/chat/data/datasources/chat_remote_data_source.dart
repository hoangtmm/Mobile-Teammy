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

    final conversations = decoded
        .whereType<Map<String, dynamic>>()
        .map((json) => ChatConversationModel.fromJson(json))
        .toList();
    final groupConversations = await _fetchGroupConversations(accessToken);
    
    return [...conversations, ...groupConversations];
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
        return [];
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => ChatConversationModel.fromGroupJson(json))
          .toList();
    } catch (e) {
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
    final body = jsonEncode(<String, dynamic>{'content': content, 'type': type});
    
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  Future<void> sendGroupMessage({
    required String accessToken,
    required String groupId,
    required String content,
    String type = 'text',
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupChatMessages(groupId)}');
    final body = jsonEncode(<String, dynamic>{'content': content, 'type': type});
    
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: body,
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

  Future<ChatMessageModel> pinMessage({
    required String accessToken,
    required String sessionId,
    required String messageId,
    required String currentUserId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/chat/sessions/$sessionId/messages/$messageId/pin',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'pin': true}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ChatMessageModel.fromJson(
      decoded,
      currentUserId: currentUserId,
      fallbackSessionId: sessionId,
    );
  }

  Future<ChatMessageModel> unpinMessage({
    required String accessToken,
    required String sessionId,
    required String messageId,
    required String currentUserId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/chat/sessions/$sessionId/messages/$messageId/pin',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'pin': false}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ChatMessageModel.fromJson(
      decoded,
      currentUserId: currentUserId,
      fallbackSessionId: sessionId,
    );
  }

  Future<ChatMessageModel> deleteMessage({
    required String accessToken,
    required String sessionId,
    required String messageId,
    required String currentUserId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/chat/sessions/$sessionId/messages/$messageId',
    );
    final response = await _httpClient.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ChatMessageModel.fromJson(
      decoded,
      currentUserId: currentUserId,
      fallbackSessionId: sessionId,
    );
  }

  Future<void> markAsRead({
    required String accessToken,
    required String sessionId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/chat/sessions/$sessionId/read',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  Future<void> pinConversation({
    required String accessToken,
    required String sessionId,
    required bool pin,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/chat/conversations/$sessionId/pin',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}
