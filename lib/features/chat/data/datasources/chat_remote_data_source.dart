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

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ChatConversationModel.fromJson)
        .toList();
  }

  Future<List<ChatMessageModel>> fetchSessionMessages({
    required String accessToken,
    required String sessionId,
    required String currentUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = Uri.parse(
      '$baseUrl${ApiPath.chatSessionMessages(sessionId)}',
    ).replace(queryParameters: {'page': '$page', 'pageSize': '$pageSize'});
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
    final uri = Uri.parse(
      '$baseUrl${ApiPath.groupChatMessages(groupId)}',
    ).replace(queryParameters: {'page': '$page', 'pageSize': '$pageSize'});

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
}
