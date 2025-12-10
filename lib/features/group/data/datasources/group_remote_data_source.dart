import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../models/group_model.dart';
import '../models/major_model.dart';
import '../models/skill_model.dart';

class GroupRemoteDataSource {
  final String baseUrl;
  final http.Client _httpClient;

  GroupRemoteDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Lấy danh sách nhóm của user từ /api/groups/my
  Future<List<GroupModel>> fetchMyGroups(String accessToken) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupsMyGroups}');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch groups');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GroupModel.fromJson)
        .toList();
  }

  /// Lấy tracking info của nhóm từ /api/groups/{groupId}/tracking/reports/project
  Future<Map<String, dynamic>> fetchGroupTracking(
    String accessToken,
    String groupId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl${ApiPath.groupTracking(groupId)}',
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch group tracking');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Lấy danh sách majors từ /api/majors
  Future<List<MajorModel>> fetchMajors(String accessToken) async {
    final uri = Uri.parse('$baseUrl${ApiPath.majors}');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch majors');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MajorModel.fromJson)
        .toList();
  }

  /// Lấy danh sách skills theo major
  Future<List<SkillModel>> fetchSkillsByMajor(
    String accessToken,
    String majorName,
  ) async {
    final encodedMajor = Uri.encodeComponent(majorName);
    final uri = Uri.parse('$baseUrl/api/skills?major=$encodedMajor&pageSize=100');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch skills: ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SkillModel.fromJson)
        .toList();
  }

  /// Tạo nhóm mới POST /api/groups
  Future<GroupModel> createGroup(
    String accessToken, {
    required String name,
    String? description,
    required int maxMembers,
    required List<String> skills,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupsCreate}');

    final body = jsonEncode({
      'name': name,
      'description': description,
      'maxMembers': maxMembers,
      'skills': skills,
    });

    print('Create Group Request - Body: $body');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: body,
    );

    print('Create Group Response - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create group: ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    
    // If response only contains id, fetch full group details
    if (decoded.length == 1 && decoded.containsKey('id')) {
      final groupId = decoded['id'] as String;
      print('Response only contains ID, fetching full group details for: $groupId');
      return await _fetchGroupDetail(accessToken, groupId);
    }
    
    return GroupModel.fromJson(decoded);
  }

  /// Lấy chi tiết nhóm từ /api/groups/my
  Future<GroupModel> _fetchGroupDetail(String accessToken, String groupId) async {
    final groups = await fetchMyGroups(accessToken);
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found after creation'),
    );
    return group;
  }

  /// Rời khỏi nhóm DELETE /api/groups/{groupId}/members/me
  Future<void> leaveGroup(
    String accessToken,
    String groupId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupLeaveMember(groupId)}');

    final response = await _httpClient.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    // Log response for debugging
    print('Leave Group Response - Status: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Try to parse error message from response
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final message = decoded['message'] as String? ?? decoded['error'] as String?;
        throw Exception(message ?? 'Failed to leave group (Status: ${response.statusCode})');
      } catch (e) {
        if (e is Exception && e.toString().contains('message')) {
          rethrow;
        }
        throw Exception('Failed to leave group (Status: ${response.statusCode})');
      }
    }
  }
}
