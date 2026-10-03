enum RecordingPhase { idle, starting, recording, stopping, disposed }

/// Locks transitions before any plugin await and delays plugin disposal until
/// the in-flight operation settles. UI/network work remains owned by the widget.
class RecordingLifecycle {
  RecordingPhase _phase = RecordingPhase.idle;
  Future<void>? _pending;
  Future<void>? _disposal;

  RecordingPhase get phase => _phase;
  bool get isDisposed => _phase == RecordingPhase.disposed;
  bool get isStarting => _phase == RecordingPhase.starting;

  bool beginStart() {
    if (_phase != RecordingPhase.idle) return false;
    _phase = RecordingPhase.starting;
    return true;
  }

  void started() {
    if (_phase == RecordingPhase.starting) _phase = RecordingPhase.recording;
  }

  bool beginStop() {
    if (_phase != RecordingPhase.recording) return false;
    _phase = RecordingPhase.stopping;
    return true;
  }

  void finish() {
    if (!isDisposed) _phase = RecordingPhase.idle;
  }

  Future<T> track<T>(Future<T> Function() operation) {
    if (isDisposed) return Future.error(StateError('Recording disposed'));
    final result = Future<T>.sync(operation);
    // Disposal must still run when the plugin operation fails.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> dispose(Future<void> Function() release) {
    if (_disposal != null) return _disposal!;
    _phase = RecordingPhase.disposed;
    return _disposal = _releaseAfterPending(release);
  }

  Future<void> _releaseAfterPending(Future<void> Function() release) async {
    await _pending;
    await release();
  }
}
