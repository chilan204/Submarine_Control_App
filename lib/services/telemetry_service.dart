import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

/// Telemetry data received from the backend WebSocket.
class TelemetryData {
  final double latitude;
  final double longitude;
  final double depth;
  final double heading;
  final double speed;
  final double pressure;
  final DateTime timestamp;

  const TelemetryData({
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.heading,
    required this.speed,
    required this.pressure,
    required this.timestamp,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      depth: (json['depth'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      pressure: (json['pressure'] as num?)?.toDouble() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'depth': depth,
        'heading': heading,
        'speed': speed,
        'pressure': pressure,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Manages WebSocket connection to the Spring Boot TelemetryHandler at /ws.
///
/// - Auto-reconnects on disconnection with exponential backoff.
/// - Exposes a [stream] of parsed [TelemetryData] for the UI.
/// - Can also [send] telemetry data back to the server.
class TelemetryService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // seconds
  static const int _watchdogTimeout = 5; // seconds

  bool _disposed = false;
  bool _connected = false;
  bool get isConnected => _connected;

  final _dataController = StreamController<TelemetryData>.broadcast();
  Stream<TelemetryData> get stream => _dataController.stream;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  /// Connect to the telemetry WebSocket endpoint.
  void connect() {
    if (_disposed) return;
    _attemptConnect();
  }

  void _attemptConnect() {
    if (_disposed) return;

    try {
      final uri = Uri.parse(ApiConfig.telemetryWs);
      debugPrint('[TelemetryService] Connecting to $uri ...');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _connected = true;
      _reconnectAttempts = 0;
      _statusController.add(true);
      _resetWatchdog();
      debugPrint('[TelemetryService] Connected ✓');
    } catch (e) {
      debugPrint('[TelemetryService] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final data = TelemetryData.fromJson(json);
      _dataController.add(data);

      if (!_connected) {
        _connected = true;
        _statusController.add(true);
      }
      _resetWatchdog();
    } catch (e) {
      debugPrint('[TelemetryService] Parse error: $e — raw: $raw');
    }
  }

  void _resetWatchdog() {
    if (_disposed) return;
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: _watchdogTimeout), () {
      debugPrint('[TelemetryService] Watchdog timeout: No telemetry data for $_watchdogTimeout seconds');
      if (_connected) {
        _connected = false;
        _statusController.add(false);
      }
    });
  }

  void _onError(Object error) {
    debugPrint('[TelemetryService] Error: $error');
    _connected = false;
    _statusController.add(false);
  }

  void _onDone() {
    debugPrint('[TelemetryService] Disconnected');
    _connected = false;
    _statusController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    final delay = math.min(
      (1 << _reconnectAttempts).clamp(1, _maxReconnectDelay),
      _maxReconnectDelay,
    );
    _reconnectAttempts++;
    debugPrint('[TelemetryService] Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: delay), _attemptConnect);
  }

  /// Send telemetry JSON to the server (broadcast to all clients).
  void send(TelemetryData data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(data.toJson()));
  }

  /// Send raw JSON string.
  void sendRaw(String json) {
    if (_channel == null) return;
    _channel!.sink.add(json);
  }

  /// Close connection and release resources.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    _channel?.sink.close();
    _dataController.close();
    _statusController.close();
  }
}
