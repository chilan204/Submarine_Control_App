import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/providers/app_provider.dart';
import 'package:submarine_flutter/services/user_session_service.dart';
import 'package:submarine_flutter/services/api_exception.dart';
import 'package:submarine_flutter/models/user_session_record.dart';

class PendingSessions extends UserSessionService {
  final requests = <Completer<List<UserSessionRecord>>>[];
  @override
  Future<List<UserSessionRecord>> fetchMySessions(String token) {
    final result = Completer<List<UserSessionRecord>>();
    requests.add(result);
    return result.future;
  }
}

void main() {
  for (final oldRequestFails in [false, true]) {
    test('old session completion cannot affect new login (error=$oldRequestFails)', () async {
      final service = PendingSessions();
      final provider = AppProvider(sessionService: service);
      addTearDown(provider.dispose);
      provider.login(token: 'A');
      final oldRequest = provider.fetchUserSessions();
      provider.logout();
      provider.login(token: 'B');
      final newRequest = provider.fetchUserSessions();
      if (oldRequestFails) {
        service.requests[0].completeError(const UnauthorizedException());
      } else {
        service.requests[0].complete([const UserSessionRecord(id: 1)]);
      }
      await oldRequest;
      expect(provider.authToken, 'B');
      expect(provider.userSessions, isEmpty);
      expect(provider.isLoadingSessions, isTrue);
      service.requests[1].complete([const UserSessionRecord(id: 2)]);
      await newRequest;
      expect(provider.userSessions.single.id, 2);
      expect(provider.isLoadingSessions, isFalse);
    });
  }
}
