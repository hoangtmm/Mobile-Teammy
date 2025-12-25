import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/invitation_model.dart';

class GroupInvitationRepository {
  final String baseUrl;
  final String accessToken;

  GroupInvitationRepository({
    required this.baseUrl,
    required this.accessToken,
  });

  Future<List<InvitationModel>> fetchPendingInvitations() async {
    try {
      final url = Uri.parse('$baseUrl/api/invitations?status=pending');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch invitations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching invitations: $e');
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    try {
      final url = Uri.parse('$baseUrl/api/invitations/$invitationId/accept');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      // Accept 200, 201, 204 (No Content = success)
      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        return;
      } else {
        throw Exception('Failed to accept invitation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting invitation: $e');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      final url = Uri.parse('$baseUrl/api/invitations/$invitationId/decline');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      // Accept 200, 201, 204 (No Content = success)
      if (response.statusCode == 200 || 
          response.statusCode == 201 || 
          response.statusCode == 204) {
        return;
      } else {
        throw Exception('Failed to decline invitation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error declining invitation: $e');
    }
  }
}
