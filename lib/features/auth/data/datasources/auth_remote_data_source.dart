import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/login_response.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<LoginResponse> exchangeIdToken(String idToken) async {
    final uri = Uri.parse('$baseUrl${ApiPath.authLogin}');
    final response = await _httpClient.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      throw AuthApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResponse.fromJson(json);
  }
}

class AuthApiException implements Exception {
  AuthApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'AuthApiException($statusCode): $body';
}
