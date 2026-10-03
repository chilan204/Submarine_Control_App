import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:submarine_flutter/services/auth_api_service.dart';

class TrackingClient extends http.BaseClient {
  TrackingClient(this.delegate);
  final http.Client delegate;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      delegate.send(request);

  @override
  void close() {
    closed = true;
    delegate.close();
  }
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8080'));

  test('voice login times out on stalled body and closes its client', () async {
    final body = StreamController<List<int>>();
    final client = TrackingClient(MockClient.streaming((request, stream) async {
      await stream.drain<void>();
      return http.StreamedResponse(body.stream, 200);
    }));
    final service = AuthApiService(
      clientFactory: () => client,
      voiceTimeout: const Duration(milliseconds: 20),
    );
    await expectLater(
        service.voiceLogin(audioBytes: [1]), throwsA(isA<TimeoutException>()));
    expect(client.closed, isTrue);
    body.add(utf8.encode('{}'));
    await body.close();
  });

  test('successful voice login closes its client', () async {
    final client = TrackingClient(MockClient((request) async => http.Response(
        jsonEncode({
          'data': {
            'authenticated': true,
            'token': 'token',
            'username': 'officer',
            'roleCode': 'OFFICER_1'
          },
        }),
        200)));
    final result = await AuthApiService(clientFactory: () => client)
        .voiceLogin(audioBytes: [1]);
    expect(result.success, isTrue);
    expect(client.closed, isTrue);
  });

  test('invalid response also closes the client', () async {
    final client =
        TrackingClient(MockClient((request) async => http.Response('{', 200)));
    await expectLater(
        AuthApiService(clientFactory: () => client).voiceLogin(audioBytes: [1]),
        throwsA(isA<FormatException>()));
    expect(client.closed, isTrue);
  });
}
