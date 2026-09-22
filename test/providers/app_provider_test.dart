import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/providers/app_provider.dart';

void main() {
  test('login rejects an empty token', () {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    expect(() => provider.login(token: ''), throwsArgumentError);
    expect(provider.isLoggedIn, isFalse);
  });

  test('logout clears authenticated state', () {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    provider.login(token: 'token', username: 'operator');
    provider.logout();

    expect(provider.isLoggedIn, isFalse);
    expect(provider.authToken, isNull);
    expect(provider.username, isNull);
  });
}
