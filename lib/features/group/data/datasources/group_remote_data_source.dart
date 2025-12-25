import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/profile_post_invitation.dart';
import '../../domain/entities/member_invitation.dart';
import '../models/group_invitation_model.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/group_feedback_model.dart';
import '../models/group_file_model.dart';
import '../models/group_recruitment_post_model.dart';
import '../models/major_model.dart';
import '../models/skill_model.dart';
import '../models/tracking_scores_model.dart';

class GroupRemoteDataSource {
  final String baseUrl;
  final http.Client _httpClient;

  GroupRemoteDataSource({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  String _parseErrorMessage(http.Response response) {
    final rawBody = response.body.trim();
    final body = rawBody.isNotEmpty
        ? rawBody
        : utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return 'Request failed (Status: ${response.statusCode})';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is String) {
        return decoded;
      }
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] as String?;
        final error = decoded['error'] as String?;
        return message ?? error ?? body;
      }
    } catch (_) {
      // Keep raw body when it's not JSON.
    }

    return body;
  }

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

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
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
    final uri = Uri.parse('$baseUrl${ApiPath.groupTracking(groupId)}');

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

  /// Lấy tracking scores của nhóm từ /api/groups/{groupId}/tracking/scores
  Future<TrackingScoresModel> fetchTrackingScores(
    String accessToken,
    String groupId, {
    String? from,
    String? to,
    int? high,
    int? medium,
    int? low,
  }) async {
    var uri = Uri.parse('$baseUrl${ApiPath.groupTrackingScores(groupId)}');
    
    final queryParams = <String, String>{};
    if (from != null) queryParams['From'] = from;
    if (to != null) queryParams['To'] = to;
    if (high != null) queryParams['High'] = high.toString();
    if (medium != null) queryParams['Medium'] = medium.toString();
    if (low != null) queryParams['Low'] = low.toString();
    
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tracking scores');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TrackingScoresModel.fromJson(decoded);
  }

  /// Lay danh sach feedback cua nhom /api/groups/{groupId}/feedback
  Future<GroupFeedbackResponseModel> fetchGroupFeedback(
    String accessToken,
    String groupId, {
    required int page,
    required int pageSize,
    String? status,
  }) async {
    var uri = Uri.parse('$baseUrl${ApiPath.groupFeedback(groupId)}');
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    uri = uri.replace(queryParameters: queryParams);

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return GroupFeedbackResponseModel.fromJson(decoded);
  }

  /// Update feedback status /api/groups/{groupId}/feedback/{feedbackId}/status
  Future<void> updateGroupFeedbackStatus(
    String accessToken,
    String groupId,
    String feedbackId, {
    required String status,
    String? note,
  }) async {
    final uri =
        Uri.parse('$baseUrl${ApiPath.groupFeedbackStatus(groupId, feedbackId)}');
    final body = jsonEncode({
      'status': status,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
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

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseErrorMessage(response));
    }
  }

  /// Lay danh sach bai dang tuyen cua nhom /api/recruitment-posts/group/{groupId}
  Future<List<GroupRecruitmentPostModel>> fetchGroupRecruitmentPosts(
    String accessToken,
    String groupId,
  ) async {
    final uri =
        Uri.parse('$baseUrl${ApiPath.recruitmentPostsByGroup(groupId)}');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GroupRecruitmentPostModel.fromJson)
        .toList();
  }

  /// Lay danh sach file cua nhom /api/groups/{groupId}/board/files
  Future<List<GroupFileModel>> fetchGroupFiles(
    String accessToken,
    String groupId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardFiles(groupId)}');
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GroupFileModel.fromJson)
        .toList();
  }

  /// Upload file cho nhom /api/groups/{groupId}/board/files/upload
  Future<GroupFileModel> uploadGroupFile(
    String accessToken,
    String groupId, {
    required List<int> bytes,
    required String fileName,
    String? description,
    String? mimeType,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardUploadFile(groupId)}');
    final multipartRequest = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      })
      ..fields['description'] = description ?? ''
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType ?? 'application/octet-stream'),
        ),
      );

    final streamedResponse = await _httpClient.send(multipartRequest);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErrorMessage(response));
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return GroupFileModel.fromJson(decoded);
  }

  /// Delete file /api/groups/{groupId}/board/files/{fileId}
  Future<void> deleteGroupFile(
    String accessToken,
    String groupId,
    String fileId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.boardFile(groupId, fileId)}');
    final response = await _httpClient.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseErrorMessage(response));
    }
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

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
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
    final uri = Uri.parse(
      '$baseUrl/api/skills?major=$encodedMajor&pageSize=100',
    );

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

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
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

    print(
      'Create Group Response - Status: ${response.statusCode}, Body: ${response.body}',
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErrorMessage(response));
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    // If response only contains id, fetch full group details
    if (decoded.length == 1 && decoded.containsKey('id')) {
      final groupId = decoded['id'] as String;
      print(
        'Response only contains ID, fetching full group details for: $groupId',
      );
      return await _fetchGroupDetail(accessToken, groupId);
    }

    return GroupModel.fromJson(decoded);
  }

  /// Lấy chi tiết nhóm từ /api/groups/my
  Future<GroupModel> _fetchGroupDetail(
    String accessToken,
    String groupId,
  ) async {
    final groups = await fetchMyGroups(accessToken);
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found after creation'),
    );
    return group;
  }

  /// Rời khỏi nhóm DELETE /api/groups/{groupId}/members/me
  Future<void> leaveGroup(String accessToken, String groupId) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupLeaveMember(groupId)}');

    final response = await _httpClient.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    // Log response for debugging
    print(
      'Leave Group Response - Status: ${response.statusCode}, Body: ${response.body}',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Try to parse error message from response
      try {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final message =
            decoded['message'] as String? ?? decoded['error'] as String?;
        throw Exception(
          message ?? 'Failed to leave group (Status: ${response.statusCode})',
        );
      } catch (e) {
        if (e is Exception && e.toString().contains('message')) {
          rethrow;
        }
        throw Exception(
          'Failed to leave group (Status: ${response.statusCode})',
        );
      }
    }
  }

  /// Lấy danh sách thành viên của nhóm
  Future<List<GroupMemberModel>> fetchGroupMembers(
    String accessToken,
    String groupId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupMembers(groupId)}');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch group members');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GroupMemberModel.fromJson)
        .toList();
  }

  /// Tìm kiếm user theo email
  Future<List<Map<String, dynamic>>> searchUsers(
    String accessToken,
    String email,
  ) async {
    final uri = Uri.parse(
      '$baseUrl${ApiPath.usersList}',
    ).replace(queryParameters: {'email': email});

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search users');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  /// Mời người dùng vào nhóm
  Future<Map<String, dynamic>> inviteUserToGroup(
    String accessToken,
    String groupId,
    String userId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupInvite(groupId)}');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final message =
            decoded['message'] as String? ?? decoded['error'] as String?;
        throw Exception(message ?? 'Failed to invite user');
      } catch (e) {
        if (e is Exception && e.toString().contains('message')) {
          rethrow;
        }
        throw Exception(
          'Failed to invite user (Status: ${response.statusCode})',
        );
      }
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Cập nhật thông tin nhóm
  Future<GroupModel> updateGroup(
    String accessToken,
    String groupId,
    Map<String, dynamic> updateData,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupUpdate(groupId)}');

    final response = await _httpClient.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json, text/plain, */*',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 204) {
      // 204 No Content - success but no body to return
      // Return a basic GroupModel with the updated data
      return GroupModel.fromJson({'id': groupId, ...updateData});
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErrorMessage(response));
    }

    return GroupModel.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Kich hoat nhom /api/groups/{groupId}/activate
  Future<String> activateGroup(
    String accessToken,
    String groupId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.groupActivate(groupId)}');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      final body = utf8.decode(response.bodyBytes).trim();
      return body.isNotEmpty ? _parseErrorMessage(response) : 'Group activated';
    }

    if (response.statusCode == 409) {
      return _parseErrorMessage(response);
    }

    throw Exception(_parseErrorMessage(response));
  }

  /// Lấy danh sách lời mời từ profile posts
  Future<List<ProfilePostInvitation>> fetchProfilePostInvitations(
    String accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/api/profile-posts/my/invitations').replace(
      queryParameters: {'status': 'pending'},
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch profile post invitations');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ProfilePostInvitation.fromJson)
        .toList();
  }

  /// Lấy danh sách lời mời thành viên
  Future<List<MemberInvitation>> fetchMemberInvitations(
    String accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/api/invitations').replace(
      queryParameters: {'status': 'pending'},
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch member invitations');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MemberInvitation.fromJson)
        .toList();
  }

  /// Lấy danh sách lời mời nhóm (deprecated - use fetchMemberInvitations and fetchProfilePostInvitations)
  Future<List<GroupInvitationModel>> fetchInvitations(
    String accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.invitationsList}').replace(
      queryParameters: {'status': 'pending'},
    );

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch invitations');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GroupInvitationModel.fromJson)
        .toList();
  }

  /// Lấy danh sách pending invitations cho một group
  Future<List<GroupInvitationModel>> fetchPendingInvitations(
    String accessToken,
    String groupId,
  ) async {
    final uri = Uri.parse('$baseUrl/api/groups/$groupId/pending');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch pending invitations');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(GroupInvitationModel.fromJson)
        .toList();
  }

  /// Lấy danh sách tất cả skills từ /api/skills
  Future<List<Map<String, dynamic>>> fetchAllSkills() async {
    final uri = Uri.parse(
      '$baseUrl/api/skills?pageSize=100&major=Software%20Engineering',
    );

    final response = await _httpClient.get(
      uri,
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch skills');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    // Handle both array and object responses
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    } else if (decoded is Map<String, dynamic>) {
      // If response is an object with data array inside
      if (decoded.containsKey('data') && decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
    }

    return [];
  }

  /// Kick member khỏi group
  Future<void> kickMember({
    required String accessToken,
    required String groupId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups/$groupId/members/$userId');

    final response = await _httpClient.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to kick member: ${response.statusCode}');
    }
  }

  /// Chuyển quyền leader cho member khác
  Future<void> transferLeader({
    required String accessToken,
    required String groupId,
    required String newLeaderUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/groups/$groupId/leader/transfer');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({'newLeaderUserId': newLeaderUserId}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('Failed to transfer leader: $errorBody');
    }
  }
}
