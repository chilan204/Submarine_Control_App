import 'package:flutter/foundation.dart';

Future<T> stopRecording<T>({
  required Future<void> Function() stopSpeech,
  required Future<T> Function() stopRecorder,
}) async {
  try {
    await stopSpeech();
  } catch (error) {
    debugPrint('Speech stop failed; continuing recorder cleanup: $error');
  }
  return await stopRecorder();
}
