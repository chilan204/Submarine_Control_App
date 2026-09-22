import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL for the Spring Boot backend service.
///
/// Platform-specific host configuration:
/// - Android Emulator: `10.0.2.2` maps to the host machine's localhost.
/// - Windows, iOS Simulator, and Web: use `localhost`.
/// - Physical Device: replace with the LAN IP address of the machine running
///   the backend service, for example: `http://192.168.1.10:8080`.
class ApiConfig {
  static String get baseUrl {
    final configured = dotenv.env['API_BASE_URL']?.trim();
    final value = configured == null || configured.isEmpty
        ? 'http://100.109.216.26:8080'
        : configured;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL is invalid');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL');
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  /// WebSocket base — derives ws:// from the HTTP baseUrl.
  static String get wsBaseUrl => baseUrl
      .replaceFirst('http://', 'ws://')
      .replaceFirst('https://', 'wss://');

  static String get passwordLogin => '$baseUrl/api/auth/password-login';
  static String get voiceLogin => '$baseUrl/api/auth/voice-login';
  static String get mySessions => '$baseUrl/api/user-session/me';
  static String get voiceCommand => '$baseUrl/api/voice-command';

  /// Real-time telemetry WebSocket (matches Spring Boot TelemetryHandler at /ws).
  static String get telemetryWs => '$wsBaseUrl/ws';
}
