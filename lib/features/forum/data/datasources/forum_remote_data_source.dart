import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../models/forum_membership_model.dart';
import '../models/forum_post_model.dart';

/// Gọi trực tiếp API Forum (profile-posts, recruitment-posts,...)
class ForumRemoteDataSource {
  ForumRemoteDataSource({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  // Endpoint path (mirror với FE path.api.js)
  static const String _recruitmentPostsPath = '/api/recruitment-posts';
  static const String _personalPostsPath = '/api/profile-posts';
  static const String _membershipPath = '/api/groups/membership';

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> _headers(String accessToken, {bool jsonBody = false}) {
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'accept': 'application/json',
    };
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Never _throwApiError(http.Response response) {
    throw AuthApiException(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Future<ForumMembershipModel?> fetchMembership(String accessToken) async {
    final uri = _buildUri(_membershipPath);
    final response = await _httpClient.get(uri, headers: _headers(accessToken));

    if (response.statusCode == 404) {
      // chưa có group
      return null;
    }

    if (response.statusCode != 200) {
      _throwApiError(response);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) return null;

    return ForumMembershipModel.fromJson(decoded);
  }

  Future<Map<String, dynamic>?> fetchGroupDetails(
    String accessToken,
    String groupId,
  ) async {
    final uri = _buildUri('/api/groups/$groupId');
    final response = await _httpClient.get(uri, headers: _headers(accessToken));

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) return null;

    return decoded;
  }

  Future<List<ForumPostModel>> fetchRecruitmentPosts(String accessToken) async {
    final uri = _buildUri(_recruitmentPostsPath);
    final response = await _httpClient.get(uri, headers: _headers(accessToken));

    if (response.statusCode != 200) {
      _throwApiError(response);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ForumPostModel.fromJson)
        .toList();
  }

  Future<List<ForumPostModel>> fetchPersonalPosts(String accessToken) async {
    final uri = _buildUri(_personalPostsPath);
    final response = await _httpClient.get(uri, headers: _headers(accessToken));

    if (response.statusCode != 200) {
      _throwApiError(response);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ForumPostModel.fromJson)
        .toList();
  }

  Future<ForumPostModel> createRecruitmentPost(
    String accessToken, {
    required String groupId,
    required String title,
    required String description,
    required String positionNeeded,
    DateTime? expiresAt,
    List<String>? skills,
  }) async {
    final model = ForumPostModel(
      id: '',
      type: 'group_hiring',
      title: title,
      description: description,
      groupId: groupId,
      positionNeeded: positionNeeded,
      skills: skills ?? const [],
      expiresAt: expiresAt,
      createdAt: null,
    );

    final uri = _buildUri(_recruitmentPostsPath);
    final response = await _httpClient.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(model.toJsonForCreateRecruitment()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    return ForumPostModel.fromJson(decoded);
  }

  Future<ForumPostModel> createPersonalPost(
    String accessToken, {
    required String title,
    required String description,
    List<String>? skills,
  }) async {
    final model = ForumPostModel(
      id: '',
      type: 'individual',
      title: title,
      description: description,
      skills: skills ?? const [],
      groupId: null,
      positionNeeded: null,
      createdAt: null,
      expiresAt: null,
    );

    final uri = _buildUri(_personalPostsPath);
    final response = await _httpClient.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(model.toJsonForCreatePersonal()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    return ForumPostModel.fromJson(decoded);
  }

  Future<void> applyToRecruitmentPost(
    String accessToken, {
    required String postId,
    required String message,
  }) async {
    final uri = _buildUri('$_recruitmentPostsPath/$postId/applications');

    final response = await _httpClient.post(
      uri,
      headers: _headers(accessToken, jsonBody: true),
      body: jsonEncode(<String, dynamic>{'message': message}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }
  }

  // Personal profile post: invite student vào group
  Future<void> inviteToProfilePost(
    String accessToken, {
    required String postId,
  }) async {
    final uri = _buildUri('$_personalPostsPath/$postId/invites');

    final response = await _httpClient.post(
      uri,
      headers: _headers(accessToken), // không cần body
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiError(response);
    }
  }

  // Fetch skills by major
  Future<List<Map<String, dynamic>>> fetchSkills(
    String accessToken, {
    required String major,
  }) async {
    final uri = _buildUri('/api/skills', {'major': major});
    final response = await _httpClient.get(uri, headers: _headers(accessToken));

    if (response.statusCode != 200) {
      _throwApiError(response);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! List) return const [];

    return decoded.whereType<Map<String, dynamic>>().toList();
  }
}
