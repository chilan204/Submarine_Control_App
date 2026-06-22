/// Base URL for the Speech-to-Text backend service (Spring Boot, default port: 8080).
///
/// Platform-specific host configuration:
/// - Android Emulator: `10.0.2.2` maps to the host machine's localhost.
/// - Windows, iOS Simulator, and Web: use `localhost`.
/// - Physical Device: replace with the LAN IP address of the machine running
///   the backend service, for example: `http://192.168.1.10:8080`.
class ApiConfig {
  static const int serverPort = 8080;

  static String get baseUrl {
    return 'http://100.109.216.26:$serverPort';
  }

  /// WebSocket base — derives ws:// from the HTTP baseUrl.
  static String get wsBaseUrl =>
      baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');

  static String get passwordLogin => '$baseUrl/api/auth/password-login';
  static String get voiceLogin => '$baseUrl/api/auth/voice-login';
  static String get mySessions => '$baseUrl/api/user-session/me';
  static String get voiceCommand => '$baseUrl/api/voice-command';

  /// Real-time telemetry WebSocket (matches Spring Boot TelemetryHandler at /ws).
  static String get telemetryWs => '$wsBaseUrl/ws';
}
