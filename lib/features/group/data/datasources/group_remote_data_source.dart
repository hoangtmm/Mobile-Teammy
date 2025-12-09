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
    final uri = Uri.parse('$baseUrl${ApiPath.skillsByMajor(majorName)}');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch skills');
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
    required String description,
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

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create group');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return GroupModel.fromJson(decoded);
  }
}
