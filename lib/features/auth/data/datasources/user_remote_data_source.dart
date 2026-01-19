import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/user_profile_model.dart';
import '../../domain/entities/user_profile_update.dart';
import 'auth_remote_data_source.dart';

class UserRemoteDataSource {
  UserRemoteDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<UserProfileModel> getProfile(String accessToken) async {
    final uri = Uri.parse('$baseUrl${ApiPath.usersMyProfile}');
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'text/plain',
      },
    );
    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return UserProfileModel.fromJson(json);
  }

  Future<UserProfileModel> getProfileByUserId(
    String accessToken,
    String userId,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiPath.usersGetById(userId)}');
    final response = await _httpClient.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'text/plain',
      },
    );
    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return UserProfileModel.fromJson(json);
  }

  Future<void> updateProfile({
    required String accessToken,
    required UserProfileUpdate payload,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiPath.usersUpdateProfile}');
    final response = await _httpClient.put(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'accept': 'text/plain',
      },
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}
