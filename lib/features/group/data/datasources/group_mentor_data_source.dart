import 'dart:convert';

import 'package:http/http.dart' as http;

class GroupMentorDataSource {
  final String baseUrl;
  final http.Client _httpClient;

  GroupMentorDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Gửi lời mời mentor cho nhóm
  /// POST /api/groups/{groupId}/mentor-invites
  Future<void> inviteMentor({
    required String accessToken,
    required String groupId,
    required String mentorUserId,
    required String topicId,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups/$groupId/mentor-invites');
    
    final payload = {
      'mentorUserId': mentorUserId,
      'topicId': topicId,
      'message': message,
    };
    
    print('[MENTOR DATA SOURCE] POST $uri');
    print('[MENTOR DATA SOURCE] Payload: ${jsonEncode(payload)}');
    
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('[MENTOR DATA SOURCE] Response Status: ${response.statusCode}');
    print('[MENTOR DATA SOURCE] Response Body: ${response.body}');
    
    if (response.statusCode == 409) {
      print('[MENTOR DATA SOURCE] 409 Error - Parsing response body...');
      final errorMessage = response.body;
      print('[MENTOR DATA SOURCE] Error details: $errorMessage');
      
      // Throw different exceptions based on error message
      if (errorMessage.contains('Mentor is not assigned to this topic')) {
        throw MentorNotAssignedToTopicException(errorMessage);
      } else {
        throw GroupMustBeFullException(
          'Group must be full before inviting mentor',
        );
      }
    }

    // Accept 200, 202, 204 as success
    if (response.statusCode != 204 && response.statusCode != 200 && response.statusCode != 202) {
      throw Exception(
        'Failed to invite mentor (${response.statusCode}): ${response.body}',
      );
    }
    
    print('[MENTOR DATA SOURCE] ✅ Mentor invite successful (${response.statusCode})');
    print('[MENTOR DATA SOURCE] Response: ${response.body}');
  }
}

class GroupMustBeFullException implements Exception {
  final String message;
  GroupMustBeFullException(this.message);

  @override
  String toString() => message;
}
class MentorNotAssignedToTopicException implements Exception {
  final String message;
  MentorNotAssignedToTopicException(this.message);

  @override
  String toString() => message;
}