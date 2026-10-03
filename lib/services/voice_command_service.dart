import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/voice_command_response.dart';

/// Reuse this metadata when retrying the same recording. A new recording gets
/// a new ID; retrying must not extend its deadline.
class CommandRequestMetadata {
  final String requestId;
  final int expiresAt;

  const CommandRequestMetadata(
      {required this.requestId, required this.expiresAt});

  factory CommandRequestMetadata.create() {
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return CommandRequestMetadata(
      requestId: id,
      expiresAt: DateTime.now()
          .add(const Duration(seconds: 45))
          .millisecondsSinceEpoch,
    );
  }
}

class VoiceCommandService {
  final http.Client? _client;
  final Duration _requestTimeout;

  VoiceCommandService(
      {http.Client? client,
      Duration requestTimeout = const Duration(seconds: 60)})
      : _client = client,
        _requestTimeout = requestTimeout;

  Future<VoiceCommandResult> sendVoiceCommand({
    required List<int> audioBytes,
    required String token,
    required CommandRequestMetadata metadata,
    String? language,
    String filename = 'command.wav',
  }) async {
    if (DateTime.now().millisecondsSinceEpoch >= metadata.expiresAt) {
      return const VoiceCommandResult(
        success: false,
        data: VoiceCommandResponse(status: 'COMMAND_EXPIRED'),
        message: 'Command deadline expired; no further transmission',
      );
    }
    final client = _client ?? http.Client();
    try {
      final uri = Uri.parse(ApiConfig.voiceCommand);
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['requestId'] = metadata.requestId;
      request.fields['expiresAt'] = metadata.expiresAt.toString();

      // Attach file
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

      // Bound both response headers and the complete body. Closing our client
      // on timeout stops local waiting; the server enforces the earlier deadline.
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_requestTimeout);

      if (response.statusCode == 401) {
        return const VoiceCommandResult(
          success: false,
          unauthorized: true,
          message: 'Authentication expired',
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final message = body['message'] as String?;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body['data'];
        if (data is! Map<String, dynamic>) {
          return VoiceCommandResult(
            success: false,
            message: message ?? 'Invalid response data',
          );
        }
        return VoiceCommandResult(
          success: true,
          data: VoiceCommandResponse.fromJson(data),
          message: message,
        );
      }

      // Handle structured error responses (e.g. 403 Forbidden with VoiceCommandResponse info)
      if (body['data'] != null && body['data'] is Map<String, dynamic>) {
        return VoiceCommandResult(
          success: false,
          data: VoiceCommandResponse.fromJson(
              body['data'] as Map<String, dynamic>),
          message: message,
        );
      }

      return VoiceCommandResult(
        success: false,
        message: message ?? 'Request failed: ${response.statusCode}',
      );
    } on TimeoutException {
      return const VoiceCommandResult(
        success: false,
        data: VoiceCommandResponse(status: 'OUTCOME_UNKNOWN'),
        message: 'Response timed out; transmission outcome is unknown',
      );
    } catch (_) {
      return const VoiceCommandResult(
        success: false,
        data: VoiceCommandResponse(status: 'OUTCOME_UNKNOWN'),
        message: 'Connection failed; transmission outcome is unknown',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
