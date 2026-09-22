import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/models/voice_command_response.dart';

void main() {
  test('parses a successful command response', () {
    final response = VoiceCommandResponse.fromJson({
      'status': 'EXECUTED',
      'speaker_id': 'operator-1',
      'text': 'tiến',
      'command': {
        'action': 'MOVE',
        'direction': 'FORWARD',
        'value': null,
      },
    });

    expect(response.status, 'EXECUTED');
    expect(response.speaker, 'operator-1');
    expect(response.command?.toCommandText(), 'MOVE_FORWARD');
  });

  test('unauthorized result is not successful', () {
    const result = VoiceCommandResult(
      success: false,
      unauthorized: true,
      message: 'Authentication expired',
    );

    expect(result.success, isFalse);
    expect(result.unauthorized, isTrue);
  });
}
