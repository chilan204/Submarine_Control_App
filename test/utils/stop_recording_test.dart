import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/utils/stop_recording.dart';

void main() {
  test('speech failure still stops recorder and returns audio path', () async {
    var stopped = false;
    final path = await stopRecording(
      stopSpeech: () async => throw StateError('speech failed'),
      stopRecorder: () async {
        stopped = true;
        return 'audio.wav';
      },
    );
    expect(stopped, isTrue);
    expect(path, 'audio.wav');
  });

  test('recorder failure is not swallowed', () async {
    await expectLater(
      stopRecording(
        stopSpeech: () async => throw StateError('speech failed'),
        stopRecorder: () async => throw StateError('recorder failed'),
      ),
      throwsStateError,
    );
  });
}
