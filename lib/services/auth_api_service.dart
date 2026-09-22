import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_models.dart';

class AuthApiService {
  static const _loginTimeout = Duration(seconds: 15);
  static const _voiceTimeout = Duration(seconds: 60);

  Future<PasswordLoginResult> passwordLogin({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.passwordLogin),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username.trim(),
            'password': password,
          }),
        )
        .timeout(_loginTimeout);

    return _parsePasswordResponse(response);
  }

  Future<VoiceLoginResult> voiceLogin({
    required List<int> audioBytes,
    String? language,
    String filename = 'audio.wav',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.voiceLogin),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: filename,
      ),
    );
    if (language != null) {
      request.fields['language'] = language;
    }

    final streamed = await request.send().timeout(_voiceTimeout);
    final response = await http.Response.fromStream(streamed);
    return _parseVoiceResponse(response);
  }

  PasswordLoginResult _parsePasswordResponse(http.Response response) {
    final Map<String, dynamic> body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final message = body['message'] as String?;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        return PasswordLoginResult(
          success: false,
          message: message ?? 'Invalid response from server',
        );
      }
      return PasswordLoginResult(
        success: true,
        data: PasswordLoginData.fromJson(data),
        message: message,
      );
    }

    return PasswordLoginResult(success: false, message: message);
  }

  VoiceLoginResult _parseVoiceResponse(http.Response response) {
    final Map<String, dynamic> body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final message = body['message'] as String?;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        return VoiceLoginResult(
          success: false,
          message: message ?? 'Invalid response from server',
        );
      }

      final voiceData = VoiceLoginData.fromJson(data);
      if (!voiceData.authenticated ||
          voiceData.token == null ||
          voiceData.token!.isEmpty) {
        return VoiceLoginResult(
          success: false,
          data: voiceData,
          message: message ?? 'Voice authentication failed',
        );
      }

      return VoiceLoginResult(
        success: true,
        data: voiceData,
        message: message,
      );
    }

    return VoiceLoginResult(success: false, message: message);
  }

  @Deprecated('Use passwordLogin instead')
  Future<PasswordLoginResult> login({
    required String username,
    required String password,
  }) =>
      passwordLogin(username: username, password: password);
}
