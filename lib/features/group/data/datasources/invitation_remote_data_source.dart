import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/invitation_model.dart';

class InvitationRemoteDataSource {
  final String baseUrl;
  final String accessToken;

  InvitationRemoteDataSource({
    required this.baseUrl,
    required this.accessToken,
  });

  final _client = http.Client();

  Future<List<InvitationModel>> fetchPendingInvitations() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/invitations?status=pending'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) is List
            ? jsonDecode(response.body)
            : jsonDecode(response.body)['data'] ?? [];
        return data
            .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to fetch invitations: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching invitations: $e');
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/invitations/$invitationId/accept'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200 && 
          response.statusCode != 201 && 
          response.statusCode != 204) {
        throw Exception('Failed to accept invitation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting invitation: $e');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/invitations/$invitationId/decline'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200 && 
          response.statusCode != 201 && 
          response.statusCode != 204) {
        throw Exception('Failed to decline invitation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error declining invitation: $e');
    }
  }
}
