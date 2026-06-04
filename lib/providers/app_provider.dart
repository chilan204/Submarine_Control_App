import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/command.dart';
import '../models/user_session_record.dart';
import '../services/user_session_service.dart';
import '../translations/translations.dart';

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
  final UserSessionService _sessionService = UserSessionService();

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
    String? token,
    String? username,
    String? name,
    String? role,
  }) {
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

  Future<void> fetchUserSessions() async {
    if (_authToken == null) {
      _sessionsError = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingSessions = true;
    _sessionsError = null;
    notifyListeners();

    try {
      final sessions = await _sessionService.fetchMySessions(_authToken!);
      _userSessions = sessions;
    } catch (e) {
      _sessionsError = e.toString();
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
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
    _missionTimer?.cancel();
    super.dispose();
  }
}
