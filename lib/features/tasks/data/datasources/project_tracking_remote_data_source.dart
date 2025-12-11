import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../models/backlog_model.dart';
import '../models/milestone_model.dart';
import '../../domain/requests/project_tracking_requests.dart';

class ProjectTrackingRemoteDataSource {
  ProjectTrackingRemoteDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<List<BacklogItemModel>> fetchBacklog({
    required String accessToken,
    required String groupId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBacklog(groupId)}');
    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load backlog (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BacklogItemModel.fromJson)
        .toList(growable: false);
  }

  Future<List<MilestoneModel>> fetchMilestones({
    required String accessToken,
    required String groupId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMilestones(groupId)}');
    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load milestones (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MilestoneModel.fromJson)
        .toList(growable: false);
  }

  Future<void> createBacklog({
    required String accessToken,
    required String groupId,
    required CreateBacklogRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBacklog(groupId)}');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'create backlog');
  }

  Future<void> updateBacklog({
    required String accessToken,
    required String groupId,
    required String backlogItemId,
    required UpdateBacklogRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBacklogItem(groupId, backlogItemId)}');
    final response = await _httpClient.put(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'update backlog');
  }

  Future<void> deleteBacklog({
    required String accessToken,
    required String groupId,
    required String backlogItemId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBacklogItem(groupId, backlogItemId)}');
    final response = await _httpClient.delete(
      uri,
      headers: _authHeaders(accessToken),
    );
    _ensureSuccess(response, 'delete backlog', allowNoContent: true);
  }

  Future<void> promoteBacklog({
    required String accessToken,
    required String groupId,
    required String backlogItemId,
    required PromoteBacklogRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBacklogPromote(groupId, backlogItemId)}');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'promote backlog');
  }

  Future<void> createMilestone({
    required String accessToken,
    required String groupId,
    required CreateMilestoneRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMilestones(groupId)}');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'create milestone');
  }

  Future<void> updateMilestone({
    required String accessToken,
    required String groupId,
    required String milestoneId,
    required UpdateMilestoneRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMilestone(groupId, milestoneId)}');
    final response = await _httpClient.put(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'update milestone');
  }

  Future<void> deleteMilestone({
    required String accessToken,
    required String groupId,
    required String milestoneId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMilestone(groupId, milestoneId)}');
    final response = await _httpClient.delete(
      uri,
      headers: _authHeaders(accessToken),
    );
    _ensureSuccess(response, 'delete milestone', allowNoContent: true);
  }

  Future<void> assignMilestoneItems({
    required String accessToken,
    required String groupId,
    required String milestoneId,
    required AssignMilestoneItemsRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMilestoneItems(groupId, milestoneId)}');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'assign milestone items');
  }

  Future<void> removeMilestoneItem({
    required String accessToken,
    required String groupId,
    required String milestoneId,
    required String backlogItemId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl${ApiPath.groupMilestoneItem(groupId, milestoneId, backlogItemId)}',
    );
    final response = await _httpClient.delete(
      uri,
      headers: _authHeaders(accessToken),
    );
    _ensureSuccess(response, 'remove milestone item', allowNoContent: true);
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      };

  Map<String, String> _jsonHeaders(String token) => {
        ..._authHeaders(token),
        'Content-Type': 'application/json',
      };

  void _ensureSuccess(
    http.Response response,
    String action, {
    bool allowNoContent = false,
  }) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok || (allowNoContent && response.statusCode == 204)) {
      return;
    }
    throw Exception('Failed to $action (${response.statusCode})');
  }
}
