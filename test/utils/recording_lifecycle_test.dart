import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:submarine_flutter/utils/recording_lifecycle.dart';

void main() {
  test('rapid start and stop taps each acquire only once', () {
    final lifecycle = RecordingLifecycle();
    expect(lifecycle.beginStart(), isTrue);
    expect(lifecycle.beginStart(), isFalse);
    expect(lifecycle.beginStop(), isFalse);
    lifecycle.started();
    expect(lifecycle.beginStop(), isTrue);
    expect(lifecycle.beginStop(), isFalse);
    expect(lifecycle.beginStart(), isFalse);
    lifecycle.finish();
    expect(lifecycle.beginStart(), isTrue);
  });

  test('disposing during start waits for plugin then releases once', () async {
    final lifecycle = RecordingLifecycle();
    final started = Completer<void>();
    var releases = 0;
    lifecycle.beginStart();
    final operation = lifecycle.track(() => started.future);
    final disposed = lifecycle.dispose(() async {
      releases++;
    });
    expect(lifecycle.isDisposed, isTrue);
    expect(lifecycle.beginStart(), isFalse);
    expect(releases, 0);
    started.complete();
    await operation;
    lifecycle.started();
    lifecycle.finish();
    await disposed;
    await lifecycle.dispose(() async {
      releases++;
    });
    expect(releases, 1);
    expect(lifecycle.phase, RecordingPhase.disposed);
  });

  test('failed stop still permits deferred cleanup', () async {
    final lifecycle = RecordingLifecycle();
    lifecycle.beginStart();
    lifecycle.started();
    lifecycle.beginStop();
    final stopped = Completer<void>();
    final operation = lifecycle.track(() => stopped.future);
    final failure = expectLater(operation, throwsStateError);
    var released = false;
    final disposal = lifecycle.dispose(() async {
      released = true;
    });
    stopped.completeError(StateError('recorder unavailable'));
    await failure;
    await disposal;
    expect(released, isTrue);
  });
}
