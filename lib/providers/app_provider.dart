import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';
import '../models/command.dart';
import '../models/user_session_record.dart';
import '../services/user_session_service.dart';
import '../services/api_exception.dart';
import '../l10n/translations.dart';

// Submarine position state for the GPS map
class SubPosition {
  final double lat;
  final double lng;
  final double depth;
  final double heading;
  final double speed;

  const SubPosition({
    required this.lat,
    required this.lng,
    required this.depth,
    required this.heading,
    required this.speed,
  });

  SubPosition copyWith({
    double? lat,
    double? lng,
    double? depth,
    double? heading,
    double? speed,
  }) {
    return SubPosition(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      depth: depth ?? this.depth,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
    );
  }
}

class AppProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _authToken;
  String? _username;
  String? _displayName;
  String? _role;
  int _activeTab = 0;
  List<Command> _commandHistory = [];
  int _missionSeconds = 0;
  Lang _lang = Lang.vi;
  Timer? _missionTimer;

  // API State for User Sessions
  List<UserSessionRecord> _userSessions = [];
  bool _isLoadingSessions = false;
  String? _sessionsError;
  final UserSessionService _sessionService;
  int _sessionGeneration = 0;
  int _historyRequest = 0;
  bool _disposed = false;

  AppProvider({UserSessionService? sessionService})
      : _sessionService = sessionService ?? UserSessionService();

  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;
  String? get username => _username;
  String? get displayName => _displayName;
  String? get role => _role;
  int get activeTab => _activeTab;
  List<Command> get commandHistory => _commandHistory;
  int get missionSeconds => _missionSeconds;
  Lang get lang => _lang;
  AppTranslations get t => AppTranslations(_lang);

  List<UserSessionRecord> get userSessions => _userSessions;
  bool get isLoadingSessions => _isLoadingSessions;
  String? get sessionsError => _sessionsError;

  void login({
    required String token,
    String? username,
    String? name,
    String? role,
  }) {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty');
    }
    _missionTimer?.cancel();
    _sessionGeneration++;
    _userSessions = [];
    _commandHistory = [];
    _isLoadingSessions = false;
    _sessionsError = null;
    _authToken = token;
    _username = username;
    _displayName = name;
    _role = role;
    _isLoggedIn = true;
    _missionSeconds = 0;
    _missionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _missionSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void logout() {
    _sessionGeneration++;
    _isLoadingSessions = false;
    _sessionsError = null;
    final token = _authToken;
    if (token != null) {
      unawaited(_revokeToken(token));
    }
    _isLoggedIn = false;
    _authToken = null;
    _username = null;
    _displayName = null;
    _role = null;
    _commandHistory = [];
    _userSessions = [];
    _missionSeconds = 0;
    _activeTab = 0;
    _missionTimer?.cancel();
    _missionTimer = null;
    notifyListeners();
  }

  Future<void> _revokeToken(String token) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('[AppProvider] Logout revocation failed: $error');
    }
  }

  Future<void> fetchUserSessions() async {
    if (_disposed) return;
    if (_authToken == null) {
      _sessionsError = 'Not authenticated';
      notifyListeners();
      return;
    }

    final generation = _sessionGeneration;
    final request = ++_historyRequest;
    final token = _authToken!;
    bool isCurrent() => !_disposed && generation == _sessionGeneration && request == _historyRequest;
    _isLoadingSessions = true;
    _sessionsError = null;
    notifyListeners();

    try {
      final sessions = await _sessionService.fetchMySessions(token);
      if (!isCurrent()) return;
      _userSessions = sessions;
    } on UnauthorizedException {
      if (!isCurrent()) return;
      logout();
      return;
    } catch (e) {
      if (!isCurrent()) return;
      _sessionsError = e.toString();
    } finally {
      if (isCurrent()) {
        _isLoadingSessions = false;
        notifyListeners();
      }
    }
  }

  void setActiveTab(int index) {
    if (_activeTab != index) {
      _activeTab = index;
      if (index == 2) {
        fetchUserSessions();
      }
      notifyListeners();
    }
  }

  void addCommand(Command cmd) {
    _commandHistory = [..._commandHistory, cmd];
    notifyListeners();
  }

  void setLang(Lang lang) {
    _lang = lang;
    notifyListeners();
  }

  String get formattedMissionTime {
    final h = (_missionSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_missionSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_missionSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionGeneration++;
    _missionTimer?.cancel();
    super.dispose();
  }
}
