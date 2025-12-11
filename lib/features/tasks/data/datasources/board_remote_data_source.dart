import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../models/board_model.dart';
import '../models/task_comment_model.dart';
import '../models/task_file_model.dart';
import '../../domain/requests/board_requests.dart';

class BoardRemoteDataSource {
  BoardRemoteDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<BoardModel> fetchBoard({
    required String accessToken,
    required String groupId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}');

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load board (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return BoardModel.fromJson(decoded);
  }

  Future<String> createColumn({
    required String accessToken,
    required String groupId,
    required CreateColumnRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/columns');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'create column');
    return _extractValue(response.bodyBytes);
  }

  Future<void> updateColumn({
    required String accessToken,
    required String groupId,
    required String columnId,
    required UpdateColumnRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/columns/$columnId');
    final response = await _httpClient.put(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'update column');
  }

  Future<void> deleteColumn({
    required String accessToken,
    required String groupId,
    required String columnId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/columns/$columnId');
    final response = await _httpClient.delete(
      uri,
      headers: _jsonHeaders(accessToken),
    );
    _ensureSuccess(response, 'delete column', allowNoContent: true);
  }

  Future<String> createTask({
    required String accessToken,
    required String groupId,
    required CreateTaskRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/tasks');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'create task');
    return _extractValue(response.bodyBytes);
  }

  Future<void> updateTask({
    required String accessToken,
    required String groupId,
    required String taskId,
    required UpdateTaskRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/tasks/$taskId');
    final response = await _httpClient.put(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'update task');
  }

  Future<void> deleteTask({
    required String accessToken,
    required String groupId,
    required String taskId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/tasks/$taskId');
    final response = await _httpClient.delete(
      uri,
      headers: _jsonHeaders(accessToken),
    );
    _ensureSuccess(response, 'delete task', allowNoContent: true);
  }

  Future<MoveTaskResponse> moveTask({
    required String accessToken,
    required String groupId,
    required String taskId,
    required MoveTaskRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/tasks/$taskId/move');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'move task');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return MoveTaskResponse.fromJson(decoded);
  }

  Future<void> replaceAssignees({
    required String accessToken,
    required String groupId,
    required String taskId,
    required ReplaceAssigneesRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupBoard(groupId)}/tasks/$taskId/assignees');
    final response = await _httpClient.put(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'replace assignees');
  }

  Future<List<TaskCommentModel>> fetchTaskComments({
    required String accessToken,
    required String groupId,
    required String taskId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardTaskComments(groupId, taskId)}');
    final response = await _httpClient.get(uri, headers: _authHeaders(accessToken));
    _ensureSuccess(response, 'load comments');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TaskCommentModel.fromJson)
        .toList();
  }

  Future<String> createTaskComment({
    required String accessToken,
    required String groupId,
    required String taskId,
    required CreateCommentRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardTaskComments(groupId, taskId)}');
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(request.toJson()),
    );
    _ensureSuccess(response, 'create comment');
    return _extractValue(response.bodyBytes);
  }

  Future<void> deleteTaskComment({
    required String accessToken,
    required String groupId,
    required String commentId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardComment(groupId, commentId)}');
    final response = await _httpClient.delete(uri, headers: _authHeaders(accessToken));
    _ensureSuccess(response, 'delete comment', allowNoContent: true);
  }

  Future<List<TaskFileModel>> fetchTaskFiles({
    required String accessToken,
    required String groupId,
    required String taskId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardTaskFiles(groupId, taskId)}');
    final response = await _httpClient.get(uri, headers: _authHeaders(accessToken));
    _ensureSuccess(response, 'load task files');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TaskFileModel.fromJson)
        .toList();
  }

  Future<TaskFileModel> uploadTaskFile({
    required String accessToken,
    required String groupId,
    required UploadTaskFileRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardUploadFile(groupId)}');
    final multipartRequest = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders(accessToken))
      ..fields['taskId'] = request.taskId
      ..fields['description'] = request.description ?? ''
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          request.bytes,
          filename: request.fileName,
          contentType: MediaType.parse(request.mimeType),
        ),
      );

    final streamedResponse = await _httpClient.send(multipartRequest);
    final response = await http.Response.fromStream(streamedResponse);
    _ensureSuccess(response, 'upload file');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TaskFileModel.fromJson(decoded);
  }

  Future<void> deleteTaskFile({
    required String accessToken,
    required String groupId,
    required String fileId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardFile(groupId, fileId)}');
    final response = await _httpClient.delete(uri, headers: _authHeaders(accessToken));
    _ensureSuccess(response, 'delete file', allowNoContent: true);
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

  String _extractValue(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return '';
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is Map<String, dynamic>) {
      final value = decoded['value'] ?? decoded['id'] ?? decoded['data'];
      if (value is String) return value;
      if (value is num || value is bool) return value.toString();
      return ''; // unsupported structure
    }
    if (decoded is String) {
      return decoded;
    }
    if (decoded is num || decoded is bool) {
      return decoded.toString();
    }
    return '';
  }
}
