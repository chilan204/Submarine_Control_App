import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:submarine_flutter/services/voice_command_service.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8080'));

  test('retry keeps the request ID and original deadline', () async {
    final metadata = CommandRequestMetadata.create();
    final bodies = <String>[];
    final client = MockClient((request) async {
      bodies.add(request.body);
      final duplicate = bodies.length > 1;
      return http.Response(
          jsonEncode({
            'data': {
              'status': duplicate ? 'DUPLICATE_REQUEST' : 'SENT_UNCONFIRMED'
            },
          }),
          duplicate ? 409 : 200,
          headers: {'content-type': 'application/json'});
    });
    final service = VoiceCommandService(client: client);
    final first = await service
        .sendVoiceCommand(audioBytes: [1], token: 'token', metadata: metadata);
    final retry = await service
        .sendVoiceCommand(audioBytes: [1], token: 'token', metadata: metadata);

    expect(first.data?.status, 'SENT_UNCONFIRMED');
    expect(retry.data?.status, 'DUPLICATE_REQUEST');
    for (final body in bodies) {
      expect(body, contains('name="requestId"\r\n\r\n${metadata.requestId}'));
      expect(body, contains('name="expiresAt"\r\n\r\n${metadata.expiresAt}'));
    }
  });

  test('already expired recording does not start an HTTP request', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('{}', 200);
    });
    final result = await VoiceCommandService(client: client).sendVoiceCommand(
      audioBytes: [1],
      token: 'token',
      metadata: CommandRequestMetadata(
        requestId: '0123456789abcdef0123456789abcdef',
        expiresAt: DateTime.now()
            .subtract(const Duration(seconds: 1))
            .millisecondsSinceEpoch,
      ),
    );
    expect(result.data?.status, 'COMMAND_EXPIRED');
    expect(requests, 0);
  });

  test(
      'timeout includes a stalled response body and reports an unknown outcome',
      () async {
    final client = MockClient.streaming((request, body) async {
      await body.drain<void>();
      return http.StreamedResponse(
        Stream.fromFuture(Future.delayed(
            const Duration(milliseconds: 100), () => utf8.encode('{}'))),
        200,
      );
    });
    final result = await VoiceCommandService(
      client: client,
      requestTimeout: const Duration(milliseconds: 10),
    ).sendVoiceCommand(
        audioBytes: [1],
        token: 'token',
        metadata: CommandRequestMetadata.create());
    expect(result.success, isFalse);
    expect(result.data?.status, 'OUTCOME_UNKNOWN');
  });

  test('server expiry remains distinct from a transport timeout', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'data': {'status': 'COMMAND_EXPIRED'}
          }),
          408,
        ));
    final result = await VoiceCommandService(client: client).sendVoiceCommand(
      audioBytes: [1],
      token: 'token',
      metadata: CommandRequestMetadata.create(),
    );
    expect(result.success, isFalse);
    expect(result.data?.status, 'COMMAND_EXPIRED');
  });
}
