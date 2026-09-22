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
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  int _reconnectAttempts = 0;
  int _clients = 0;
  static const int _maxReconnectDelay = 30; // seconds
  static const int _watchdogTimeout = 5; // seconds

  bool _disposed = false;
  bool _connected = false;
  bool _connecting = false;
  String? _authToken;
  bool get isConnected => _connected;

  final _dataController = StreamController<TelemetryData>.broadcast();
  Stream<TelemetryData> get stream => _dataController.stream;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  /// Connect to the telemetry WebSocket endpoint.
  void connect(String? authToken) {
    if (_disposed) return;
    _clients++;
    final tokenChanged = _authToken != null && _authToken != authToken;
    _authToken = authToken;
    if (tokenChanged) {
      _restartConnection();
      return;
    }
    if (_connected || _connecting) return;
    _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    if (_disposed || _clients == 0 || _connecting || _connected) return;
    if (_authToken == null || _authToken!.isEmpty) {
      _statusController.add(false);
      return;
    }

    _connecting = true;

    try {
      final baseUri = Uri.parse(ApiConfig.telemetryWs);
      final uri = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          if (_authToken != null && _authToken!.isNotEmpty)
            'access_token': _authToken!,
        },
      );
      debugPrint(
        '[TelemetryService] Connecting to ${baseUri.replace(query: '')} ...',
      );

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
      if (_disposed || _clients == 0 || !identical(_channel, channel)) {
        _connecting = false;
        await channel.sink.close();
        return;
      }

      channel.stream.listen(
        _onMessage,
        onError: (Object error) => _onError(channel, error),
        onDone: () => _onDone(channel),
        cancelOnError: false,
      );

      _connecting = false;
      _connected = true;
      _reconnectAttempts = 0;
      _statusController.add(true);
      _resetWatchdog();
      debugPrint('[TelemetryService] Connected ✓');
    } catch (e) {
      _connecting = false;
      _connected = false;
      _channel = null;
      _statusController.add(false);
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
      debugPrint(
        '[TelemetryService] Watchdog timeout: No telemetry data for $_watchdogTimeout seconds',
      );
      if (_connected) {
        _restartConnection();
      }
    });
  }

  void _onError(WebSocketChannel channel, Object error) {
    if (!identical(_channel, channel)) return;
    debugPrint('[TelemetryService] Error: $error');
    _channel = null;
    _connecting = false;
    _connected = false;
    _statusController.add(false);
    channel.sink.close();
    _scheduleReconnect();
  }

  void _onDone(WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;
    debugPrint('[TelemetryService] Disconnected');
    _channel = null;
    _connecting = false;
    _connected = false;
    _statusController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _clients == 0) return;
    _reconnectTimer?.cancel();
    final backoffStep = math.min(_reconnectAttempts, 5);
    final delay = math.min(
      1 << backoffStep,
      _maxReconnectDelay,
    );
    _reconnectAttempts++;
    debugPrint(
      '[TelemetryService] Reconnecting in ${delay}s (attempt $_reconnectAttempts)',
    );
    _reconnectTimer = Timer(Duration(seconds: delay), _attemptConnect);
  }

  void _restartConnection() {
    if (_disposed || _clients == 0) return;
    _watchdogTimer?.cancel();
    final channel = _channel;
    _channel = null;
    _connecting = false;
    if (_connected) {
      _connected = false;
      _statusController.add(false);
    }
    channel?.sink.close();
    _scheduleReconnect();
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

  /// Disconnect the active WebSocket connection and stop all timers.
  /// Keep the StreamControllers active so the service can be reconnected.
  void disconnect() {
    if (_clients > 0) _clients--;
    if (_clients > 0) return;
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connecting = false;
    if (_connected) {
      _connected = false;
      _statusController.add(false);
    }
    debugPrint('[TelemetryService] Disconnected and timers cancelled');
  }

  /// Close connection and release resources permanently.
  void dispose() {
    _clients = 1;
    disconnect();
    _disposed = true;
    _dataController.close();
    _statusController.close();
  }
}
